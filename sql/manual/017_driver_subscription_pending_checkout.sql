-- Omnya Driver
-- Subscription pending checkout and single current subscription control.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor after
-- sql/manual/017a_driver_subscription_pending_status.sql.

alter table driver.subscriptions
  add column if not exists external_reference text;

create unique index if not exists idx_driver_subscriptions_external_reference_unique
  on driver.subscriptions (external_reference)
  where external_reference is not null;

with ranked as (
  select
    id,
    row_number() over (
      partition by user_id, coalesce(provider, 'asaas')
      order by
        case
          when status = 'active'::driver.subscription_status then 1
          when status = 'pending'::driver.subscription_status then 2
          when status = 'overdue'::driver.subscription_status then 3
          when status = 'gifted'::driver.subscription_status then 4
          else 9
        end,
        updated_at desc,
        created_at desc
    ) as position
  from driver.subscriptions
  where cancelled_at is null
    and status in (
      'active'::driver.subscription_status,
      'pending'::driver.subscription_status,
      'overdue'::driver.subscription_status,
      'gifted'::driver.subscription_status
    )
)
update driver.subscriptions s
set
  status = 'expired'::driver.subscription_status,
  cancelled_at = coalesce(s.cancelled_at, timezone('utc', now())),
  updated_at = timezone('utc', now())
from ranked r
where r.id = s.id
  and r.position > 1;

create unique index if not exists idx_driver_subscriptions_one_current_provider
  on driver.subscriptions (user_id, (coalesce(provider, 'asaas')))
  where cancelled_at is null
    and status in (
      'active'::driver.subscription_status,
      'pending'::driver.subscription_status,
      'overdue'::driver.subscription_status,
      'gifted'::driver.subscription_status
    );

create or replace function driver.mark_subscription_checkout_pending(
  p_user_id uuid,
  p_plan_type driver.plan_type,
  p_provider text default 'asaas',
  p_external_reference text default null,
  p_provider_checkout_id text default null,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_profile driver.profiles%rowtype;
  v_subscription_id uuid;
begin
  select *
  into v_profile
  from driver.profiles
  where id = p_user_id
  limit 1;

  if v_profile.id is null then
    raise exception 'Perfil do usuario nao encontrado.'
      using errcode = 'P0002';
  end if;

  if v_profile.plan_type in (
    'premium'::driver.plan_type,
    'gift'::driver.plan_type,
    'lifetime'::driver.plan_type,
    'developer'::driver.plan_type
  )
  and v_profile.subscription_status in (
    'active'::driver.subscription_status,
    'gifted'::driver.subscription_status
  ) then
    return jsonb_build_object(
      'ok', false,
      'reason', 'already_active',
      'message', 'Voce ja tem um plano ativo.'
    );
  end if;

  update driver.subscriptions
  set
    plan_type = p_plan_type,
    status = 'pending'::driver.subscription_status,
    provider = coalesce(p_provider, provider, 'asaas'),
    provider_subscription_id = coalesce(p_provider_checkout_id, provider_subscription_id),
    external_reference = coalesce(p_external_reference, external_reference),
    cancelled_at = null,
    updated_at = v_now
  where user_id = p_user_id
    and coalesce(provider, 'asaas') = coalesce(p_provider, 'asaas')
    and cancelled_at is null
    and status = 'pending'::driver.subscription_status
  returning id into v_subscription_id;

  if v_subscription_id is null then
    insert into driver.subscriptions (
      user_id,
      plan_type,
      status,
      provider,
      provider_subscription_id,
      external_reference,
      started_at,
      created_at,
      updated_at
    )
    values (
      p_user_id,
      p_plan_type,
      'pending'::driver.subscription_status,
      coalesce(p_provider, 'asaas'),
      p_provider_checkout_id,
      p_external_reference,
      null,
      v_now,
      v_now
    )
    returning id into v_subscription_id;
  end if;

  update driver.profiles
  set
    subscription_status = 'pending'::driver.subscription_status,
    updated_at = v_now
  where id = p_user_id;

  perform driver.record_billing_event(
    p_provider => coalesce(p_provider, 'asaas'),
    p_event_type => 'checkout_pending',
    p_provider_object_id => p_provider_checkout_id,
    p_external_reference => p_external_reference,
    p_user_id => p_user_id,
    p_status => 'pending',
    p_payload => coalesce(p_payload, '{}'::jsonb)
  );

  return jsonb_build_object(
    'ok', true,
    'subscription_id', v_subscription_id,
    'status', 'pending'
  );
end;
$$;

grant execute on function driver.mark_subscription_checkout_pending(
  uuid,
  driver.plan_type,
  text,
  text,
  text,
  jsonb
) to authenticated;

drop function if exists driver.apply_billing_subscription_state(
  uuid,
  driver.plan_type,
  driver.subscription_status,
  text,
  text,
  text,
  timestamptz,
  jsonb
);

create or replace function driver.apply_billing_subscription_state(
  p_user_id uuid,
  p_plan_type driver.plan_type,
  p_status driver.subscription_status,
  p_provider text default 'asaas',
  p_provider_customer_id text default null,
  p_provider_subscription_id text default null,
  p_current_period_end timestamptz default null,
  p_payload jsonb default '{}'::jsonb,
  p_external_reference text default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_email text;
  v_subscription_id uuid;
begin
  select p.email
  into v_email
  from driver.profiles p
  where p.id = p_user_id;

  if v_email is null then
    raise exception 'Perfil do usuario nao encontrado.'
      using errcode = 'P0002';
  end if;

  update driver.profiles
  set
    plan_type = case
      when p_status in ('active'::driver.subscription_status, 'gifted'::driver.subscription_status)
        then p_plan_type
      when p_status in ('cancelled'::driver.subscription_status, 'expired'::driver.subscription_status, 'inactive'::driver.subscription_status)
        then 'free'::driver.plan_type
      else plan_type
    end,
    subscription_status = p_status,
    subscription_expires_at = p_current_period_end,
    current_period_end = p_current_period_end,
    asaas_customer_id = coalesce(p_provider_customer_id, asaas_customer_id),
    updated_at = v_now
  where id = p_user_id;

  update driver.subscriptions
  set
    plan_type = p_plan_type,
    status = p_status,
    provider = coalesce(p_provider, provider, 'asaas'),
    provider_customer_id = coalesce(p_provider_customer_id, provider_customer_id),
    provider_subscription_id = coalesce(p_provider_subscription_id, provider_subscription_id),
    external_reference = coalesce(p_external_reference, external_reference),
    started_at = case
      when p_status in ('active'::driver.subscription_status, 'gifted'::driver.subscription_status)
        then coalesce(started_at, v_now)
      else started_at
    end,
    expires_at = p_current_period_end,
    cancelled_at = case
      when p_status in ('cancelled'::driver.subscription_status, 'expired'::driver.subscription_status, 'inactive'::driver.subscription_status)
        then coalesce(cancelled_at, v_now)
      else null
    end,
    updated_at = v_now
  where user_id = p_user_id
    and coalesce(provider, 'asaas') = coalesce(p_provider, 'asaas')
    and (
      (p_external_reference is not null and external_reference = p_external_reference)
      or (
        p_external_reference is null
        and cancelled_at is null
        and status in (
          'pending'::driver.subscription_status,
          'active'::driver.subscription_status,
          'overdue'::driver.subscription_status
        )
      )
    )
  returning id into v_subscription_id;

  if v_subscription_id is null then
    insert into driver.subscriptions (
      user_id,
      plan_type,
      status,
      provider,
      provider_customer_id,
      provider_subscription_id,
      external_reference,
      started_at,
      expires_at,
      cancelled_at,
      created_at,
      updated_at
    )
    values (
      p_user_id,
      p_plan_type,
      p_status,
      coalesce(p_provider, 'asaas'),
      p_provider_customer_id,
      p_provider_subscription_id,
      p_external_reference,
      case
        when p_status in ('active'::driver.subscription_status, 'gifted'::driver.subscription_status)
          then v_now
        else null
      end,
      p_current_period_end,
      case
        when p_status in ('cancelled'::driver.subscription_status, 'expired'::driver.subscription_status, 'inactive'::driver.subscription_status)
          then v_now
        else null
      end,
      v_now,
      v_now
    )
    returning id into v_subscription_id;
  end if;

  perform driver.record_billing_event(
    p_provider => coalesce(p_provider, 'asaas'),
    p_event_type => 'subscription_state_synced',
    p_provider_object_id => p_provider_subscription_id,
    p_external_reference => p_external_reference,
    p_user_id => p_user_id,
    p_status => p_status::text,
    p_payload => coalesce(p_payload, '{}'::jsonb)
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', p_user_id,
    'subscription_id', v_subscription_id,
    'email', v_email,
    'plan_type', p_plan_type,
    'status', p_status
  );
end;
$$;

grant execute on function driver.apply_billing_subscription_state(
  uuid,
  driver.plan_type,
  driver.subscription_status,
  text,
  text,
  text,
  timestamptz,
  jsonb,
  text
) to authenticated;
