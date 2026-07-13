-- Omnya Driver
-- Weekly mission claims and visible reward registration.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/024_driver_growth_operations.sql.

create table if not exists driver.driver_mission_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mission_key text not null references driver.driver_missions(mission_key),
  period_key text not null,
  reward_xp integer not null default 0,
  reward_title text,
  claimed_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, mission_key, period_key)
);

create index if not exists idx_driver_mission_claims_user_period
  on driver.driver_mission_claims (user_id, period_key, claimed_at desc);

alter table driver.driver_mission_claims enable row level security;

grant select, insert on driver.driver_mission_claims to authenticated;

drop policy if exists "driver_mission_claims_own_select"
  on driver.driver_mission_claims;
create policy "driver_mission_claims_own_select"
  on driver.driver_mission_claims
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "driver_mission_claims_own_insert"
  on driver.driver_mission_claims;
create policy "driver_mission_claims_own_insert"
  on driver.driver_mission_claims
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create or replace function driver.claim_driver_mission(p_mission_key text)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_mission driver.driver_missions%rowtype;
  v_period_key text := to_char(date_trunc('week', timezone('utc', now())), 'IYYY-IW');
  v_current_value integer := 0;
  v_claim_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  select *
  into v_mission
  from driver.driver_missions
  where mission_key = p_mission_key
    and active = true
  limit 1;

  if v_mission.id is null then
    raise exception 'Missao nao encontrada.'
      using errcode = 'P0002';
  end if;

  if v_mission.target_metric = 'journeys' then
    select count(*)::integer
    into v_current_value
    from driver.journeys
    where user_id = v_user_id
      and started_at >= date_trunc('week', timezone('utc', now()));
  elsif v_mission.target_metric = 'deliveries' then
    select coalesce(sum(jp.deliveries), 0)::integer
    into v_current_value
    from driver.journey_platforms jp
    join driver.journeys j on j.id = jp.journey_id
    where j.user_id = v_user_id
      and j.started_at >= date_trunc('week', timezone('utc', now()));
  elsif v_mission.target_metric = 'goals' then
    select count(*)::integer
    into v_current_value
    from driver.goals g
    where g.user_id = v_user_id
      and g.created_at >= date_trunc('week', timezone('utc', now()));
  elsif v_mission.target_metric = 'referrals' then
    select count(*)::integer
    into v_current_value
    from driver.driver_referrals r
    where r.referrer_user_id = v_user_id
      and r.accepted_at >= date_trunc('week', timezone('utc', now()));
  end if;

  if v_current_value < v_mission.target_value then
    return jsonb_build_object(
      'ok', false,
      'reason', 'not_completed',
      'current_value', v_current_value,
      'target_value', v_mission.target_value
    );
  end if;

  insert into driver.driver_mission_claims (
    user_id,
    mission_key,
    period_key,
    reward_xp,
    reward_title
  )
  values (
    v_user_id,
    v_mission.mission_key,
    v_period_key,
    v_mission.reward_xp,
    v_mission.reward_title
  )
  on conflict (user_id, mission_key, period_key) do nothing
  returning id into v_claim_id;

  if v_claim_id is null then
    return jsonb_build_object(
      'ok', false,
      'reason', 'already_claimed',
      'period_key', v_period_key
    );
  end if;

  insert into driver.driver_medal_unlocks (
    user_id,
    medal_key,
    medal_name,
    description,
    metadata
  )
  values (
    v_user_id,
    'mission_' || v_mission.mission_key || '_' || v_period_key,
    coalesce(v_mission.reward_title, v_mission.title),
    v_mission.description,
    jsonb_build_object(
      'mission_key', v_mission.mission_key,
      'period_key', v_period_key,
      'reward_xp', v_mission.reward_xp
    )
  )
  on conflict (user_id, medal_key) do nothing;

  perform driver.refresh_driver_progress(v_user_id);

  return jsonb_build_object(
    'ok', true,
    'claim_id', v_claim_id,
    'period_key', v_period_key,
    'reward_xp', v_mission.reward_xp,
    'reward_title', v_mission.reward_title
  );
end;
$$;

grant execute on function driver.claim_driver_mission(text) to authenticated;

