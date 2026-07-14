-- Omnya Driver
-- Scope native Supabase TOTP MFA to the Driver app without deleting global factors.
-- Date: 2026-07-14
-- Execute manually in Supabase SQL Editor after sql/manual/039_driver_reset_own_totp_mfa_factors.sql.

alter table driver.profiles
  add column if not exists totp_mfa_factor_id text;

comment on column driver.profiles.totp_mfa_factor_id is
  'Supabase auth.mfa_factors.id owned by Driver. Native MFA factors are project-global, so Driver must only enforce the factor linked here.';

create or replace function driver.reset_own_totp_mfa_factors()
returns integer
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.profiles
  set
    totp_mfa_enabled = false,
    totp_mfa_factor_id = null,
    updated_at = timezone('utc', now())
  where id = v_user_id;

  return 0;
end;
$$;

grant execute on function driver.reset_own_totp_mfa_factors() to authenticated;
