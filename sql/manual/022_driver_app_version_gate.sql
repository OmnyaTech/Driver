-- Omnya Driver
-- App version gate rules.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor before testing forced updates.
-- Any enabled rule with latest_build_number greater than the installed build
-- gives the user grace_period_days to update before blocking access.

create table if not exists driver.app_version_rules (
  platform text primary key,
  minimum_build_number integer not null default 1,
  latest_build_number integer not null default 1,
  latest_version text not null default '1.0.0',
  update_url text,
  grace_period_days integer not null default 7,
  enforcement_started_at timestamptz not null default timezone('utc', now()),
  enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table driver.app_version_rules
  alter column grace_period_days set default 7;

alter table driver.app_version_rules enable row level security;

grant select on driver.app_version_rules to anon, authenticated;

drop policy if exists "driver_app_version_rules_public_select"
  on driver.app_version_rules;
create policy "driver_app_version_rules_public_select"
  on driver.app_version_rules
  for select
  to anon, authenticated
  using (enabled = true);

insert into driver.app_version_rules (
  platform,
  minimum_build_number,
  latest_build_number,
  latest_version,
  update_url
)
values
  ('android', 1, 1, '1.0.0', null),
  ('ios', 1, 1, '1.0.0', null),
  ('web', 1, 1, '1.0.0', null)
on conflict (platform) do nothing;

update driver.app_version_rules
set
  grace_period_days = 7,
  updated_at = timezone('utc', now())
where grace_period_days is distinct from 7;
