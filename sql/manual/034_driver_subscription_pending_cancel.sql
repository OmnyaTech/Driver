-- Omnya Driver
-- Pending checkout cancellation.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/017_driver_subscription_pending_checkout.sql.

create or replace function driver.cancel_pending_subscription_checkout(
  p_reason text default 'checkout_abandoned'
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_subscription_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  update driver.subscriptions
  set
    status = 'cancelled'::driver.subscription_status,
    cancelled_at = timezone('utc', now()),
    cancel_requested_at = timezone('utc', now()),
    cancel_reason = nullif(trim(coalesce(p_reason, '')), ''),
    updated_at = timezone('utc', now())
  where user_id = v_user_id
    and cancelled_at is null
    and status = 'pending'::driver.subscription_status
  returning id into v_subscription_id;

  if v_subscription_id is null then
    return jsonb_build_object('ok', false, 'reason', 'no_pending_checkout');
  end if;

  update driver.profiles
  set
    plan_type = 'free'::driver.plan_type,
    subscription_status = 'inactive'::driver.subscription_status,
    subscription_expires_at = null,
    current_period_end = null,
    updated_at = timezone('utc', now())
  where id = v_user_id
    and subscription_status = 'pending'::driver.subscription_status;

  perform driver.record_billing_event(
    p_provider => 'asaas',
    p_event_type => 'checkout_cancelled_by_user',
    p_provider_object_id => null,
    p_external_reference => null,
    p_user_id => v_user_id,
    p_status => 'cancelled',
    p_payload => jsonb_build_object('reason', nullif(trim(coalesce(p_reason, '')), ''))
  );

  return jsonb_build_object(
    'ok', true,
    'subscription_id', v_subscription_id,
    'status', 'cancelled'
  );
end;
$$;

grant execute on function driver.cancel_pending_subscription_checkout(text)
  to authenticated;
