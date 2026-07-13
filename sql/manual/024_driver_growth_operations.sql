-- Omnya Driver
-- Growth, operations, advanced gamification, public profile and backend push queue.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/023_driver_platform_catalog.sql.

alter table driver.profiles
  add column if not exists public_title text,
  add column if not exists public_banner_url text,
  add column if not exists selected_badge_keys text[] not null default '{}'::text[];

alter table driver.subscriptions
  add column if not exists cancel_requested_at timestamptz,
  add column if not exists cancel_reason text,
  add column if not exists scheduled_plan_type driver.plan_type,
  add column if not exists scheduled_plan_starts_at timestamptz;

create table if not exists driver.driver_missions (
  id uuid primary key default gen_random_uuid(),
  mission_key text not null unique,
  title text not null,
  description text not null,
  cadence text not null default 'weekly',
  target_metric text not null,
  target_value integer not null,
  reward_xp integer not null default 25,
  reward_title text,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

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
    'weekly_3_journeys',
    'Semana em movimento',
    'Registre 3 jornadas na semana para manter o ritmo.',
    'weekly',
    'journeys',
    3,
    35,
    'Motorista constante'
  ),
  (
    'weekly_25_deliveries',
    'Entrega no sangue',
    'Some 25 entregas na semana e suba no placar.',
    'weekly',
    'deliveries',
    25,
    45,
    'Ritmo forte'
  ),
  (
    'weekly_1_goal',
    'Dinheiro com destino',
    'Crie ou conclua uma meta para organizar melhor o que sobrou.',
    'weekly',
    'goals',
    1,
    30,
    'Planejador'
  ),
  (
    'weekly_invite',
    'Chame um parceiro',
    'Convide um motorista e ganhe reconhecimento no perfil.',
    'weekly',
    'referrals',
    1,
    50,
    'Embaixador Omnya'
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

create table if not exists driver.driver_push_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_key text,
  event_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  scheduled_at timestamptz not null default timezone('utc', now()),
  sent_at timestamptz,
  failed_at timestamptz,
  failure_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, notification_key)
);

create index if not exists idx_driver_push_jobs_status_scheduled
  on driver.driver_push_jobs (status, scheduled_at);

alter table driver.driver_push_jobs enable row level security;

grant select, insert, update on driver.driver_push_jobs to authenticated;

drop policy if exists "driver_push_jobs_own_select" on driver.driver_push_jobs;
create policy "driver_push_jobs_own_select"
  on driver.driver_push_jobs
  for select
  to authenticated
  using (auth.uid() = user_id or driver.is_requester_developer());

drop policy if exists "driver_push_jobs_developer_update" on driver.driver_push_jobs;
create policy "driver_push_jobs_developer_update"
  on driver.driver_push_jobs
  for update
  to authenticated
  using (driver.is_requester_developer())
  with check (driver.is_requester_developer());

create or replace function driver.enqueue_driver_push(
  p_user_id uuid,
  p_event_type text,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb,
  p_notification_key text default null,
  p_scheduled_at timestamptz default timezone('utc', now())
)
returns uuid
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_id uuid;
  v_notification_key text := nullif(trim(coalesce(p_notification_key, '')), '');
begin
  if auth.uid() is null and not driver.is_requester_developer() then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if auth.uid() is distinct from p_user_id and not driver.is_requester_developer() then
    raise exception 'Nao autorizado a criar push para outro usuario.'
      using errcode = '42501';
  end if;

  insert into driver.driver_push_jobs (
    user_id,
    notification_key,
    event_type,
    title,
    body,
    payload,
    scheduled_at
  )
  values (
    p_user_id,
    v_notification_key,
    nullif(trim(coalesce(p_event_type, '')), ''),
    nullif(trim(coalesce(p_title, '')), ''),
    nullif(trim(coalesce(p_body, '')), ''),
    coalesce(p_payload, '{}'::jsonb),
    coalesce(p_scheduled_at, timezone('utc', now()))
  )
  on conflict (user_id, notification_key) do update
  set
    event_type = excluded.event_type,
    title = excluded.title,
    body = excluded.body,
    payload = excluded.payload,
    status = 'queued',
    scheduled_at = excluded.scheduled_at,
    sent_at = null,
    failed_at = null,
    failure_reason = null,
    updated_at = timezone('utc', now())
  returning id into v_id;

  insert into driver.driver_notifications (
    user_id,
    notification_key,
    kind,
    title,
    body,
    action_type,
    action_payload,
    delivered_at
  )
  values (
    p_user_id,
    coalesce(v_notification_key, 'push-' || v_id::text),
    coalesce(nullif(trim(p_event_type), ''), 'system'),
    p_title,
    p_body,
    p_event_type,
    coalesce(p_payload, '{}'::jsonb),
    null
  )
  on conflict (user_id, notification_key) do nothing;

  return v_id;
end;
$$;

grant execute on function driver.enqueue_driver_push(
  uuid,
  text,
  text,
  text,
  jsonb,
  text,
  timestamptz
) to authenticated;

create or replace function driver.request_subscription_cancellation(
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_subscription_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.subscriptions
  set
    cancel_requested_at = timezone('utc', now()),
    cancel_reason = nullif(trim(coalesce(p_reason, '')), ''),
    updated_at = timezone('utc', now())
  where user_id = v_user_id
    and cancelled_at is null
    and status in (
      'active'::driver.subscription_status,
      'pending'::driver.subscription_status,
      'overdue'::driver.subscription_status,
      'gifted'::driver.subscription_status
    )
  returning id into v_subscription_id;

  if v_subscription_id is null then
    return jsonb_build_object(
      'ok', false,
      'reason', 'no_current_subscription',
      'message', 'Nenhum plano ativo ou pendente encontrado.'
    );
  end if;

  perform driver.record_billing_event(
    p_provider => 'asaas',
    p_event_type => 'cancel_requested',
    p_provider_object_id => null,
    p_external_reference => null,
    p_user_id => v_user_id,
    p_status => 'requested',
    p_payload => jsonb_build_object('reason', nullif(trim(coalesce(p_reason, '')), ''))
  );

  return jsonb_build_object(
    'ok', true,
    'subscription_id', v_subscription_id,
    'status', 'cancel_requested'
  );
end;
$$;

grant execute on function driver.request_subscription_cancellation(text)
  to authenticated;

create or replace function driver.request_subscription_plan_change(
  p_plan_type driver.plan_type
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_subscription_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.subscriptions
  set
    scheduled_plan_type = p_plan_type,
    scheduled_plan_starts_at = coalesce(expires_at, timezone('utc', now())),
    updated_at = timezone('utc', now())
  where user_id = v_user_id
    and cancelled_at is null
    and status in (
      'active'::driver.subscription_status,
      'overdue'::driver.subscription_status,
      'gifted'::driver.subscription_status
    )
  returning id into v_subscription_id;

  if v_subscription_id is null then
    return jsonb_build_object(
      'ok', false,
      'reason', 'no_active_subscription',
      'message', 'Assine primeiro para trocar de plano.'
    );
  end if;

  perform driver.record_billing_event(
    p_provider => 'asaas',
    p_event_type => 'plan_change_requested',
    p_provider_object_id => null,
    p_external_reference => null,
    p_user_id => v_user_id,
    p_status => 'requested',
    p_payload => jsonb_build_object('plan_type', p_plan_type::text)
  );

  return jsonb_build_object(
    'ok', true,
    'subscription_id', v_subscription_id,
    'scheduled_plan_type', p_plan_type::text
  );
end;
$$;

grant execute on function driver.request_subscription_plan_change(driver.plan_type)
  to authenticated;

create or replace function driver.get_driver_growth_summary()
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_progress driver.driver_progress%rowtype;
  v_total_deliveries integer := 0;
  v_total_journeys integer := 0;
  v_account_days integer := 0;
  v_referrals integer := 0;
  v_goals_touched integer := 0;
  v_tier text := 'Bronze';
  v_next_tier_score integer := 500;
  v_missions jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  perform driver.refresh_driver_progress(v_user_id);

  select *
  into v_progress
  from driver.driver_progress
  where user_id = v_user_id
  limit 1;

  select
    count(*)::integer,
    greatest(((timezone('utc', now()))::date - min(p.created_at)::date), 0)::integer
  into v_total_journeys, v_account_days
  from driver.profiles p
  left join driver.journeys j on j.user_id = p.id
  where p.id = v_user_id
  group by p.id;

  select coalesce(sum(jp.deliveries), 0)::integer
  into v_total_deliveries
  from driver.journey_platforms jp
  join driver.journeys j on j.id = jp.journey_id
  where j.user_id = v_user_id;

  select count(*)::integer
  into v_referrals
  from driver.driver_referrals r
  where r.referrer_user_id = v_user_id;

  select count(*)::integer
  into v_goals_touched
  from driver.goals g
  where g.user_id = v_user_id;

  v_tier := case
    when coalesce(v_progress.public_score, 0) >= 5000 then 'Lendaria'
    when coalesce(v_progress.public_score, 0) >= 2500 then 'Diamante'
    when coalesce(v_progress.public_score, 0) >= 1200 then 'Ouro'
    when coalesce(v_progress.public_score, 0) >= 500 then 'Prata'
    else 'Bronze'
  end;

  v_next_tier_score := case
    when coalesce(v_progress.public_score, 0) >= 5000 then null
    when coalesce(v_progress.public_score, 0) >= 2500 then 5000
    when coalesce(v_progress.public_score, 0) >= 1200 then 2500
    when coalesce(v_progress.public_score, 0) >= 500 then 1200
    else 500
  end;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'key', mission_key,
        'title', title,
        'description', description,
        'cadence', cadence,
        'target_metric', target_metric,
        'target_value', target_value,
        'reward_xp', reward_xp,
        'reward_title', reward_title,
        'current_value',
          case target_metric
            when 'journeys' then v_total_journeys
            when 'deliveries' then v_total_deliveries
            when 'goals' then v_goals_touched
            when 'referrals' then v_referrals
            else 0
          end,
        'completed',
          (
            case target_metric
              when 'journeys' then v_total_journeys
              when 'deliveries' then v_total_deliveries
              when 'goals' then v_goals_touched
              when 'referrals' then v_referrals
              else 0
            end
          ) >= target_value
      )
      order by target_value
    ),
    '[]'::jsonb
  )
  into v_missions
  from driver.driver_missions
  where active = true;

  return jsonb_build_object(
    'tier', v_tier,
    'next_tier_score', v_next_tier_score,
    'public_score', coalesce(v_progress.public_score, 0),
    'missions', v_missions,
    'stats', jsonb_build_object(
      'total_deliveries', v_total_deliveries,
      'total_journeys', v_total_journeys,
      'account_days', v_account_days,
      'referrals', v_referrals,
      'medals_count', coalesce(v_progress.medals_count, 0),
      'best_streak_days', coalesce(v_progress.best_streak_days, 0)
    )
  );
end;
$$;

grant execute on function driver.get_driver_growth_summary() to authenticated;

create or replace function driver.get_developer_metrics()
returns jsonb
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

  return jsonb_build_object(
    'users', (
      select jsonb_build_object(
        'total', count(*)::integer,
        'onboarded', count(*) filter (where onboarding_completed_at is not null)::integer,
        'public_profiles', count(*) filter (where public_profile_enabled = true)::integer
      )
      from driver.profiles
    ),
    'activity', (
      select jsonb_build_object(
        'dau', count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '1 day')::integer,
        'wau', count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '7 days')::integer,
        'mau', count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '30 days')::integer,
        'journeys_30d', count(*) filter (where started_at >= timezone('utc', now()) - interval '30 days')::integer
      )
      from driver.journeys
    ),
    'billing', (
      select jsonb_build_object(
        'active', count(*) filter (where subscription_status in ('active'::driver.subscription_status, 'gifted'::driver.subscription_status))::integer,
        'pending', count(*) filter (where subscription_status = 'pending'::driver.subscription_status)::integer,
        'free', count(*) filter (where plan_type = 'free'::driver.plan_type)::integer,
        'premium', count(*) filter (where plan_type = 'premium'::driver.plan_type)::integer
      )
      from driver.profiles
    ),
    'devices', (
      select jsonb_build_object(
        'push_enabled', count(*) filter (where enabled = true)::integer,
        'web', count(*) filter (where platform = 'web')::integer,
        'android', count(*) filter (where platform = 'android')::integer,
        'ios', count(*) filter (where platform = 'ios')::integer
      )
      from driver.driver_push_devices
    ),
    'preferences', (
      select jsonb_build_object(
        'pt_br', count(*) filter (where language_code = 'pt-BR')::integer,
        'en_us', count(*) filter (where language_code = 'en-US')::integer,
        'es_es', count(*) filter (where language_code = 'es-ES')::integer,
        'brl', count(*) filter (where currency_code = 'BRL')::integer,
        'usd', count(*) filter (where currency_code = 'USD')::integer,
        'eur', count(*) filter (where currency_code = 'EUR')::integer
      )
      from driver.profiles
    )
  );
end;
$$;

grant execute on function driver.get_developer_metrics() to authenticated;

create or replace function driver.get_public_driver_profile_v2(p_slug text)
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
declare
  v_profile record;
  v_progress driver.driver_progress%rowtype;
  v_records jsonb;
  v_total_deliveries integer := 0;
  v_account_days integer := 0;
  v_badges jsonb := '[]'::jsonb;
  v_tier text := 'Bronze';
begin
  select
    p.id,
    p.display_name,
    p.avatar_url,
    p.public_slug,
    p.public_bio,
    p.public_city,
    p.public_title,
    p.public_banner_url,
    p.selected_badge_keys,
    p.created_at,
    p.public_profile_enabled
  into v_profile
  from driver.profiles p
  where lower(p.public_slug) = lower(trim(p_slug))
  limit 1;

  if v_profile.id is null or v_profile.public_profile_enabled is distinct from true then
    return null;
  end if;

  select *
  into v_progress
  from driver.driver_progress dp
  where dp.user_id = v_profile.id
  limit 1;

  v_records := driver.get_driver_records(v_profile.id);

  select coalesce(sum(jp.deliveries), 0)::integer
  into v_total_deliveries
  from driver.journey_platforms jp
  join driver.journeys j on j.id = jp.journey_id
  where j.user_id = v_profile.id;

  v_account_days := greatest(((timezone('utc', now()))::date - v_profile.created_at::date), 0)::integer;

  v_tier := case
    when coalesce(v_progress.public_score, 0) >= 5000 then 'Lendaria'
    when coalesce(v_progress.public_score, 0) >= 2500 then 'Diamante'
    when coalesce(v_progress.public_score, 0) >= 1200 then 'Ouro'
    when coalesce(v_progress.public_score, 0) >= 500 then 'Prata'
    else 'Bronze'
  end;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'key', m.medal_key,
        'name', m.medal_name,
        'description', m.description,
        'awarded_at', m.awarded_at
      )
      order by m.awarded_at desc
    ),
    '[]'::jsonb
  )
  into v_badges
  from driver.driver_medal_unlocks m
  where m.user_id = v_profile.id
    and (
      coalesce(array_length(v_profile.selected_badge_keys, 1), 0) = 0
      or m.medal_key = any(v_profile.selected_badge_keys)
    )
  limit 8;

  return jsonb_build_object(
    'display_name', v_profile.display_name,
    'avatar_url', v_profile.avatar_url,
    'public_slug', v_profile.public_slug,
    'public_bio', v_profile.public_bio,
    'public_city', v_profile.public_city,
    'public_title', coalesce(v_profile.public_title, v_progress.level_title),
    'public_banner_url', v_profile.public_banner_url,
    'tier', v_tier,
    'level', v_progress.level,
    'level_title', v_progress.level_title,
    'xp', v_progress.xp,
    'medals_count', v_progress.medals_count,
    'current_streak_days', v_progress.current_streak_days,
    'best_streak_days', v_progress.best_streak_days,
    'public_score', v_progress.public_score,
    'stats', jsonb_build_object(
      'total_deliveries', v_total_deliveries,
      'account_days', v_account_days
    ),
    'badges', v_badges,
    'records', jsonb_build_object(
      'best_friday', jsonb_build_object(
        'date', v_records->'best_friday'->>'date',
        'has_record', (v_records->'best_friday') is not null
      ),
      'highest_revenue_day', jsonb_build_object(
        'date', v_records->'highest_revenue_day'->>'date',
        'has_record', (v_records->'highest_revenue_day') is not null
      ),
      'highest_profit_per_hour', jsonb_build_object(
        'started_at', v_records->'highest_profit_per_hour'->>'started_at',
        'has_record', (v_records->'highest_profit_per_hour') is not null
      ),
      'highest_deliveries_day', jsonb_build_object(
        'date', v_records->'highest_deliveries_day'->>'date',
        'deliveries', coalesce((v_records->'highest_deliveries_day'->>'deliveries')::integer, 0)
      )
    )
  );
end;
$$;

grant execute on function driver.get_public_driver_profile_v2(text)
  to authenticated;
