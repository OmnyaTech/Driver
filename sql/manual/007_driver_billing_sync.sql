-- Omnya Driver
-- Billing sync helpers for Asaas checkout and webhook processing.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create or replace function driver.record_billing_event(
  p_provider text,
  p_event_type text,
  p_provider_object_id text default null,
  p_external_reference text default null,
  p_user_id uuid default null,
  p_status text default null,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_id uuid;
begin
  insert into driver.billing_events (
    provider,
    event_type,
    provider_object_id,
    external_reference,
    user_id,
    status,
    payload
  )
  values (
    coalesce(p_provider, 'asaas'),
    p_event_type,
    p_provider_object_id,
    p_external_reference,
    p_user_id,
    p_status,
    coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function driver.record_billing_event(
  text,
  text,
  text,
  text,
  uuid,
  text,
  jsonb
) to authenticated;

create or replace function driver.apply_billing_subscription_state(
  p_user_id uuid,
  p_plan_type driver.plan_type,
  p_status driver.subscription_status,
  p_provider text default 'asaas',
  p_provider_customer_id text default null,
  p_provider_subscription_id text default null,
  p_current_period_end timestamptz default null,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_email text;
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
    plan_type = p_plan_type,
    subscription_status = p_status,
    subscription_expires_at = p_current_period_end,
    current_period_end = p_current_period_end,
    asaas_customer_id = coalesce(p_provider_customer_id, asaas_customer_id),
    updated_at = v_now
  where id = p_user_id;

  insert into driver.subscriptions (
    user_id,
    plan_type,
    status,
    provider,
    provider_customer_id,
    provider_subscription_id,
    started_at,
    expires_at,
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
    v_now,
    p_current_period_end,
    v_now,
    v_now
  );

  perform driver.record_billing_event(
    p_provider => coalesce(p_provider, 'asaas'),
    p_event_type => 'subscription_state_synced',
    p_provider_object_id => p_provider_subscription_id,
    p_external_reference => null,
    p_user_id => p_user_id,
    p_status => p_status::text,
    p_payload => coalesce(p_payload, '{}'::jsonb)
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', p_user_id,
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
  jsonb
) to authenticated;
