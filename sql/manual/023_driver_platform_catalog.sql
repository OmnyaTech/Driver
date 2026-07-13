-- Omnya Driver
-- Shared platform/place catalog for smart logo reuse by region.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor before testing smart platform logos.

create table if not exists driver.platform_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'platform',
  city text,
  state text,
  country text not null default 'Brasil',
  logo_url text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists idx_driver_platform_catalog_region_unique
  on driver.platform_catalog (
    lower(name),
    lower(type),
    lower(coalesce(city, '')),
    lower(coalesce(state, '')),
    lower(coalesce(country, 'Brasil'))
  );

alter table driver.platform_catalog enable row level security;

grant select, insert, update on driver.platform_catalog to authenticated;

drop policy if exists "driver_platform_catalog_authenticated_select"
  on driver.platform_catalog;
create policy "driver_platform_catalog_authenticated_select"
  on driver.platform_catalog
  for select
  to authenticated
  using (true);

drop policy if exists "driver_platform_catalog_authenticated_insert"
  on driver.platform_catalog;
create policy "driver_platform_catalog_authenticated_insert"
  on driver.platform_catalog
  for insert
  to authenticated
  with check (auth.uid() = created_by);

drop policy if exists "driver_platform_catalog_creator_update"
  on driver.platform_catalog;
create policy "driver_platform_catalog_creator_update"
  on driver.platform_catalog
  for update
  to authenticated
  using (auth.uid() = created_by or driver.is_requester_developer())
  with check (auth.uid() = created_by or driver.is_requester_developer());

create or replace function driver.upsert_platform_catalog_entry(
  p_name text,
  p_type text,
  p_city text default null,
  p_state text default null,
  p_country text default 'Brasil',
  p_logo_url text default null
)
returns uuid
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_id uuid;
  v_name text := trim(coalesce(p_name, ''));
  v_type text := coalesce(nullif(trim(coalesce(p_type, '')), ''), 'platform');
  v_city text := nullif(trim(coalesce(p_city, '')), '');
  v_state text := nullif(trim(coalesce(p_state, '')), '');
  v_country text := coalesce(nullif(trim(coalesce(p_country, '')), ''), 'Brasil');
  v_logo_url text := nullif(trim(coalesce(p_logo_url, '')), '');
begin
  if auth.uid() is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if v_name = '' then
    raise exception 'Nome da plataforma obrigatorio.'
      using errcode = '22023';
  end if;

  select pc.id
  into v_id
  from driver.platform_catalog pc
  where lower(pc.name) = lower(v_name)
    and lower(pc.type) = lower(v_type)
    and lower(coalesce(pc.city, '')) = lower(coalesce(v_city, ''))
    and lower(coalesce(pc.state, '')) = lower(coalesce(v_state, ''))
    and lower(coalesce(pc.country, 'Brasil')) = lower(v_country)
  limit 1;

  if v_id is not null then
    update driver.platform_catalog
    set
      logo_url = coalesce(v_logo_url, logo_url),
      updated_at = timezone('utc', now())
    where id = v_id;

    return v_id;
  end if;

  insert into driver.platform_catalog (
    name,
    type,
    city,
    state,
    country,
    logo_url,
    created_by
  )
  values (
    v_name,
    v_type,
    v_city,
    v_state,
    v_country,
    v_logo_url,
    auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function driver.upsert_platform_catalog_entry(
  text,
  text,
  text,
  text,
  text,
  text
) to authenticated;
