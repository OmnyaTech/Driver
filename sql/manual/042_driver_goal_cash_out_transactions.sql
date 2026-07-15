-- Omnya Driver
-- Goal cash-out movement metadata.
-- Date: 2026-07-15
-- Execute manually in Supabase SQL Editor after 041.

alter table driver.goal_transactions
  add column if not exists movement_type text not null default 'contribution',
  add column if not exists note text;

update driver.goal_transactions
set movement_type = case
  when amount >= 0 then 'contribution'
  else 'withdrawal'
end
where movement_type is null
   or movement_type = ''
   or (movement_type = 'contribution' and amount < 0);

alter table driver.goal_transactions
  drop constraint if exists goal_transactions_movement_type_check;

alter table driver.goal_transactions
  add constraint goal_transactions_movement_type_check
  check (movement_type in ('contribution', 'withdrawal', 'cash_out'));

drop function if exists driver.apply_goal_transaction(uuid, numeric, uuid);

create or replace function driver.apply_goal_transaction(
  p_goal_id uuid,
  p_amount numeric,
  p_journey_id uuid default null,
  p_movement_type text default null,
  p_note text default null
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
  v_movement_type text;
  v_note text;
begin
  if auth.uid() is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  if p_amount is null or p_amount = 0 then
    raise exception 'Valor da movimentacao deve ser diferente de zero.'
      using errcode = '22023';
  end if;

  v_movement_type := coalesce(
    nullif(trim(p_movement_type), ''),
    case when p_amount >= 0 then 'contribution' else 'withdrawal' end
  );

  if v_movement_type not in ('contribution', 'withdrawal', 'cash_out') then
    raise exception 'Tipo de movimentacao invalido.'
      using errcode = '22023';
  end if;

  if v_movement_type = 'contribution' and p_amount < 0 then
    raise exception 'Aporte precisa ter valor positivo.'
      using errcode = '22023';
  end if;

  if v_movement_type in ('withdrawal', 'cash_out') and p_amount > 0 then
    raise exception 'Retirada ou saque precisam ter valor negativo.'
      using errcode = '22023';
  end if;

  v_note := nullif(trim(p_note), '');

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
    amount,
    movement_type,
    note
  )
  values (
    v_goal.id,
    p_journey_id,
    p_amount,
    v_movement_type,
    v_note
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

grant execute on function driver.apply_goal_transaction(uuid, numeric, uuid, text, text) to authenticated;
