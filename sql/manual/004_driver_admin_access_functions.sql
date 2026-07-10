-- Omnya Driver
-- Developer admin functions for lookup, manual access grant and gift access.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create or replace function driver.is_requester_developer()
returns boolean
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  select exists (
    select 1
    from driver.profiles p
    where p.id = auth.uid()
      and p.role = 'developer'
  );
$$;

grant execute on function driver.is_requester_developer() to authenticated;

create or replace function driver.admin_lookup_profile(p_email text)
returns table (
  id uuid,
  email text,
  display_name text,
  full_name text,
  role driver.user_role,
  plan_type driver.plan_type,
  subscription_status driver.subscription_status,
  onboarding_completed_at timestamptz
)
language plpgsql
security definer
set search_path = driver, auth, public
as $$
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.email,
    p.display_name,
    p.full_name,
    p.role,
    p.plan_type,
    p.subscription_status,
    p.onboarding_completed_at
  from driver.profiles p
  where lower(p.email) = lower(trim(p_email))
  limit 1;
end;
$$;

grant execute on function driver.admin_lookup_profile(text) to authenticated;

create or replace function driver.admin_grant_access(
  p_email text,
  p_plan_type driver.plan_type,
  p_role driver.user_role default 'user',
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_target_id uuid;
  v_target_email text;
  v_full_name text;
  v_display_name text;
  v_role driver.user_role;
  v_status driver.subscription_status;
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  select
    u.id,
    u.email,
    nullif(trim(coalesce(
      u.raw_user_meta_data ->> 'full_name',
      u.raw_user_meta_data ->> 'name',
      ''
    )), ''),
    coalesce(
      nullif(trim(split_part(coalesce(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        u.email,
        'Motorista'
      ), ' ', 1)), ''),
      'Motorista'
    )
  into
    v_target_id,
    v_target_email,
    v_full_name,
    v_display_name
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  if v_target_id is null then
    raise exception 'Usuario nao encontrado para o e-mail informado.'
      using errcode = 'P0002';
  end if;

  v_role := case
    when p_plan_type = 'developer' then 'developer'::driver.user_role
    else coalesce(p_role, 'user'::driver.user_role)
  end;

  v_status := case p_plan_type
    when 'free' then 'inactive'::driver.subscription_status
    when 'gift' then 'gifted'::driver.subscription_status
    else 'active'::driver.subscription_status
  end;

  insert into driver.profiles (
    id,
    email,
    full_name,
    display_name,
    role,
    plan_type,
    subscription_status,
    subscription_expires_at,
    current_period_end,
    gifted_by,
    gifted_at,
    updated_at
  )
  values (
    v_target_id,
    v_target_email,
    v_full_name,
    v_display_name,
    v_role,
    p_plan_type,
    v_status,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type = 'gift' then auth.uid() else null end,
    case when p_plan_type = 'gift' then v_now else null end,
    v_now
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(driver.profiles.full_name, excluded.full_name),
    display_name = coalesce(driver.profiles.display_name, excluded.display_name),
    role = v_role,
    plan_type = p_plan_type,
    subscription_status = v_status,
    subscription_expires_at = case
      when p_plan_type in ('premium', 'gift') then p_expires_at
      else null
    end,
    current_period_end = case
      when p_plan_type in ('premium', 'gift') then p_expires_at
      else null
    end,
    gifted_by = case when p_plan_type = 'gift' then auth.uid() else null end,
    gifted_at = case when p_plan_type = 'gift' then v_now else null end,
    updated_at = v_now;

  insert into driver.subscriptions (
    user_id,
    plan_type,
    status,
    provider,
    started_at,
    expires_at,
    gifted_by,
    created_at,
    updated_at
  )
  values (
    v_target_id,
    p_plan_type,
    v_status,
    case
      when p_plan_type = 'gift' then 'gift_admin'
      when p_plan_type = 'developer' then 'developer_admin'
      else 'manual_admin'
    end,
    v_now,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type = 'gift' then auth.uid() else null end,
    v_now,
    v_now
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', v_target_id,
    'email', v_target_email,
    'message', format('Acesso %s aplicado para %s.', p_plan_type, v_target_email)
  );
end;
$$;

grant execute on function driver.admin_grant_access(
  text,
  driver.plan_type,
  driver.user_role,
  timestamptz
) to authenticated;
