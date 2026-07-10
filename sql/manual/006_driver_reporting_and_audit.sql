-- Omnya Driver
-- Reporting functions, audit log and developer history.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create table if not exists driver.developer_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  target_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  summary text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists driver.billing_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'asaas',
  event_type text not null,
  provider_object_id text,
  external_reference text,
  user_id uuid references auth.users(id) on delete set null,
  status text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_driver_developer_audit_logs_created_at
  on driver.developer_audit_logs (created_at desc);

create index if not exists idx_driver_developer_audit_logs_target
  on driver.developer_audit_logs (target_user_id, created_at desc);

create index if not exists idx_driver_billing_events_user_id_created_at
  on driver.billing_events (user_id, created_at desc);

create index if not exists idx_driver_billing_events_external_reference
  on driver.billing_events (external_reference);

alter table driver.developer_audit_logs enable row level security;
alter table driver.billing_events enable row level security;

grant select, insert on driver.developer_audit_logs to authenticated;
grant select, insert on driver.billing_events to authenticated;

drop policy if exists "driver_billing_events_own_select" on driver.billing_events;
create policy "driver_billing_events_own_select"
  on driver.billing_events
  for select
  to authenticated
  using (auth.uid() = user_id or driver.is_requester_developer());

drop policy if exists "driver_developer_audit_logs_developer_select" on driver.developer_audit_logs;
create policy "driver_developer_audit_logs_developer_select"
  on driver.developer_audit_logs
  for select
  to authenticated
  using (driver.is_requester_developer());

create or replace function driver.write_admin_audit(
  p_action text,
  p_target_user_id uuid default null,
  p_summary text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_id uuid;
begin
  insert into driver.developer_audit_logs (
    actor_user_id,
    target_user_id,
    action,
    summary,
    metadata
  )
  values (
    auth.uid(),
    p_target_user_id,
    p_action,
    p_summary,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function driver.admin_grant_access(
  text,
  driver.plan_type,
  driver.user_role,
  timestamptz
) to authenticated;

grant execute on function driver.write_admin_audit(text, uuid, text, jsonb) to authenticated;

create or replace function driver.admin_list_audit_logs(p_limit integer default 50)
returns table (
  id uuid,
  action text,
  summary text,
  actor_email text,
  target_email text,
  metadata jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = driver, auth, public
as $$
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  return query
  select
    l.id,
    l.action,
    l.summary,
    actor_profile.email as actor_email,
    target_profile.email as target_email,
    l.metadata,
    l.created_at
  from driver.developer_audit_logs l
  left join driver.profiles actor_profile on actor_profile.id = l.actor_user_id
  left join driver.profiles target_profile on target_profile.id = l.target_user_id
  order by l.created_at desc
  limit greatest(coalesce(p_limit, 50), 1);
end;
$$;

grant execute on function driver.admin_list_audit_logs(integer) to authenticated;

create or replace function driver.get_dashboard_metrics(
  p_start_at timestamptz default null,
  p_end_at timestamptz default null
)
returns table (
  total_income numeric,
  total_operational_costs numeric,
  net_result numeric,
  total_journeys integer,
  open_journeys integer,
  total_deliveries integer,
  total_distance_km numeric,
  active_vehicles integer,
  active_platforms integer,
  total_fuelings integer,
  total_maintenances integer,
  total_trip_expenses integer
)
language sql
stable
set search_path = driver, auth, public
as $$
  with filtered_journeys as (
    select *
    from driver.journeys j
    where j.user_id = auth.uid()
      and (p_start_at is null or j.started_at >= p_start_at)
      and (p_end_at is null or j.started_at <= p_end_at)
  ),
  journey_revenue as (
    select
      jp.journey_id,
      coalesce(sum(jp.income), 0)::numeric as income,
      coalesce(sum(jp.deliveries), 0)::integer as deliveries
    from driver.journey_platforms jp
    join filtered_journeys j on j.id = jp.journey_id
    group by jp.journey_id
  ),
  trip_expenses as (
    select
      coalesce(sum(te.amount), 0)::numeric as total_amount,
      count(*)::integer as total_count
    from driver.trip_expenses te
    where te.user_id = auth.uid()
      and (p_start_at is null or te.occurred_at >= p_start_at)
      and (p_end_at is null or te.occurred_at <= p_end_at)
  ),
  fuelings as (
    select
      coalesce(sum(f.total_amount), 0)::numeric as total_amount,
      count(*)::integer as total_count
    from driver.fuelings f
    where f.user_id = auth.uid()
      and (p_start_at is null or f.fueled_at >= p_start_at)
      and (p_end_at is null or f.fueled_at <= p_end_at)
  ),
  maintenances as (
    select
      coalesce(sum(m.total_amount), 0)::numeric as total_amount,
      count(*)::integer as total_count
    from driver.maintenances m
    where m.user_id = auth.uid()
      and (
        p_start_at is null
        or m.maintenance_date >= (p_start_at at time zone 'utc')::date
      )
      and (
        p_end_at is null
        or m.maintenance_date <= (p_end_at at time zone 'utc')::date
      )
  ),
  journey_totals as (
    select
      coalesce(sum(jr.income), 0)::numeric as total_income,
      coalesce(sum(jr.deliveries), 0)::integer as total_deliveries,
      count(*)::integer as total_journeys,
      count(*) filter (where j.ended_at is null)::integer as open_journeys,
      coalesce(sum(
        case
          when j.odometer_start is not null
            and j.odometer_end is not null
            and j.odometer_end >= j.odometer_start
          then j.odometer_end - j.odometer_start
          else 0
        end
      ), 0)::numeric as total_distance_km
    from filtered_journeys j
    left join journey_revenue jr on jr.journey_id = j.id
  )
  select
    jt.total_income,
    (te.total_amount + fu.total_amount + ma.total_amount)::numeric as total_operational_costs,
    (jt.total_income - (te.total_amount + fu.total_amount + ma.total_amount))::numeric as net_result,
    jt.total_journeys,
    jt.open_journeys,
    jt.total_deliveries,
    jt.total_distance_km,
    (
      select count(*)::integer
      from driver.vehicles v
      where v.user_id = auth.uid()
        and v.active = true
    ) as active_vehicles,
    (
      select count(*)::integer
      from driver.platforms p
      where p.user_id = auth.uid()
        and p.active = true
    ) as active_platforms,
    fu.total_count as total_fuelings,
    ma.total_count as total_maintenances,
    te.total_count as total_trip_expenses
  from journey_totals jt
  cross join trip_expenses te
  cross join fuelings fu
  cross join maintenances ma;
$$;

grant execute on function driver.get_dashboard_metrics(timestamptz, timestamptz) to authenticated;

create or replace function driver.get_operational_report(
  p_start_at timestamptz default null,
  p_end_at timestamptz default null
)
returns jsonb
language plpgsql
stable
set search_path = driver, auth, public
as $$
declare
  v_metrics record;
  v_top_platforms jsonb;
  v_expense_breakdown jsonb;
begin
  select *
  into v_metrics
  from driver.get_dashboard_metrics(p_start_at, p_end_at);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'platform_name', platform_name,
        'income', income,
        'deliveries', deliveries
      )
      order by income desc
    ),
    '[]'::jsonb
  )
  into v_top_platforms
  from (
    select
      coalesce(p.name, 'Plataforma') as platform_name,
      coalesce(sum(jp.income), 0)::numeric as income,
      coalesce(sum(jp.deliveries), 0)::integer as deliveries
    from driver.journey_platforms jp
    join driver.journeys j on j.id = jp.journey_id
    left join driver.platforms p on p.id = jp.platform_id
    where j.user_id = auth.uid()
      and (p_start_at is null or j.started_at >= p_start_at)
      and (p_end_at is null or j.started_at <= p_end_at)
    group by coalesce(p.name, 'Plataforma')
    order by income desc
    limit 5
  ) top_platforms;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'label', label,
        'amount', amount
      )
      order by amount desc
    ),
    '[]'::jsonb
  )
  into v_expense_breakdown
  from (
    select label, amount
    from (
      select 'Despesas de percurso'::text as label,
             coalesce(sum(te.amount), 0)::numeric as amount
      from driver.trip_expenses te
      where te.user_id = auth.uid()
        and (p_start_at is null or te.occurred_at >= p_start_at)
        and (p_end_at is null or te.occurred_at <= p_end_at)
      union all
      select 'Abastecimentos'::text,
             coalesce(sum(f.total_amount), 0)::numeric
      from driver.fuelings f
      where f.user_id = auth.uid()
        and (p_start_at is null or f.fueled_at >= p_start_at)
        and (p_end_at is null or f.fueled_at <= p_end_at)
      union all
      select 'Manutencoes'::text,
             coalesce(sum(m.total_amount), 0)::numeric
      from driver.maintenances m
      where m.user_id = auth.uid()
        and (
          p_start_at is null
          or m.maintenance_date >= (p_start_at at time zone 'utc')::date
        )
        and (
          p_end_at is null
          or m.maintenance_date <= (p_end_at at time zone 'utc')::date
        )
    ) breakdown
  ) expense_summary;

  return jsonb_build_object(
    'start_at', p_start_at,
    'end_at', p_end_at,
    'total_income', coalesce(v_metrics.total_income, 0),
    'total_operational_costs', coalesce(v_metrics.total_operational_costs, 0),
    'net_result', coalesce(v_metrics.net_result, 0),
    'total_journeys', coalesce(v_metrics.total_journeys, 0),
    'total_deliveries', coalesce(v_metrics.total_deliveries, 0),
    'total_distance_km', coalesce(v_metrics.total_distance_km, 0),
    'top_platforms', v_top_platforms,
    'expense_breakdown', v_expense_breakdown
  );
end;
$$;

grant execute on function driver.get_operational_report(timestamptz, timestamptz) to authenticated;

create or replace function driver.admin_grant_access(
  p_email text,
  p_plan_type driver.plan_type,
  p_role driver.user_role default 'user',
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_target_id uuid;
  v_target_email text;
  v_full_name text;
  v_display_name text;
  v_role driver.user_role;
  v_status driver.subscription_status;
begin
  if not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  select
    u.id,
    u.email,
    nullif(trim(coalesce(
      u.raw_user_meta_data ->> 'full_name',
      u.raw_user_meta_data ->> 'name',
      ''
    )), ''),
    coalesce(
      nullif(trim(split_part(coalesce(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        u.email,
        'Motorista'
      ), ' ', 1)), ''),
      'Motorista'
    )
  into
    v_target_id,
    v_target_email,
    v_full_name,
    v_display_name
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  if v_target_id is null then
    raise exception 'Usuario nao encontrado para o e-mail informado.'
      using errcode = 'P0002';
  end if;

  v_role := case
    when p_plan_type = 'developer' then 'developer'::driver.user_role
    else coalesce(p_role, 'user'::driver.user_role)
  end;

  v_status := case p_plan_type
    when 'free' then 'inactive'::driver.subscription_status
    when 'gift' then 'gifted'::driver.subscription_status
    else 'active'::driver.subscription_status
  end;

  insert into driver.profiles (
    id,
    email,
    full_name,
    display_name,
    role,
    plan_type,
    subscription_status,
    subscription_expires_at,
    current_period_end,
    gifted_by,
    gifted_at,
    updated_at
  )
  values (
    v_target_id,
    v_target_email,
    v_full_name,
    v_display_name,
    v_role,
    p_plan_type,
    v_status,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type = 'gift' then auth.uid() else null end,
    case when p_plan_type = 'gift' then v_now else null end,
    v_now
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(driver.profiles.full_name, excluded.full_name),
    display_name = coalesce(driver.profiles.display_name, excluded.display_name),
    role = v_role,
    plan_type = p_plan_type,
    subscription_status = v_status,
    subscription_expires_at = case
      when p_plan_type in ('premium', 'gift') then p_expires_at
      else null
    end,
    current_period_end = case
      when p_plan_type in ('premium', 'gift') then p_expires_at
      else null
    end,
    gifted_by = case when p_plan_type = 'gift' then auth.uid() else null end,
    gifted_at = case when p_plan_type = 'gift' then v_now else null end,
    updated_at = v_now;

  insert into driver.subscriptions (
    user_id,
    plan_type,
    status,
    provider,
    started_at,
    expires_at,
    gifted_by,
    created_at,
    updated_at
  )
  values (
    v_target_id,
    p_plan_type,
    v_status,
    case
      when p_plan_type = 'gift' then 'gift_admin'
      when p_plan_type = 'developer' then 'developer_admin'
      else 'manual_admin'
    end,
    v_now,
    case when p_plan_type in ('premium', 'gift') then p_expires_at else null end,
    case when p_plan_type = 'gift' then auth.uid() else null end,
    v_now,
    v_now
  );

  perform driver.write_admin_audit(
    p_action => 'grant_access',
    p_target_user_id => v_target_id,
    p_summary => format(
      'Plano %s com papel %s aplicado manualmente.',
      p_plan_type,
      v_role
    ),
    p_metadata => jsonb_build_object(
      'email', v_target_email,
      'plan_type', p_plan_type,
      'role', v_role,
      'expires_at', p_expires_at
    )
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', v_target_id,
    'email', v_target_email,
    'message', format('Acesso %s aplicado para %s.', p_plan_type, v_target_email)
  );
end;
$$;
