-- Omnya Driver
-- Automatic bootstrap of driver.profiles from auth.users.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create schema if not exists driver;

create or replace function driver.sync_profile_from_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth, driver
as $$
declare
  metadata jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  full_name text := nullif(trim(coalesce(metadata->>'full_name', metadata->>'name', '')), '');
  display_name text := nullif(trim(split_part(coalesce(metadata->>'full_name', metadata->>'name', new.email, 'Motorista'), ' ', 1)), '');
begin
  insert into driver.profiles (
    id,
    email,
    full_name,
    display_name,
    avatar_url,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.email,
    full_name,
    coalesce(display_name, 'Motorista'),
    metadata->>'avatar_url',
    timezone('utc', now()),
    timezone('utc', now())
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, driver.profiles.full_name),
    display_name = coalesce(excluded.display_name, driver.profiles.display_name, 'Motorista'),
    avatar_url = coalesce(excluded.avatar_url, driver.profiles.avatar_url),
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_driver_profile on auth.users;

create trigger on_auth_user_created_driver_profile
after insert on auth.users
for each row
execute function driver.sync_profile_from_auth_user();

comment on function driver.sync_profile_from_auth_user()
is 'Bootstrap automatico do perfil do Omnya Driver a partir de auth.users.';

insert into driver.profiles (
  id,
  email,
  full_name,
  display_name,
  avatar_url,
  created_at,
  updated_at
)
select
  u.id,
  u.email,
  nullif(trim(coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', '')), '') as full_name,
  coalesce(
    nullif(trim(split_part(coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', u.email, 'Motorista'), ' ', 1)), ''),
    'Motorista'
  ) as display_name,
  u.raw_user_meta_data->>'avatar_url' as avatar_url,
  timezone('utc', now()),
  timezone('utc', now())
from auth.users u
left join driver.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;
