-- Omnya Driver
-- Explicit app-level TOTP MFA preference.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor before testing 2FA enforcement.

alter table driver.profiles
  add column if not exists totp_mfa_enabled boolean not null default false;

update driver.profiles
set totp_mfa_enabled = coalesce(totp_mfa_enabled, false)
where totp_mfa_enabled is null;
