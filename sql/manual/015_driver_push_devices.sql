-- Omnya Driver
-- Push notification device registry.
-- Date: 2026-07-11
-- Execute manually in Supabase SQL Editor after Firebase setup is planned.

create table if not exists driver.driver_push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  platform text not null default 'unknown',
  fcm_token text,
  apns_token text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, device_id)
);

create index if not exists idx_driver_push_devices_user_enabled
  on driver.driver_push_devices (user_id, enabled, last_seen_at desc);

alter table driver.driver_push_devices enable row level security;

grant select, insert, update, delete on driver.driver_push_devices to authenticated;

drop policy if exists "driver_push_devices_own_all" on driver.driver_push_devices;
create policy "driver_push_devices_own_all"
  on driver.driver_push_devices
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
