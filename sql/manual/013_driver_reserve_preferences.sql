-- Omnya Driver
-- Reserve preference fields per driver profile.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

alter table driver.profiles
  add column if not exists reserve_mode text not null default 'daily_percent',
  add column if not exists reserve_percentage numeric(5,2) not null default 30,
  add column if not exists reserve_amount_per_delivery numeric(10,2) not null default 0;

update driver.profiles
set
  reserve_mode = coalesce(nullif(reserve_mode, ''), 'daily_percent'),
  reserve_percentage = coalesce(reserve_percentage, 30),
  reserve_amount_per_delivery = coalesce(reserve_amount_per_delivery, 0)
where reserve_mode is null
   or reserve_mode = ''
   or reserve_percentage is null
   or reserve_amount_per_delivery is null;
