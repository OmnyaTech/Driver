-- Omnya Driver
-- Gamification, public profile and ranking preparation.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

alter table driver.profiles
  add column if not exists public_profile_enabled boolean not null default false,
  add column if not exists public_slug text,
  add column if not exists public_bio text,
  add column if not exists public_city text;

create unique index if not exists idx_driver_profiles_public_slug_unique
  on driver.profiles (lower(public_slug))
  where public_slug is not null;

create table if not exists driver.driver_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  xp integer not null default 0,
  level integer not null default 1,
  level_title text not null default 'Motorista iniciante',
  current_streak_days integer not null default 0,
  best_streak_days integer not null default 0,
  medals_count integer not null default 0,
  public_score integer not null default 0,
  ranking_opt_in boolean not null default false,
  last_calculated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.driver_medal_unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medal_key text not null,
  medal_name text not null,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  awarded_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, medal_key)
);

create index if not exists idx_driver_progress_public_score
  on driver.driver_progress (ranking_opt_in, public_score desc, xp desc);

create index if not exists idx_driver_medal_unlocks_user_id_awarded_at
  on driver.driver_medal_unlocks (user_id, awarded_at desc);

alter table driver.driver_progress enable row level security;
alter table driver.driver_medal_unlocks enable row level security;

grant select, insert, update on driver.driver_progress to authenticated;
grant select on driver.driver_medal_unlocks to authenticated;

drop policy if exists "driver_progress_own_all" on driver.driver_progress;
create policy "driver_progress_own_all"
  on driver.driver_progress
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_medal_unlocks_own_select" on driver.driver_medal_unlocks;
create policy "driver_medal_unlocks_own_select"
  on driver.driver_medal_unlocks
  for select
  to authenticated
  using (auth.uid() = user_id);

insert into driver.driver_progress (user_id)
select p.id
from driver.profiles p
left join driver.driver_progress dp on dp.user_id = p.id
where dp.user_id is null
on conflict (user_id) do nothing;

create or replace function driver.get_level_from_xp(p_xp integer)
returns table (
  level integer,
  level_title text,
  next_level_xp integer
)
language sql
immutable
set search_path = driver, auth, public
as $$
  with value as (
    select greatest(coalesce(p_xp, 0), 0) as xp_value
  )
  select
    case
      when xp_value >= 3500 then 8
      when xp_value >= 2600 then 7
      when xp_value >= 1900 then 6
      when xp_value >= 1350 then 5
      when xp_value >= 900 then 4
      when xp_value >= 550 then 3
      when xp_value >= 250 then 2
      else 1
    end as level,
    case
      when xp_value >= 3500 then 'Lenda da pista'
      when xp_value >= 2600 then 'Comandante da cidade'
      when xp_value >= 1900 then 'Motorista de elite'
      when xp_value >= 1350 then 'Motorista estrategista'
      when xp_value >= 900 then 'Motorista de ritmo forte'
      when xp_value >= 550 then 'Motorista consistente'
      when xp_value >= 250 then 'Motorista em ascensao'
      else 'Motorista iniciante'
    end as level_title,
    case
      when xp_value >= 3500 then null
      when xp_value >= 2600 then 3500
      when xp_value >= 1900 then 2600
      when xp_value >= 1350 then 1900
      when xp_value >= 900 then 1350
      when xp_value >= 550 then 900
      when xp_value >= 250 then 550
      else 250
    end as next_level_xp
  from value;
$$;

grant execute on function driver.get_level_from_xp(integer) to authenticated;

create or replace function driver.get_driver_streaks(p_user_id uuid default auth.uid())
returns table (
  current_streak_days integer,
  best_streak_days integer
)
language sql
stable
set search_path = driver, auth, public
as $$
  with active_days as (
    select distinct (j.started_at at time zone 'utc')::date as active_day
    from driver.journeys j
    where j.user_id = p_user_id
  ),
  ordered_days as (
    select
      active_day,
      active_day - (row_number() over (order by active_day))::integer as streak_group
    from active_days
  ),
  streaks as (
    select
      min(active_day) as start_day,
      max(active_day) as end_day,
      count(*)::integer as streak_days
    from ordered_days
    group by streak_group
  ),
  latest_day as (
    select max(active_day) as value
    from active_days
  )
  select
    coalesce(
      max(s.streak_days) filter (
        where ld.value is not null
          and ld.value >= ((timezone('utc', now()))::date - 1)
          and s.end_day = ld.value
      ),
      0
    )::integer as current_streak_days,
    coalesce(max(s.streak_days), 0)::integer as best_streak_days
  from latest_day ld
  left join streaks s on true;
$$;

grant execute on function driver.get_driver_streaks(uuid) to authenticated;

create or replace function driver.get_driver_records(p_user_id uuid default auth.uid())
returns jsonb
language sql
stable
set search_path = driver, auth, public
as $$
  with daily_income as (
    select
      (j.started_at at time zone 'utc')::date as activity_date,
      extract(dow from j.started_at at time zone 'utc')::integer as weekday_index,
      coalesce(sum(jp.income), 0)::numeric as total_income
    from driver.journeys j
    left join driver.journey_platforms jp on jp.journey_id = j.id
    where j.user_id = p_user_id
    group by 1, 2
  ),
  journey_trip_expenses as (
    select
      te.journey_id,
      coalesce(sum(te.amount), 0)::numeric as total_amount
    from driver.trip_expenses te
    where te.user_id = p_user_id
      and te.journey_id is not null
    group by te.journey_id
  ),
  journey_fuelings as (
    select
      f.journey_id,
      coalesce(sum(f.total_amount), 0)::numeric as total_amount
    from driver.fuelings f
    where f.user_id = p_user_id
      and f.journey_id is not null
    group by f.journey_id
  ),
  hourly_profit as (
    select
      j.id as journey_id,
      j.started_at,
      case
        when j.ended_at is null or j.ended_at <= j.started_at then null
        else (
          (
            coalesce(sum(jp.income), 0)
            - coalesce(jte.total_amount, 0)
            - coalesce(jf.total_amount, 0)
          )::numeric
          / greatest(extract(epoch from (j.ended_at - j.started_at)) / 3600.0, 0.01)
        )::numeric
      end as profit_per_hour
    from driver.journeys j
    left join driver.journey_platforms jp on jp.journey_id = j.id
    left join journey_trip_expenses jte on jte.journey_id = j.id
    left join journey_fuelings jf on jf.journey_id = j.id
    where j.user_id = p_user_id
    group by j.id, j.started_at, j.ended_at, jte.total_amount, jf.total_amount
  ),
  daily_deliveries as (
    select
      (j.started_at at time zone 'utc')::date as activity_date,
      coalesce(sum(jp.deliveries), 0)::integer as total_deliveries
    from driver.journeys j
    left join driver.journey_platforms jp on jp.journey_id = j.id
    where j.user_id = p_user_id
    group by 1
  ),
  streaks as (
    select *
    from driver.get_driver_streaks(p_user_id)
  )
  select jsonb_build_object(
    'best_friday',
    (
      select jsonb_build_object(
        'date', activity_date,
        'income', total_income
      )
      from daily_income
      where weekday_index = 5
      order by total_income desc, activity_date desc
      limit 1
    ),
    'highest_revenue_day',
    (
      select jsonb_build_object(
        'date', activity_date,
        'income', total_income
      )
      from daily_income
      order by total_income desc, activity_date desc
      limit 1
    ),
    'highest_profit_per_hour',
    (
      select jsonb_build_object(
        'journey_id', journey_id,
        'started_at', started_at,
        'profit_per_hour', profit_per_hour
      )
      from hourly_profit
      where profit_per_hour is not null
      order by profit_per_hour desc, started_at desc
      limit 1
    ),
    'highest_deliveries_day',
    (
      select jsonb_build_object(
        'date', activity_date,
        'deliveries', total_deliveries
      )
      from daily_deliveries
      order by total_deliveries desc, activity_date desc
      limit 1
    ),
    'streak',
    (
      select jsonb_build_object(
        'current_days', current_streak_days,
        'best_days', best_streak_days
      )
      from streaks
      limit 1
    )
  );
$$;

grant execute on function driver.get_driver_records(uuid) to authenticated;

create or replace function driver.refresh_driver_progress(p_user_id uuid default auth.uid())
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_total_journeys integer := 0;
  v_completed_journeys integer := 0;
  v_total_deliveries integer := 0;
  v_total_distance_km numeric := 0;
  v_completed_goals integer := 0;
  v_active_platforms integer := 0;
  v_best_daily_income numeric := 0;
  v_best_friday_income numeric := 0;
  v_best_profit_per_hour numeric := 0;
  v_current_streak integer := 0;
  v_best_streak integer := 0;
  v_medals_count integer := 0;
  v_xp integer := 0;
  v_level integer := 1;
  v_level_title text := 'Motorista iniciante';
  v_next_level_xp integer;
  v_records jsonb := '{}'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if v_user_id is distinct from auth.uid() and not driver.is_requester_developer() then
    raise exception 'Nao autorizado para recalcular progresso de outro usuario.'
      using errcode = '42501';
  end if;

  insert into driver.driver_progress (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select
    coalesce(journey_stats.total_journeys, 0),
    coalesce(journey_stats.completed_journeys, 0),
    coalesce(delivery_stats.total_deliveries, 0),
    coalesce(journey_stats.total_distance_km, 0)
  into
    v_total_journeys,
    v_completed_journeys,
    v_total_deliveries,
    v_total_distance_km
  from (
    select
      count(*)::integer as total_journeys,
      count(*) filter (where j.ended_at is not null)::integer as completed_journeys,
      coalesce(sum(
        case
          when j.odometer_start is not null
            and j.odometer_end is not null
            and j.odometer_end >= j.odometer_start
          then j.odometer_end - j.odometer_start
          else 0
        end
      ), 0)::numeric as total_distance_km
    from driver.journeys j
    where j.user_id = v_user_id
  ) journey_stats
  cross join (
    select coalesce(sum(jp.deliveries), 0)::integer as total_deliveries
    from driver.journey_platforms jp
    join driver.journeys j on j.id = jp.journey_id
    where j.user_id = v_user_id
  ) delivery_stats;

  select count(*)::integer
  into v_completed_goals
  from driver.goals g
  where g.user_id = v_user_id
    and g.target_amount > 0
    and coalesce(g.current_amount, 0) >= g.target_amount;

  select count(*)::integer
  into v_active_platforms
  from driver.platforms p
  where p.user_id = v_user_id
    and p.active = true;

  v_records := coalesce(driver.get_driver_records(v_user_id), '{}'::jsonb);

  select coalesce((v_records->'highest_revenue_day'->>'income')::numeric, 0)
  into v_best_daily_income;

  select coalesce((v_records->'highest_profit_per_hour'->>'profit_per_hour')::numeric, 0)
  into v_best_profit_per_hour;

  select coalesce((v_records->'best_friday'->>'income')::numeric, 0)
  into v_best_friday_income;

  select
    current_streak_days,
    best_streak_days
  into
    v_current_streak,
    v_best_streak
  from driver.get_driver_streaks(v_user_id);

  with candidate_medals as (
    select *
    from (
      values
        (
          'first_journey',
          'Primeira partida',
          'Registrou a primeira jornada.',
          v_total_journeys >= 1,
          jsonb_build_object('total_journeys', v_total_journeys)
        ),
        (
          'journey_10',
          'Ritmo de trabalho',
          'Concluiu pelo menos 10 jornadas.',
          v_completed_journeys >= 10,
          jsonb_build_object('completed_journeys', v_completed_journeys)
        ),
        (
          'deliveries_100',
          'Centena de entregas',
          'Alcancou 100 entregas registradas.',
          v_total_deliveries >= 100,
          jsonb_build_object('total_deliveries', v_total_deliveries)
        ),
        (
          'distance_1000',
          'Asfalto rodado',
          'Superou 1000 km registrados.',
          v_total_distance_km >= 1000,
          jsonb_build_object('total_distance_km', v_total_distance_km)
        ),
        (
          'streak_7',
          'Foco da semana',
          'Manteve uma sequencia de 7 dias ativos.',
          v_best_streak >= 7,
          jsonb_build_object('best_streak_days', v_best_streak)
        ),
        (
          'goal_completed',
          'Meta concluida',
          'Finalizou pelo menos um objetivo financeiro.',
          v_completed_goals >= 1,
          jsonb_build_object('completed_goals', v_completed_goals)
        ),
        (
          'friday_star',
          'Sexta dourada',
          'Registrou uma sexta-feira com faturamento positivo.',
          v_best_friday_income > 0,
          jsonb_build_object('best_friday_income', v_best_friday_income)
        ),
        (
          'revenue_peak',
          'Pico de faturamento',
          'Registrou pelo menos um dia com faturamento positivo.',
          v_best_daily_income > 0,
          jsonb_build_object('best_daily_income', v_best_daily_income)
        ),
        (
          'multi_platform',
          'Operacao versatil',
          'Manteve tres ou mais plataformas ativas.',
          v_active_platforms >= 3,
          jsonb_build_object('active_platforms', v_active_platforms)
        ),
        (
          'profit_hunter',
          'Lucro por hora',
          'Registrou pelo menos uma jornada com lucro por hora positivo.',
          v_best_profit_per_hour > 0,
          jsonb_build_object('best_profit_per_hour', v_best_profit_per_hour)
        )
    ) as medals(medal_key, medal_name, description, achieved, metadata)
    where achieved
  )
  insert into driver.driver_medal_unlocks (
    user_id,
    medal_key,
    medal_name,
    description,
    metadata
  )
  select
    v_user_id,
    medal_key,
    medal_name,
    description,
    metadata
  from candidate_medals
  on conflict (user_id, medal_key) do nothing;

  select count(*)::integer
  into v_medals_count
  from driver.driver_medal_unlocks m
  where m.user_id = v_user_id;

  v_xp :=
      (v_completed_journeys * 20)
    + (v_total_deliveries * 2)
    + floor(coalesce(v_total_distance_km, 0) / 25)::integer * 3
    + (v_completed_goals * 50)
    + (v_medals_count * 25)
    + (greatest(v_best_streak - 1, 0) * 5);

  select
    level,
    level_title,
    next_level_xp
  into
    v_level,
    v_level_title,
    v_next_level_xp
  from driver.get_level_from_xp(v_xp);

  update driver.driver_progress
  set
    xp = v_xp,
    level = v_level,
    level_title = v_level_title,
    current_streak_days = v_current_streak,
    best_streak_days = v_best_streak,
    medals_count = v_medals_count,
    public_score = v_xp + (v_medals_count * 10) + (v_best_streak * 3),
    last_calculated_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where user_id = v_user_id;

  return jsonb_build_object(
    'user_id', v_user_id,
    'xp', v_xp,
    'level', v_level,
    'level_title', v_level_title,
    'next_level_xp', v_next_level_xp,
    'current_streak_days', v_current_streak,
    'best_streak_days', v_best_streak,
    'medals_count', v_medals_count,
    'public_score', v_xp + (v_medals_count * 10) + (v_best_streak * 3)
  );
end;
$$;

grant execute on function driver.refresh_driver_progress(uuid) to authenticated;

create or replace function driver.get_driver_gamification_summary()
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_progress driver.driver_progress%rowtype;
  v_next_level_xp integer;
  v_records jsonb;
  v_medals jsonb;
begin
  perform driver.refresh_driver_progress(auth.uid());

  select *
  into v_progress
  from driver.driver_progress dp
  where dp.user_id = auth.uid()
  limit 1;

  select next_level_xp
  into v_next_level_xp
  from driver.get_level_from_xp(v_progress.xp);

  v_records := driver.get_driver_records(auth.uid());

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'key', m.medal_key,
        'name', m.medal_name,
        'description', m.description,
        'awarded_at', m.awarded_at,
        'metadata', m.metadata
      )
      order by m.awarded_at desc
    ),
    '[]'::jsonb
  )
  into v_medals
  from driver.driver_medal_unlocks m
  where m.user_id = auth.uid();

  return jsonb_build_object(
    'xp', v_progress.xp,
    'level', v_progress.level,
    'level_title', v_progress.level_title,
    'next_level_xp', v_next_level_xp,
    'current_streak_days', v_progress.current_streak_days,
    'best_streak_days', v_progress.best_streak_days,
    'medals_count', v_progress.medals_count,
    'ranking_opt_in', v_progress.ranking_opt_in,
    'public_score', v_progress.public_score,
    'records', coalesce(v_records, '{}'::jsonb),
    'medals', v_medals
  );
end;
$$;

grant execute on function driver.get_driver_gamification_summary() to authenticated;

create or replace function driver.get_public_driver_profile(p_slug text)
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
begin
  select
    p.id,
    p.display_name,
    p.avatar_url,
    p.public_slug,
    p.public_bio,
    p.public_city,
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

  return jsonb_build_object(
    'display_name', v_profile.display_name,
    'avatar_url', v_profile.avatar_url,
    'public_slug', v_profile.public_slug,
    'public_bio', v_profile.public_bio,
    'public_city', v_profile.public_city,
    'level', v_progress.level,
    'level_title', v_progress.level_title,
    'xp', v_progress.xp,
    'medals_count', v_progress.medals_count,
    'current_streak_days', v_progress.current_streak_days,
    'best_streak_days', v_progress.best_streak_days,
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

grant execute on function driver.get_public_driver_profile(text) to authenticated;

create or replace function driver.get_public_ranking_preview(p_limit integer default 50)
returns table (
  rank_position bigint,
  public_slug text,
  display_name text,
  avatar_url text,
  level integer,
  level_title text,
  medals_count integer,
  public_score integer,
  best_streak_days integer
)
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  with ranked as (
    select
      row_number() over (
        order by dp.public_score desc, dp.xp desc, dp.best_streak_days desc, p.display_name asc
      ) as rank_position,
      p.public_slug,
      p.display_name,
      p.avatar_url,
      dp.level,
      dp.level_title,
      dp.medals_count,
      dp.public_score,
      dp.best_streak_days
    from driver.profiles p
    join driver.driver_progress dp on dp.user_id = p.id
    where p.public_profile_enabled = true
      and p.public_slug is not null
      and dp.ranking_opt_in = true
  )
  select *
  from ranked
  order by rank_position
  limit greatest(coalesce(p_limit, 50), 1);
$$;

grant execute on function driver.get_public_ranking_preview(integer) to authenticated;
