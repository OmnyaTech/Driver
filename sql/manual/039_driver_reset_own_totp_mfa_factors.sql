-- Omnya Driver
-- Self-service cleanup for stale TOTP MFA factors.
-- Date: 2026-07-14
-- Execute manually in Supabase SQL Editor after sql/manual/038_driver_more_gamification_missions.sql.

create or replace function driver.reset_own_totp_mfa_factors()
returns integer
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_removed integer := 0;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  delete from auth.mfa_factors
  where user_id = v_user_id
    and factor_type = 'totp';

  get diagnostics v_removed = row_count;

  update driver.profiles
  set
    totp_mfa_enabled = false,
    updated_at = timezone('utc', now())
  where id = v_user_id;

  return v_removed;
end;
$$;

grant execute on function driver.reset_own_totp_mfa_factors() to authenticated;
