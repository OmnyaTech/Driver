-- Omnya Driver
-- Product completion helpers: LGPD deletion workflow, public showcase and special missions.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/030_driver_product_events.sql.

alter table driver.account_deletion_requests
  add column if not exists scheduled_deletion_at timestamptz,
  add column if not exists cancelled_at timestamptz,
  add column if not exists cancel_reason text;

update driver.account_deletion_requests
set scheduled_deletion_at = coalesce(scheduled_deletion_at, requested_at + interval '30 days')
where status = 'requested'
  and scheduled_deletion_at is null;

create or replace function driver.cancel_account_deletion_request(
  p_reason text default 'user_returned'
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.account_deletion_requests
  set
    status = 'cancelled',
    cancelled_at = timezone('utc', now()),
    cancel_reason = nullif(trim(coalesce(p_reason, '')), ''),
    processed_at = null
  where user_id = v_user_id
    and status = 'requested'
  returning id into v_request_id;

  return jsonb_build_object(
    'ok', v_request_id is not null,
    'request_id', v_request_id,
    'status', case when v_request_id is null then 'not_found' else 'cancelled' end
  );
end;
$$;

grant execute on function driver.cancel_account_deletion_request(text)
  to authenticated;

create or replace function driver.mark_due_account_deletion_requests()
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_marked integer := 0;
begin
  if auth.uid() is not null and not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.account_deletion_requests
  set
    status = 'ready_for_processing',
    processed_at = timezone('utc', now())
  where status = 'requested'
    and coalesce(scheduled_deletion_at, requested_at + interval '30 days') <= timezone('utc', now());

  get diagnostics v_marked = row_count;

  return jsonb_build_object(
    'ok', true,
    'ready_for_processing', v_marked
  );
end;
$$;

grant execute on function driver.mark_due_account_deletion_requests()
  to authenticated;

insert into driver.driver_missions (
  mission_key,
  title,
  description,
  cadence,
  target_metric,
  target_value,
  reward_xp,
  reward_title
)
values
  (
    'special_first_100_deliveries',
    'Centena no placar',
    'Bata 100 entregas registradas e desbloqueie um marco especial no perfil.',
    'special',
    'deliveries',
    100,
    120,
    'Centenario'
  ),
  (
    'special_10_referrals',
    'Embaixador da pista',
    'Convide 10 motoristas para a comunidade Omnya Driver.',
    'special',
    'referrals',
    10,
    200,
    'Embaixador da pista'
  ),
  (
    'legendary_1000_deliveries',
    'Lenda das entregas',
    'Chegue a 1000 entregas registradas e entre no grupo lendario.',
    'legendary',
    'deliveries',
    1000,
    600,
    'Lenda das entregas'
  )
on conflict (mission_key) do update
set
  title = excluded.title,
  description = excluded.description,
  cadence = excluded.cadence,
  target_metric = excluded.target_metric,
  target_value = excluded.target_value,
  reward_xp = excluded.reward_xp,
  reward_title = excluded.reward_title,
  active = true,
  updated_at = timezone('utc', now());

create or replace function driver.update_public_profile_showcase(
  p_public_title text default null,
  p_public_banner_url text default null,
  p_selected_badge_keys text[] default '{}'::text[]
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_allowed_badges text[];
  v_selected_badges text[] := coalesce(p_selected_badge_keys, '{}'::text[]);
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  select coalesce(array_agg(medal_key), '{}'::text[])
  into v_allowed_badges
  from driver.driver_medal_unlocks
  where user_id = v_user_id;

  if exists (
    select 1
    from unnest(v_selected_badges) selected_badge
    where selected_badge <> all(v_allowed_badges)
  ) then
    raise exception 'Selecione apenas conquistas que voce ja desbloqueou.'
      using errcode = '42501';
  end if;

  update driver.profiles
  set
    public_title = nullif(trim(coalesce(p_public_title, '')), ''),
    public_banner_url = nullif(trim(coalesce(p_public_banner_url, '')), ''),
    selected_badge_keys = v_selected_badges,
    updated_at = timezone('utc', now())
  where id = v_user_id;

  return jsonb_build_object(
    'ok', true,
    'selected_badges', coalesce(array_length(v_selected_badges, 1), 0)
  );
end;
$$;

grant execute on function driver.update_public_profile_showcase(text, text, text[])
  to authenticated;
