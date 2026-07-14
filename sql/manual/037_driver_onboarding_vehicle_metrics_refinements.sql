-- Omnya Driver
-- Onboarding/vehicle refinements and paid subscriber metrics.
-- Date: 2026-07-14
-- Execute manually in Supabase SQL Editor after sql/manual/036_driver_disable_global_profile_bootstrap.sql.

alter table driver.vehicles
  add column if not exists vehicle_type text,
  add column if not exists fuel_types text[] not null default '{}'::text[];

update driver.vehicles
set fuel_types = array[fuel_type]
where fuel_type is not null
  and trim(fuel_type) <> ''
  and coalesce(array_length(fuel_types, 1), 0) = 0;

create index if not exists idx_driver_vehicles_vehicle_type
  on driver.vehicles (vehicle_type);

comment on column driver.vehicles.vehicle_type is
  'Driver vehicle type selected in the app, such as Moto, Carro, Bicicleta, Van or Patinete.';

comment on column driver.vehicles.fuel_types is
  'Driver multi-select fuel catalog. fuel_type remains as legacy display fallback.';

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
  v_paid_subscribers integer := 0;
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
    count(*) filter (
      where subscription_status = 'active'::driver.subscription_status
        and plan_type in ('premium'::driver.plan_type, 'lifetime'::driver.plan_type)
        and role <> 'developer'::driver.user_role
    )::integer
  into v_total_users, v_onboarded, v_paid_subscribers
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
      'paid_pct', case when v_total_users = 0 then 0 else round((v_paid_subscribers::numeric / v_total_users::numeric) * 100, 1) end
    ),
    'billing', (
      select jsonb_build_object(
        'active', v_paid_subscribers,
        'paid_subscribers', v_paid_subscribers,
        'gift', count(*) filter (where plan_type = 'gift'::driver.plan_type or subscription_status = 'gifted'::driver.subscription_status)::integer,
        'developer', count(*) filter (where role = 'developer'::driver.user_role or plan_type = 'developer'::driver.plan_type)::integer,
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
