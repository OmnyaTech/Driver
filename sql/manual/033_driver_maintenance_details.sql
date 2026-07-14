-- Omnya Driver
-- Maintenance details expansion.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor before testing maintenance form updates.

alter table driver.maintenances
  add column if not exists maintenance_at timestamptz,
  add column if not exists payment_method text,
  add column if not exists current_odometer numeric(10,2),
  add column if not exists next_maintenance_odometer numeric(10,2);

update driver.maintenances
set maintenance_at = coalesce(maintenance_at, maintenance_date::timestamptz)
where maintenance_at is null
  and maintenance_date is not null;

create index if not exists idx_driver_maintenances_user_maintenance_at
  on driver.maintenances (user_id, maintenance_at desc);
