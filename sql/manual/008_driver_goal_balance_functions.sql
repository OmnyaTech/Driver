-- Omnya Driver
-- Goal balance helpers and safe goal transaction function.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

create or replace function driver.get_goal_balance_summary()
returns table (
  net_operational_result numeric,
  allocated_to_goals numeric,
  available_balance numeric
)
language sql
stable
set search_path = driver, auth, public
as $$
  with metrics as (
    select *
    from driver.get_dashboard_metrics(null, null)
  ),
  goal_totals as (
    select
      coalesce(sum(g.current_amount), 0)::numeric as allocated_to_goals
    from driver.goals g
    where g.user_id = auth.uid()
  )
  select
    coalesce(m.net_result, 0)::numeric as net_operational_result,
    gt.allocated_to_goals,
    (coalesce(m.net_result, 0)::numeric - gt.allocated_to_goals)::numeric as available_balance
  from metrics m
  cross join goal_totals gt;
$$;

grant execute on function driver.get_goal_balance_summary() to authenticated;

create or replace function driver.apply_goal_transaction(
  p_goal_id uuid,
  p_amount numeric,
  p_journey_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = driver, auth, public
as $$
declare
  v_goal driver.goals%rowtype;
  v_summary record;
  v_next_amount numeric;
  v_transaction_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if p_amount is null or p_amount = 0 then
    raise exception 'Valor da movimentacao deve ser diferente de zero.'
      using errcode = '22023';
  end if;

  select *
  into v_goal
  from driver.goals g
  where g.id = p_goal_id
    and g.user_id = auth.uid()
  limit 1;

  if v_goal.id is null then
    raise exception 'Objetivo nao encontrado para o usuario atual.'
      using errcode = 'P0002';
  end if;

  select *
  into v_summary
  from driver.get_goal_balance_summary();

  if p_amount > 0 and p_amount > coalesce(v_summary.available_balance, 0) then
    raise exception 'Saldo disponivel insuficiente para aporte.'
      using errcode = '22023';
  end if;

  if p_amount < 0 and abs(p_amount) > coalesce(v_goal.current_amount, 0) then
    raise exception 'Nao e possivel retirar mais do que o saldo do objetivo.'
      using errcode = '22023';
  end if;

  v_next_amount := coalesce(v_goal.current_amount, 0) + p_amount;

  update driver.goals
  set
    current_amount = v_next_amount,
    updated_at = timezone('utc', now())
  where id = v_goal.id;

  insert into driver.goal_transactions (
    goal_id,
    journey_id,
    amount
  )
  values (
    v_goal.id,
    p_journey_id,
    p_amount
  )
  returning id into v_transaction_id;

  return jsonb_build_object(
    'ok', true,
    'goal_id', v_goal.id,
    'transaction_id', v_transaction_id,
    'current_amount', v_next_amount,
    'available_balance_after', coalesce(v_summary.available_balance, 0) - p_amount
  );
end;
$$;

grant execute on function driver.apply_goal_transaction(uuid, numeric, uuid) to authenticated;
