-- Omnya Driver
-- API grants for custom schema exposure support.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

grant usage on schema driver to anon, authenticated, service_role;

grant select on all tables in schema driver to anon, authenticated;
grant insert, update, delete on all tables in schema driver to authenticated;
grant execute on all routines in schema driver to anon, authenticated;
grant usage, select on all sequences in schema driver to anon, authenticated;

grant all privileges on all tables in schema driver to service_role;
grant all privileges on all routines in schema driver to service_role;
grant all privileges on all sequences in schema driver to service_role;

alter default privileges for role postgres in schema driver
  grant select on tables to anon, authenticated;

alter default privileges for role postgres in schema driver
  grant insert, update, delete on tables to authenticated;

alter default privileges for role postgres in schema driver
  grant execute on routines to anon, authenticated;

alter default privileges for role postgres in schema driver
  grant usage, select on sequences to anon, authenticated;

alter default privileges for role postgres in schema driver
  grant all privileges on tables to service_role;

alter default privileges for role postgres in schema driver
  grant all privileges on routines to service_role;

alter default privileges for role postgres in schema driver
  grant all privileges on sequences to service_role;
