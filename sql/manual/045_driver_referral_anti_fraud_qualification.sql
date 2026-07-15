-- Omnya Driver
-- Referral anti-fraud qualification.
-- Date: 2026-07-15
-- Execute manually in Supabase SQL Editor after 044.

alter table driver.driver_referrals
  add column if not exists status text not null default 'pending',
  add column if not exists qualified_at timestamptz,
  add column if not exists qualification_reason text,
  add column if not exists reward_awarded_at timestamptz;

alter table driver.driver_referrals
  drop constraint if exists driver_referrals_status_check;

alter table driver.driver_referrals
  add constraint driver_referrals_status_check
  check (status in ('pending', 'qualified'));

create index if not exists idx_driver_referrals_referrer_qualified_at
  on driver.driver_referrals (referrer_user_id, qualified_at desc)
  where qualified_at is not null;

create or replace function driver.qualify_driver_referral(
  p_referred_user_id uuid,
  p_reason text default 'email_confirmed'
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_referral driver.driver_referrals%rowtype;
  v_medal_key text;
begin
  if p_referred_user_id is null then
    return jsonb_build_object('qualified', false, 'reason', 'missing_user');
  end if;

  select *
  into v_referral
  from driver.driver_referrals r
  where r.referred_user_id = p_referred_user_id
  limit 1;

  if v_referral.id is null then
    return jsonb_build_object('qualified', false, 'reason', 'referral_not_found');
  end if;

  if v_referral.status = 'qualified' then
    return jsonb_build_object(
      'qualified', true,
      'reason', 'already_qualified',
      'referral_id', v_referral.id
    );
  end if;

  update driver.driver_referrals
  set
    status = 'qualified',
    qualified_at = timezone('utc', now()),
    qualification_reason = coalesce(nullif(trim(p_reason), ''), 'email_confirmed'),
    reward_awarded_at = timezone('utc', now())
  where id = v_referral.id
  returning * into v_referral;

  v_medal_key := 'referral_' || left(replace(v_referral.referred_user_id::text, '-', ''), 12);

  insert into driver.driver_medal_unlocks (
    user_id,
    medal_key,
    medal_name,
    description,
    metadata
  )
  values (
    v_referral.referrer_user_id,
    v_medal_key,
    'Convite confirmado',
    'Um entregador confirmou a conta depois de entrar pelo seu convite.',
    jsonb_build_object(
      'referred_user_id', v_referral.referred_user_id,
      'referral_id', v_referral.id,
      'reward_xp', v_referral.reward_xp,
      'qualification_reason', v_referral.qualification_reason
    )
  )
  on conflict (user_id, medal_key) do nothing;

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
    v_referral.referrer_user_id,
    'referral-qualified-' || v_referral.id::text,
    'gamification',
    'Convite confirmado',
    'Um entregador confirmou a conta pelo seu link. Agora o convite conta para XP e missoes.',
    'gamification',
    jsonb_build_object('referral_id', v_referral.id),
    timezone('utc', now())
  )
  on conflict (user_id, notification_key) do nothing;

  perform driver.refresh_driver_progress(v_referral.referrer_user_id);

  return jsonb_build_object(
    'qualified', true,
    'referral_id', v_referral.id,
    'referrer_user_id', v_referral.referrer_user_id,
    'reward_xp', v_referral.reward_xp
  );
end;
$$;

grant execute on function driver.qualify_driver_referral(uuid, text)
  to authenticated;

create or replace function driver.accept_public_referral(p_referrer_slug text)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_referred_user_id uuid := auth.uid();
  v_referrer_user_id uuid;
  v_referrer_slug text := lower(trim(coalesce(p_referrer_slug, '')));
  v_referral_id uuid;
  v_email_confirmed_at timestamptz;
begin
  if v_referred_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if v_referrer_slug = '' then
    return jsonb_build_object('accepted', false, 'reason', 'empty_slug');
  end if;

  select p.id
  into v_referrer_user_id
  from driver.profiles p
  where lower(p.public_slug) = v_referrer_slug
    and p.public_profile_enabled = true
  limit 1;

  if v_referrer_user_id is null then
    return jsonb_build_object('accepted', false, 'reason', 'referrer_not_found');
  end if;

  if v_referrer_user_id = v_referred_user_id then
    return jsonb_build_object('accepted', false, 'reason', 'self_referral');
  end if;

  insert into driver.driver_referrals (
    referrer_user_id,
    referred_user_id,
    referrer_slug,
    status
  )
  values (
    v_referrer_user_id,
    v_referred_user_id,
    v_referrer_slug,
    'pending'
  )
  on conflict (referred_user_id) do nothing
  returning id into v_referral_id;

  if v_referral_id is null then
    return jsonb_build_object('accepted', false, 'reason', 'already_referred');
  end if;

  select u.email_confirmed_at
  into v_email_confirmed_at
  from auth.users u
  where u.id = v_referred_user_id;

  if v_email_confirmed_at is not null then
    perform driver.qualify_driver_referral(v_referred_user_id, 'email_confirmed');
  end if;

  return jsonb_build_object(
    'accepted', true,
    'status', case when v_email_confirmed_at is null then 'pending' else 'qualified' end,
    'referrer_user_id', v_referrer_user_id,
    'referral_id', v_referral_id,
    'reward_xp', 25
  );
end;
$$;

grant execute on function driver.accept_public_referral(text) to authenticated;

create or replace function driver.qualify_referral_on_email_confirm()
returns trigger
language plpgsql
security definer
set search_path = driver, auth, public
as $$
begin
  if new.email_confirmed_at is not null
    and old.email_confirmed_at is distinct from new.email_confirmed_at then
    perform driver.qualify_driver_referral(new.id, 'email_confirmed');
  end if;

  return new;
end;
$$;

drop trigger if exists driver_qualify_referral_on_email_confirm
  on auth.users;

create trigger driver_qualify_referral_on_email_confirm
  after update of email_confirmed_at on auth.users
  for each row
  execute function driver.qualify_referral_on_email_confirm();

create or replace function driver.qualify_referral_on_first_journey()
returns trigger
language plpgsql
security definer
set search_path = driver, auth, public
as $$
begin
  perform driver.qualify_driver_referral(new.user_id, 'first_journey');
  return new;
end;
$$;

drop trigger if exists driver_qualify_referral_on_first_journey
  on driver.journeys;

create trigger driver_qualify_referral_on_first_journey
  after insert on driver.journeys
  for each row
  execute function driver.qualify_referral_on_first_journey();

update driver.driver_referrals r
set
  status = 'qualified',
  qualified_at = coalesce(r.qualified_at, r.accepted_at, timezone('utc', now())),
  qualification_reason = coalesce(r.qualification_reason, 'legacy_backfill'),
  reward_awarded_at = coalesce(r.reward_awarded_at, r.accepted_at, timezone('utc', now()))
where r.status <> 'qualified'
  and (
    exists (
      select 1
      from auth.users u
      where u.id = r.referred_user_id
        and u.email_confirmed_at is not null
    )
    or exists (
      select 1
      from driver.journeys j
      where j.user_id = r.referred_user_id
    )
  );

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
      and r.status = 'qualified'
      and r.qualified_at >= date_trunc('week', timezone('utc', now()));
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
  where r.referrer_user_id = v_user_id
    and r.status = 'qualified';

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

create or replace function driver.get_referral_subscription_benefit()
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_premium_referrals integer := 0;
  v_free_months integer := 0;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  select count(*)::integer
  into v_premium_referrals
  from driver.driver_referrals r
  join driver.profiles p on p.id = r.referred_user_id
  where r.referrer_user_id = v_user_id
    and r.status = 'qualified'
    and p.plan_type in (
      'premium'::driver.plan_type,
      'developer'::driver.plan_type,
      'gift'::driver.plan_type,
      'lifetime'::driver.plan_type
    )
    and p.subscription_status in (
      'active'::driver.subscription_status,
      'gifted'::driver.subscription_status
    );

  v_free_months := v_premium_referrals / 5;

  return jsonb_build_object(
    'premium_referrals', v_premium_referrals,
    'free_months_earned', v_free_months,
    'until_next_free_month',
      case
        when v_premium_referrals = 0 then 5
        when v_premium_referrals % 5 = 0 then 5
        else 5 - (v_premium_referrals % 5)
      end,
    'rule', 'A cada 5 indicados Premium ativos e confirmados, o entregador ganha 1 mensalidade de beneficio.'
  );
end;
$$;

grant execute on function driver.get_referral_subscription_benefit()
  to authenticated;

create or replace function driver.get_referral_rewards()
returns table (
  referral_id uuid,
  referred_user_id uuid,
  referred_display_name text,
  referred_avatar_url text,
  reward_xp integer,
  accepted_at timestamptz
)
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  select
    r.id as referral_id,
    r.referred_user_id,
    coalesce(nullif(p.display_name, ''), nullif(p.full_name, ''), 'Motorista indicado') as referred_display_name,
    p.avatar_url as referred_avatar_url,
    r.reward_xp,
    coalesce(r.qualified_at, r.accepted_at) as accepted_at
  from driver.driver_referrals r
  left join driver.profiles p on p.id = r.referred_user_id
  where r.referrer_user_id = auth.uid()
    and r.status = 'qualified'
  order by coalesce(r.qualified_at, r.accepted_at) desc
  limit 50;
$$;

grant execute on function driver.get_referral_rewards() to authenticated;
