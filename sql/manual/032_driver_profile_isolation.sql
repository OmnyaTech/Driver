-- Omnya Driver
-- Profile isolation from shared auth.users.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after validating active Omnya Driver users.
--
-- Omnya products can share the same Supabase project/auth, but each product
-- must own its profile rows inside its own schema. This disables the global
-- auth.users bootstrap that copied every auth user into driver.profiles.

drop trigger if exists on_auth_user_created_driver_profile on auth.users;

comment on function driver.sync_profile_from_auth_user()
is 'Legacy bootstrap kept for manual compatibility. Do not attach this globally to auth.users; Omnya Driver profiles are created only by the Driver app flow.';

delete from driver.driver_progress dp
where exists (
  select 1
  from driver.profiles p
  where p.id = dp.user_id
    and p.onboarding_completed_at is null
    and not exists (select 1 from driver.journeys j where j.user_id = p.id)
    and not exists (select 1 from driver.vehicles v where v.user_id = p.id)
    and not exists (select 1 from driver.platforms pl where pl.user_id = p.id)
    and not exists (select 1 from driver.goals g where g.user_id = p.id)
    and not exists (select 1 from driver.trip_expenses te where te.user_id = p.id)
    and not exists (select 1 from driver.fuelings f where f.user_id = p.id)
    and not exists (select 1 from driver.maintenances m where m.user_id = p.id)
    and not exists (select 1 from driver.subscriptions s where s.user_id = p.id)
);

delete from driver.profiles p
where p.onboarding_completed_at is null
  and not exists (select 1 from driver.journeys j where j.user_id = p.id)
  and not exists (select 1 from driver.vehicles v where v.user_id = p.id)
  and not exists (select 1 from driver.platforms pl where pl.user_id = p.id)
  and not exists (select 1 from driver.goals g where g.user_id = p.id)
  and not exists (select 1 from driver.trip_expenses te where te.user_id = p.id)
  and not exists (select 1 from driver.fuelings f where f.user_id = p.id)
  and not exists (select 1 from driver.maintenances m where m.user_id = p.id)
  and not exists (select 1 from driver.subscriptions s where s.user_id = p.id);
