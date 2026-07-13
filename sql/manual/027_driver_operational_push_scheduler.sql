-- Omnya Driver
-- Operational push scheduler: queues reminders for the backend push sender.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/024_driver_growth_operations.sql.
-- Then schedule your backend/cron to call the Edge Function driver-send-push
-- periodically with SUPABASE_SERVICE_ROLE_KEY + DRIVER_PUSH_SERVICE_SECRET.

create or replace function driver.enqueue_operational_push_jobs()
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_journey_count integer := 0;
  v_goal_count integer := 0;
  v_subscription_count integer := 0;
begin
  if auth.uid() is not null and not driver.is_requester_developer() then
    raise exception 'Acesso developer obrigatorio.'
      using errcode = '42501';
  end if;

  with candidates as (
    select
      j.user_id,
      'journey-open-' || j.id::text as notification_key,
      'journey_reminder' as event_type,
      'Jornada em aberto' as title,
      'Sua jornada ainda esta rodando. Se terminou, feche para manter seus numeros certos.' as body,
      jsonb_build_object(
        'journey_id', j.id,
        'started_at', j.started_at,
        'route', '/journeys'
      ) as payload
    from driver.journeys j
    where j.ended_at is null
      and j.started_at <= v_now - interval '3 hours'
  ),
  inserted as (
    insert into driver.driver_push_jobs (
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      scheduled_at
    )
    select
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      v_now
    from candidates
    on conflict (user_id, notification_key) do nothing
    returning id
  )
  select count(*)::integer into v_journey_count from inserted;

  with candidates as (
    select
      g.user_id,
      'goal-due-' || g.id::text || '-' || g.deadline::text as notification_key,
      'goal_reminder' as event_type,
      'Meta chegando' as title,
      'Uma meta esta perto do prazo. Veja se vale guardar um pouco hoje.' as body,
      jsonb_build_object(
        'goal_id', g.id,
        'deadline', g.deadline,
        'route', '/goals'
      ) as payload
    from driver.goals g
    where g.deadline is not null
      and g.deadline between v_now::date and (v_now::date + 3)
      and coalesce(g.current_amount, 0) < g.target_amount
  ),
  inserted as (
    insert into driver.driver_push_jobs (
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      scheduled_at
    )
    select
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      v_now
    from candidates
    on conflict (user_id, notification_key) do nothing
    returning id
  )
  select count(*)::integer into v_goal_count from inserted;

  with candidates as (
    select
      s.user_id,
      'subscription-pending-' || s.id::text as notification_key,
      'subscription_pending' as event_type,
      'Pagamento pendente' as title,
      'Seu checkout foi criado. Assim que o pagamento cair, o Premium entra automaticamente.' as body,
      jsonb_build_object(
        'subscription_id', s.id,
        'external_reference', s.external_reference,
        'route', '/settings/subscription'
      ) as payload
    from driver.subscriptions s
    where s.cancelled_at is null
      and s.status = 'pending'::driver.subscription_status
      and s.updated_at <= v_now - interval '20 minutes'
  ),
  inserted as (
    insert into driver.driver_push_jobs (
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      scheduled_at
    )
    select
      user_id,
      notification_key,
      event_type,
      title,
      body,
      payload,
      v_now
    from candidates
    on conflict (user_id, notification_key) do nothing
    returning id
  )
  select count(*)::integer into v_subscription_count from inserted;

  insert into driver.driver_notifications (
    user_id,
    notification_key,
    kind,
    title,
    body,
    action_type,
    action_payload
  )
  select
    pj.user_id,
    pj.notification_key,
    pj.event_type,
    pj.title,
    pj.body,
    pj.event_type,
    pj.payload
  from driver.driver_push_jobs pj
  where pj.status = 'queued'
    and pj.created_at >= v_now - interval '1 minute'
  on conflict (user_id, notification_key) do nothing;

  return jsonb_build_object(
    'ok', true,
    'journey_jobs', v_journey_count,
    'goal_jobs', v_goal_count,
    'subscription_jobs', v_subscription_count
  );
end;
$$;

grant execute on function driver.enqueue_operational_push_jobs()
  to authenticated;
