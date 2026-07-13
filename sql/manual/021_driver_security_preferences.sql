-- Omnya Driver
-- Security preferences for device lock and inactivity protection.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor before testing app lock settings.

alter table driver.profiles
  add column if not exists biometric_lock_enabled boolean not null default false,
  add column if not exists inactivity_lock_minutes integer not null default 15,
  add column if not exists reauth_on_resume boolean not null default true;

update driver.profiles
set
  biometric_lock_enabled = coalesce(biometric_lock_enabled, false),
  inactivity_lock_minutes = greatest(coalesce(inactivity_lock_minutes, 15), 1),
  reauth_on_resume = coalesce(reauth_on_resume, true)
where biometric_lock_enabled is null
   or inactivity_lock_minutes is null
   or inactivity_lock_minutes < 1
   or reauth_on_resume is null;
