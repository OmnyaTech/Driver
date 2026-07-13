-- Omnya Driver
-- Account deletion request workflow.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor.

create table if not exists driver.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text,
  status text not null default 'requested',
  metadata jsonb not null default '{}'::jsonb,
  requested_at timestamptz not null default timezone('utc', now()),
  processed_at timestamptz
);

create index if not exists idx_driver_account_deletion_requests_user_status
  on driver.account_deletion_requests (user_id, status, requested_at desc);

alter table driver.account_deletion_requests enable row level security;

grant select, insert on driver.account_deletion_requests to authenticated;

drop policy if exists "driver_account_deletion_requests_own_select"
  on driver.account_deletion_requests;
create policy "driver_account_deletion_requests_own_select"
  on driver.account_deletion_requests
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "driver_account_deletion_requests_own_insert"
  on driver.account_deletion_requests;
create policy "driver_account_deletion_requests_own_insert"
  on driver.account_deletion_requests
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create or replace function driver.request_account_deletion(
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  select id
  into v_request_id
  from driver.account_deletion_requests
  where user_id = v_user_id
    and status = 'requested'
  order by requested_at desc
  limit 1;

  if v_request_id is null then
    insert into driver.account_deletion_requests (
      user_id,
      reason,
      metadata
    )
    values (
      v_user_id,
      nullif(trim(coalesce(p_reason, '')), ''),
      jsonb_build_object('source', 'app')
    )
    returning id into v_request_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'request_id', v_request_id,
    'status', 'requested'
  );
end;
$$;

grant execute on function driver.request_account_deletion(text) to authenticated;
