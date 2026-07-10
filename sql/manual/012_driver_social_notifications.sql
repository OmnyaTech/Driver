-- Omnya Driver
-- Social discovery and engagement notifications.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create table if not exists driver.driver_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_key text not null,
  kind text not null,
  title text not null,
  body text not null,
  action_type text,
  action_payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, notification_key)
);

create index if not exists idx_driver_notifications_user_id_created_at
  on driver.driver_notifications (user_id, created_at desc);

create index if not exists idx_driver_notifications_user_id_read_at
  on driver.driver_notifications (user_id, read_at, created_at desc);

alter table driver.driver_notifications enable row level security;

grant select, insert, update on driver.driver_notifications to authenticated;

drop policy if exists "driver_notifications_own_all" on driver.driver_notifications;
create policy "driver_notifications_own_all"
  on driver.driver_notifications
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function driver.list_public_driver_profiles(
  p_query text default null,
  p_limit integer default 20
)
returns table (
  public_slug text,
  display_name text,
  avatar_url text,
  public_city text,
  level integer,
  level_title text,
  medals_count integer,
  public_score integer,
  best_streak_days integer
)
language sql
security definer
stable
set search_path = driver, auth, public
as $$
  select
    p.public_slug,
    p.display_name,
    p.avatar_url,
    p.public_city,
    dp.level,
    dp.level_title,
    dp.medals_count,
    dp.public_score,
    dp.best_streak_days
  from driver.profiles p
  join driver.driver_progress dp on dp.user_id = p.id
  where p.public_profile_enabled = true
    and p.public_slug is not null
    and (
      p_query is null
      or trim(p_query) = ''
      or lower(p.display_name) like '%' || lower(trim(p_query)) || '%'
      or lower(p.public_slug) like '%' || lower(trim(p_query)) || '%'
      or lower(coalesce(p.public_city, '')) like '%' || lower(trim(p_query)) || '%'
    )
  order by dp.public_score desc, dp.xp desc, p.display_name asc
  limit greatest(coalesce(p_limit, 20), 1);
$$;

grant execute on function driver.list_public_driver_profiles(text, integer) to authenticated;
