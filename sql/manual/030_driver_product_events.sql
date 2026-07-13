-- Omnya Driver
-- Product analytics and lightweight audit events.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/029_driver_feature_flags_ranking_metrics.sql.

create table if not exists driver.product_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  event_name text not null,
  screen text,
  metadata jsonb not null default '{}'::jsonb,
  app_version text,
  platform text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_driver_product_events_name_created
  on driver.product_events (event_name, created_at desc);

create index if not exists idx_driver_product_events_user_created
  on driver.product_events (user_id, created_at desc);

alter table driver.product_events enable row level security;

grant insert on driver.product_events to authenticated;
grant select on driver.product_events to authenticated;

drop policy if exists "driver_product_events_own_insert"
  on driver.product_events;
create policy "driver_product_events_own_insert"
  on driver.product_events
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "driver_product_events_developer_select"
  on driver.product_events;
create policy "driver_product_events_developer_select"
  on driver.product_events
  for select
  to authenticated
  using (driver.is_requester_developer());

create or replace function driver.track_product_event(
  p_event_name text,
  p_screen text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_app_version text default null,
  p_platform text default null
)
returns uuid
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_event_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if nullif(trim(coalesce(p_event_name, '')), '') is null then
    raise exception 'Nome do evento obrigatorio.'
      using errcode = '22023';
  end if;

  insert into driver.product_events (
    user_id,
    event_name,
    screen,
    metadata,
    app_version,
    platform
  )
  values (
    v_user_id,
    trim(p_event_name),
    nullif(trim(coalesce(p_screen, '')), ''),
    coalesce(p_metadata, '{}'::jsonb),
    nullif(trim(coalesce(p_app_version, '')), ''),
    nullif(trim(coalesce(p_platform, '')), '')
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

grant execute on function driver.track_product_event(
  text,
  text,
  jsonb,
  text,
  text
) to authenticated;

create or replace function driver.get_product_analytics_summary()
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'events_24h',
        count(*) filter (where created_at >= timezone('utc', now()) - interval '24 hours')::integer,
      'events_7d',
        count(*) filter (where created_at >= timezone('utc', now()) - interval '7 days')::integer,
      'active_event_users_7d',
        count(distinct user_id) filter (where created_at >= timezone('utc', now()) - interval '7 days')::integer,
      'top_events',
        coalesce(
          (
            select jsonb_agg(row_to_json(top_event))
            from (
              select
                event_name,
                count(*)::integer as total
              from driver.product_events
              where created_at >= timezone('utc', now()) - interval '7 days'
              group by event_name
              order by count(*) desc, event_name asc
              limit 10
            ) top_event
          ),
          '[]'::jsonb
        )
    )
    from driver.product_events
  );
end;
$$;

grant execute on function driver.get_product_analytics_summary()
  to authenticated;
