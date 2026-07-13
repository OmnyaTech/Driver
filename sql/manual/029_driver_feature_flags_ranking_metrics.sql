-- Omnya Driver
-- Feature flags, scoped ranking and richer developer metrics.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/024_driver_growth_operations.sql.

create table if not exists driver.feature_flags (
  id uuid primary key default gen_random_uuid(),
  flag_key text not null unique,
  description text,
  enabled boolean not null default false,
  min_app_version text,
  required_plan_type driver.plan_type,
  rollout_percentage integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint feature_flags_rollout_range check (rollout_percentage between 0 and 100)
);

alter table driver.feature_flags enable row level security;

grant select on driver.feature_flags to authenticated;
grant insert, update, delete on driver.feature_flags to authenticated;

drop policy if exists "driver_feature_flags_authenticated_select"
  on driver.feature_flags;
create policy "driver_feature_flags_authenticated_select"
  on driver.feature_flags
  for select
  to authenticated
  using (true);

drop policy if exists "driver_feature_flags_developer_insert"
  on driver.feature_flags;
create policy "driver_feature_flags_developer_insert"
  on driver.feature_flags
  for insert
  to authenticated
  with check (driver.is_requester_developer());

drop policy if exists "driver_feature_flags_developer_update"
  on driver.feature_flags;
create policy "driver_feature_flags_developer_update"
  on driver.feature_flags
  for update
  to authenticated
  using (driver.is_requester_developer())
  with check (driver.is_requester_developer());

drop policy if exists "driver_feature_flags_developer_delete"
  on driver.feature_flags;
create policy "driver_feature_flags_developer_delete"
  on driver.feature_flags
  for delete
  to authenticated
  using (driver.is_requester_developer());

insert into driver.feature_flags (
  flag_key,
  description,
  enabled,
  required_plan_type,
  metadata
)
values
  (
    'android_direct_journey_finish',
    'Permite encerrar jornada pela notificacao ativa quando o fluxo nativo estiver pronto.',
    false,
    null,
    jsonb_build_object('area', 'journey')
  ),
  (
    'premium_exports',
    'Libera exportacoes PDF e Excel ricas para assinantes Premium.',
    true,
    'premium'::driver.plan_type,
    jsonb_build_object('area', 'reports')
  ),
  (
    'ranking_scopes',
    'Habilita ranking local, estadual, nacional e global.',
    true,
    null,
    jsonb_build_object('area', 'social')
  ),
  (
    'legendary_missions',
    'Habilita missoes especiais e lendarias de temporada.',
    false,
    null,
    jsonb_build_object('area', 'gamification')
  ),
  (
    'public_profile_customization',
    'Habilita banner, badges escolhidos e personalizacao visual do perfil publico.',
    true,
    null,
    jsonb_build_object('area', 'social')
  )
on conflict (flag_key) do update
set
  description = excluded.description,
  required_plan_type = excluded.required_plan_type,
  metadata = excluded.metadata,
  updated_at = timezone('utc', now());

create or replace function driver.get_feature_flags()
returns jsonb
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  select coalesce(
    jsonb_object_agg(
      flag_key,
      jsonb_build_object(
        'enabled', enabled,
        'min_app_version', min_app_version,
        'required_plan_type', required_plan_type,
        'rollout_percentage', rollout_percentage,
        'metadata', metadata
      )
    ),
    '{}'::jsonb
  )
  from driver.feature_flags;
$$;

grant execute on function driver.get_feature_flags() to authenticated;

create or replace function driver.get_public_ranking_by_scope(
  p_scope text default 'global',
  p_limit integer default 50
)
returns table (
  rank_position bigint,
  public_slug text,
  display_name text,
  avatar_url text,
  public_city text,
  city text,
  state text,
  country text,
  level integer,
  level_title text,
  medals_count integer,
  public_score integer,
  best_streak_days integer,
  tier text
)
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  with viewer as (
    select
      lower(coalesce(city, public_city, '')) as city_value,
      lower(coalesce(state, '')) as state_value,
      lower(coalesce(country, 'Brasil')) as country_value
    from driver.profiles
    where id = auth.uid()
    limit 1
  ),
  candidates as (
    select
      p.public_slug,
      p.display_name,
      p.avatar_url,
      p.public_city,
      p.city,
      p.state,
      p.country,
      dp.level,
      dp.level_title,
      dp.medals_count,
      dp.public_score,
      dp.best_streak_days,
      case
        when coalesce(dp.public_score, 0) >= 5000 then 'Lendaria'
        when coalesce(dp.public_score, 0) >= 2500 then 'Diamante'
        when coalesce(dp.public_score, 0) >= 1200 then 'Ouro'
        when coalesce(dp.public_score, 0) >= 500 then 'Prata'
        else 'Bronze'
      end as tier
    from driver.profiles p
    join driver.driver_progress dp on dp.user_id = p.id
    cross join viewer v
    where p.public_profile_enabled = true
      and p.public_slug is not null
      and dp.ranking_opt_in = true
      and (
        lower(coalesce(p_scope, 'global')) = 'global'
        or (
          lower(coalesce(p_scope, 'global')) = 'local'
          and lower(coalesce(p.city, p.public_city, '')) = v.city_value
          and v.city_value <> ''
        )
        or (
          lower(coalesce(p_scope, 'global')) = 'state'
          and lower(coalesce(p.state, '')) = v.state_value
          and v.state_value <> ''
        )
        or (
          lower(coalesce(p_scope, 'global')) = 'national'
          and lower(coalesce(p.country, 'Brasil')) = v.country_value
        )
      )
  ),
  ranked as (
    select
      row_number() over (
        order by public_score desc, medals_count desc, best_streak_days desc, display_name asc
      ) as rank_position,
      *
    from candidates
  )
  select *
  from ranked
  order by rank_position
  limit greatest(coalesce(p_limit, 50), 1);
$$;

grant execute on function driver.get_public_ranking_by_scope(text, integer)
  to authenticated;

create or replace function driver.get_developer_metrics()
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
declare
  v_total_users integer := 0;
  v_onboarded integer := 0;
  v_active integer := 0;
  v_active_7d integer := 0;
  v_active_30d integer := 0;
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  select
    count(*)::integer,
    count(*) filter (where onboarding_completed_at is not null)::integer,
    count(*) filter (where subscription_status in ('active'::driver.subscription_status, 'gifted'::driver.subscription_status))::integer
  into v_total_users, v_onboarded, v_active
  from driver.profiles;

  select
    count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '7 days')::integer,
    count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '30 days')::integer
  into v_active_7d, v_active_30d
  from driver.journeys;

  return jsonb_build_object(
    'users', (
      select jsonb_build_object(
        'total', v_total_users,
        'onboarded', v_onboarded,
        'public_profiles', count(*) filter (where public_profile_enabled = true)::integer
      )
      from driver.profiles
    ),
    'activity', (
      select jsonb_build_object(
        'dau', count(distinct user_id) filter (where started_at >= timezone('utc', now()) - interval '1 day')::integer,
        'wau', v_active_7d,
        'mau', v_active_30d,
        'journeys_30d', count(*) filter (where started_at >= timezone('utc', now()) - interval '30 days')::integer
      )
      from driver.journeys
    ),
    'retention', jsonb_build_object(
      'active_7d', v_active_7d,
      'active_30d', v_active_30d,
      'active_7d_pct', case when v_total_users = 0 then 0 else round((v_active_7d::numeric / v_total_users::numeric) * 100, 1) end,
      'active_30d_pct', case when v_total_users = 0 then 0 else round((v_active_30d::numeric / v_total_users::numeric) * 100, 1) end
    ),
    'conversion', jsonb_build_object(
      'onboarding_pct', case when v_total_users = 0 then 0 else round((v_onboarded::numeric / v_total_users::numeric) * 100, 1) end,
      'paid_pct', case when v_total_users = 0 then 0 else round((v_active::numeric / v_total_users::numeric) * 100, 1) end
    ),
    'billing', (
      select jsonb_build_object(
        'active', v_active,
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
    'push_jobs', (
      select jsonb_build_object(
        'queued', count(*) filter (where status = 'queued')::integer,
        'sent', count(*) filter (where status = 'sent')::integer,
        'failed', count(*) filter (where status = 'failed')::integer,
        'last_24h', count(*) filter (where created_at >= timezone('utc', now()) - interval '24 hours')::integer
      )
      from driver.driver_push_jobs
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
    ),
    'feature_flags', (
      select jsonb_build_object(
        'total', count(*)::integer,
        'enabled', count(*) filter (where enabled = true)::integer,
        'disabled', count(*) filter (where enabled = false)::integer
      )
      from driver.feature_flags
    )
  );
end;
$$;

grant execute on function driver.get_developer_metrics() to authenticated;
