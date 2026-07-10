-- Omnya Driver
-- Foundation schema for manual execution in Supabase SQL Editor.
-- Date: 2026-07-09
-- Rule: creates only objects inside schema driver.

create schema if not exists driver;

create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'user_role'
  ) then
    create type driver.user_role as enum ('user', 'developer');
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'plan_type'
  ) then
    create type driver.plan_type as enum (
      'free',
      'premium',
      'gift',
      'lifetime',
      'developer'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'subscription_status'
  ) then
    create type driver.subscription_status as enum (
      'inactive',
      'active',
      'cancelled',
      'expired',
      'overdue',
      'gifted'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'journey_mode'
  ) then
    create type driver.journey_mode as enum ('manual', 'quick', 'automatic');
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'platform_type'
  ) then
    create type driver.platform_type as enum (
      'platform',
      'restaurant',
      'market',
      'other'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'driver' and t.typname = 'expense_type'
  ) then
    create type driver.expense_type as enum (
      'toll',
      'parking',
      'fuel',
      'maintenance',
      'other'
    );
  end if;
end $$;

create table if not exists driver.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  display_name text,
  phone text,
  avatar_url text,
  role driver.user_role not null default 'user',
  plan_type driver.plan_type not null default 'free',
  subscription_status driver.subscription_status not null default 'inactive',
  subscription_expires_at timestamptz,
  current_period_end timestamptz,
  gifted_by uuid references auth.users(id) on delete set null,
  gifted_at timestamptz,
  asaas_customer_id text,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  brand text not null,
  model text not null,
  model_year integer,
  plate text,
  fuel_type text,
  average_consumption numeric(10,2),
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.platforms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type driver.platform_type not null default 'platform',
  average_income numeric(12,2),
  average_deliveries integer,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.journeys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid references driver.vehicles(id) on delete set null,
  mode driver.journey_mode not null default 'manual',
  started_at timestamptz not null,
  ended_at timestamptz,
  odometer_start numeric(12,2),
  odometer_end numeric(12,2),
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.journey_platforms (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references driver.journeys(id) on delete cascade,
  platform_id uuid references driver.platforms(id) on delete set null,
  deliveries integer not null default 0,
  income numeric(12,2) not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.trip_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  journey_id uuid references driver.journeys(id) on delete set null,
  type driver.expense_type not null,
  description text,
  amount numeric(12,2) not null,
  occurred_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.fuelings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references driver.vehicles(id) on delete cascade,
  journey_id uuid references driver.journeys(id) on delete set null,
  fueled_at timestamptz not null,
  odometer numeric(12,2),
  station_name text,
  fuel_type text,
  liters numeric(12,3) not null,
  price_per_liter numeric(12,3) not null,
  total_amount numeric(12,2) not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.maintenances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references driver.vehicles(id) on delete cascade,
  maintenance_date date not null,
  workshop text,
  reason text,
  description text,
  total_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.maintenance_items (
  id uuid primary key default gen_random_uuid(),
  maintenance_id uuid not null references driver.maintenances(id) on delete cascade,
  description text not null,
  amount numeric(12,2) not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  icon text,
  target_amount numeric(12,2) not null,
  current_amount numeric(12,2) not null default 0,
  deadline date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.goal_transactions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references driver.goals(id) on delete cascade,
  journey_id uuid references driver.journeys(id) on delete set null,
  amount numeric(12,2) not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_type driver.plan_type not null,
  status driver.subscription_status not null,
  provider text default 'asaas',
  provider_customer_id text,
  provider_subscription_id text,
  started_at timestamptz,
  expires_at timestamptz,
  cancelled_at timestamptz,
  gifted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_driver_profiles_plan_type
  on driver.profiles (plan_type);

create index if not exists idx_driver_vehicles_user_id
  on driver.vehicles (user_id);

create index if not exists idx_driver_platforms_user_id
  on driver.platforms (user_id);

create index if not exists idx_driver_journeys_user_id_started_at
  on driver.journeys (user_id, started_at desc);

create index if not exists idx_driver_trip_expenses_user_id_occurred_at
  on driver.trip_expenses (user_id, occurred_at desc);

create index if not exists idx_driver_fuelings_user_id_fueled_at
  on driver.fuelings (user_id, fueled_at desc);

create index if not exists idx_driver_maintenances_user_id_maintenance_date
  on driver.maintenances (user_id, maintenance_date desc);

create index if not exists idx_driver_goals_user_id
  on driver.goals (user_id);

create index if not exists idx_driver_subscriptions_user_id
  on driver.subscriptions (user_id);

alter table driver.profiles enable row level security;
alter table driver.vehicles enable row level security;
alter table driver.platforms enable row level security;
alter table driver.journeys enable row level security;
alter table driver.journey_platforms enable row level security;
alter table driver.trip_expenses enable row level security;
alter table driver.fuelings enable row level security;
alter table driver.maintenances enable row level security;
alter table driver.maintenance_items enable row level security;
alter table driver.goals enable row level security;
alter table driver.goal_transactions enable row level security;
alter table driver.subscriptions enable row level security;

grant usage on schema driver to authenticated;

grant select, insert, update on
  driver.profiles,
  driver.vehicles,
  driver.platforms,
  driver.journeys,
  driver.journey_platforms,
  driver.trip_expenses,
  driver.fuelings,
  driver.maintenances,
  driver.maintenance_items,
  driver.goals,
  driver.goal_transactions,
  driver.subscriptions
to authenticated;

drop policy if exists "driver_profiles_select_own" on driver.profiles;
create policy "driver_profiles_select_own"
  on driver.profiles
  for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "driver_profiles_update_own" on driver.profiles;
create policy "driver_profiles_update_own"
  on driver.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "driver_profiles_insert_own" on driver.profiles;
create policy "driver_profiles_insert_own"
  on driver.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "driver_vehicles_own_all" on driver.vehicles;
create policy "driver_vehicles_own_all"
  on driver.vehicles
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_platforms_own_all" on driver.platforms;
create policy "driver_platforms_own_all"
  on driver.platforms
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_journeys_own_all" on driver.journeys;
create policy "driver_journeys_own_all"
  on driver.journeys
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_trip_expenses_own_all" on driver.trip_expenses;
create policy "driver_trip_expenses_own_all"
  on driver.trip_expenses
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_fuelings_own_all" on driver.fuelings;
create policy "driver_fuelings_own_all"
  on driver.fuelings
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_maintenances_own_all" on driver.maintenances;
create policy "driver_maintenances_own_all"
  on driver.maintenances
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_goals_own_all" on driver.goals;
create policy "driver_goals_own_all"
  on driver.goals
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "driver_subscriptions_own_select" on driver.subscriptions;
create policy "driver_subscriptions_own_select"
  on driver.subscriptions
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "driver_journey_platforms_by_journey_owner" on driver.journey_platforms;
create policy "driver_journey_platforms_by_journey_owner"
  on driver.journey_platforms
  for all
  to authenticated
  using (
    exists (
      select 1
      from driver.journeys j
      where j.id = journey_id
        and j.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from driver.journeys j
      where j.id = journey_id
        and j.user_id = auth.uid()
    )
  );

drop policy if exists "driver_maintenance_items_by_maintenance_owner" on driver.maintenance_items;
create policy "driver_maintenance_items_by_maintenance_owner"
  on driver.maintenance_items
  for all
  to authenticated
  using (
    exists (
      select 1
      from driver.maintenances m
      where m.id = maintenance_id
        and m.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from driver.maintenances m
      where m.id = maintenance_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "driver_goal_transactions_by_goal_owner" on driver.goal_transactions;
create policy "driver_goal_transactions_by_goal_owner"
  on driver.goal_transactions
  for all
  to authenticated
  using (
    exists (
      select 1
      from driver.goals g
      where g.id = goal_id
        and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from driver.goals g
      where g.id = goal_id
        and g.user_id = auth.uid()
    )
  );
