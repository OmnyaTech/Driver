-- Omnya Driver
-- Developer gift access control: list, update expiration and revoke gifts.
-- Date: 2026-07-14
-- Execute manually in Supabase SQL Editor after sql/manual/037_driver_onboarding_vehicle_metrics_refinements.sql.

create or replace function driver.admin_list_gift_accesses()
returns table (
  user_id uuid,
  email text,
  display_name text,
  full_name text,
  plan_type text,
  subscription_status text,
  gifted_at timestamptz,
  expires_at timestamptz,
  gifted_by_email text,
  is_active_gift boolean,
  is_expired boolean
)
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id as user_id,
    p.email,
    p.display_name,
    p.full_name,
    p.plan_type::text,
    p.subscription_status::text,
    p.gifted_at,
    p.subscription_expires_at as expires_at,
    gifted_by_profile.email as gifted_by_email,
    (
      p.plan_type = 'gift'::driver.plan_type
      and p.subscription_status = 'gifted'::driver.subscription_status
      and (
        p.subscription_expires_at is null
        or p.subscription_expires_at >= timezone('utc', now())
      )
    ) as is_active_gift,
    (
      p.plan_type = 'gift'::driver.plan_type
      and p.subscription_expires_at is not null
      and p.subscription_expires_at < timezone('utc', now())
    ) as is_expired
  from driver.profiles p
  left join driver.profiles gifted_by_profile on gifted_by_profile.id = p.gifted_by
  where
    p.gifted_by is not null
    or p.gifted_at is not null
    or p.plan_type = 'gift'::driver.plan_type
    or p.subscription_status = 'gifted'::driver.subscription_status
  order by
    is_active_gift desc,
    p.gifted_at desc nulls last,
    p.updated_at desc;
end;
$$;

grant execute on function driver.admin_list_gift_accesses() to authenticated;

create or replace function driver.admin_update_gift_access(
  p_user_id uuid,
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_email text;
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  select email into v_email
  from driver.profiles
  where id = p_user_id
  limit 1;

  if v_email is null then
    raise exception 'Usuario nao encontrado.'
      using errcode = 'P0002';
  end if;

  update driver.profiles
  set
    plan_type = 'gift'::driver.plan_type,
    subscription_status = 'gifted'::driver.subscription_status,
    subscription_expires_at = p_expires_at,
    current_period_end = p_expires_at,
    gifted_by = coalesce(gifted_by, auth.uid()),
    gifted_at = coalesce(gifted_at, v_now),
    updated_at = v_now
  where id = p_user_id;

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
    p_user_id,
    'gift'::driver.plan_type,
    'gifted'::driver.subscription_status,
    'gift_admin_update',
    v_now,
    p_expires_at,
    auth.uid(),
    v_now,
    v_now
  );

  perform driver.write_admin_audit(
    p_action => 'gift_access_updated',
    p_target_user_id => p_user_id,
    p_summary => format('Presente atualizado para %s.', v_email),
    p_metadata => jsonb_build_object(
      'email', v_email,
      'expires_at', p_expires_at
    )
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', p_user_id,
    'email', v_email,
    'message', format('Presente atualizado para %s.', v_email)
  );
end;
$$;

grant execute on function driver.admin_update_gift_access(uuid, timestamptz) to authenticated;

create or replace function driver.admin_revoke_gift_access(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_email text;
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  select email into v_email
  from driver.profiles
  where id = p_user_id
  limit 1;

  if v_email is null then
    raise exception 'Usuario nao encontrado.'
      using errcode = 'P0002';
  end if;

  update driver.profiles
  set
    plan_type = case
      when plan_type = 'gift'::driver.plan_type then 'free'::driver.plan_type
      else plan_type
    end,
    subscription_status = case
      when subscription_status = 'gifted'::driver.subscription_status then 'inactive'::driver.subscription_status
      else subscription_status
    end,
    subscription_expires_at = null,
    current_period_end = null,
    updated_at = v_now
  where id = p_user_id;

  update driver.subscriptions
  set
    status = 'cancelled'::driver.subscription_status,
    cancelled_at = coalesce(cancelled_at, v_now),
    updated_at = v_now
  where user_id = p_user_id
    and plan_type = 'gift'::driver.plan_type
    and status = 'gifted'::driver.subscription_status;

  insert into driver.subscriptions (
    user_id,
    plan_type,
    status,
    provider,
    started_at,
    cancelled_at,
    created_at,
    updated_at
  )
  values (
    p_user_id,
    'free'::driver.plan_type,
    'inactive'::driver.subscription_status,
    'gift_admin_revoke',
    v_now,
    v_now,
    v_now,
    v_now
  );

  perform driver.write_admin_audit(
    p_action => 'gift_access_revoked',
    p_target_user_id => p_user_id,
    p_summary => format('Presente revogado para %s.', v_email),
    p_metadata => jsonb_build_object('email', v_email)
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', p_user_id,
    'email', v_email,
    'message', format('Presente revogado para %s.', v_email)
  );
end;
$$;

grant execute on function driver.admin_revoke_gift_access(uuid) to authenticated;
