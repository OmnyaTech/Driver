-- Omnya Driver
-- Disable global auth bootstrap to keep Driver profiles isolated.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/032_driver_profile_isolation.sql.

drop trigger if exists on_auth_user_created_driver_profile on auth.users;

comment on function driver.sync_profile_from_auth_user() is
  'Omnya Driver: kept for historical/manual compatibility only. The global auth trigger is disabled so Driver profiles are created explicitly by the Driver app login flow.';
