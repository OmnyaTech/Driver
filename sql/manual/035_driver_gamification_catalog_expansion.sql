-- Omnya Driver
-- Expanded gamification catalog: level titles, unique titles, missions and referral benefits.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after sql/manual/031_driver_product_completion.sql.

create table if not exists driver.driver_titles (
  id uuid primary key default gen_random_uuid(),
  title_key text not null unique,
  title text not null,
  description text,
  unlock_type text not null default 'level',
  required_level integer,
  required_metric text,
  required_value integer,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table driver.driver_titles enable row level security;

grant select on driver.driver_titles to authenticated;

drop policy if exists "driver_titles_authenticated_select"
  on driver.driver_titles;
create policy "driver_titles_authenticated_select"
  on driver.driver_titles
  for select
  to authenticated
  using (active = true);

with generated as (
  select
    gs as idx,
    (gs * 6 + 1) as required_level,
    (array[
      'Entregador iniciante',
      'Entregador atento',
      'Entregador de bairro',
      'Entregador constante',
      'Entregador agil',
      'Entregador urbano',
      'Entregador de rota',
      'Entregador firme',
      'Entregador estrategista',
      'Entregador premium',
      'Entregador mestre',
      'Entregador elite',
      'Entregador campeao',
      'Entregador lendario',
      'Entregador titan',
      'Entregador estrela',
      'Entregador invicto',
      'Entregador comandante',
      'Entregador implacavel',
      'Entregador mito'
    ])[(gs % 20) + 1] as base_title,
    ((gs / 20)::integer + 1) as chapter
  from generate_series(0, 199) gs
)
insert into driver.driver_titles (
  title_key,
  title,
  description,
  unlock_type,
  required_level
)
select
  'level_' || required_level::text,
  case
    when idx = 0 then 'Entregador iniciante'
    else base_title || ' ' || chapter::text
  end,
  'Titulo padrao liberado no nivel ' || required_level::text || '.',
  'level',
  required_level
from generated
on conflict (title_key) do update
set
  title = excluded.title,
  description = excluded.description,
  unlock_type = excluded.unlock_type,
  required_level = excluded.required_level,
  active = true,
  updated_at = timezone('utc', now());

with generated as (
  select
    gs,
    (array[
      'Guardiao',
      'Ligeiro',
      'Parceiro',
      'Campeao',
      'Explorador',
      'Falcao',
      'Sentinela',
      'Condutor',
      'Veterano',
      'Heroi',
      'Navegador',
      'Piloto',
      'Arquiteto',
      'Mestre',
      'Radar',
      'Cometa',
      'Fenix',
      'Ritmo',
      'Turbo',
      'Veloz',
      'Estrategista',
      'Capitao',
      'Lenda',
      'Estrela',
      'Craque'
    ])[((gs - 1) % 25) + 1] as prefix,
    (array[
      'da rota',
      'do bairro',
      'da madrugada',
      'do horario nobre',
      'da comunidade'
    ])[((gs - 1) / 25)::integer + 1] as suffix
  from generate_series(1, 125) gs
)
insert into driver.driver_titles (
  title_key,
  title,
  description,
  unlock_type,
  required_metric,
  required_value
)
select
  'unique_' || gs::text,
  prefix || ' ' || suffix,
  'Titulo unico liberado por conquista especial.',
  'unique',
  case
    when gs % 4 = 0 then 'referrals'
    when gs % 4 = 1 then 'journeys'
    when gs % 4 = 2 then 'deliveries'
    else 'goals'
  end,
  case
    when gs % 4 = 0 then 1 + (gs % 25)
    when gs % 4 = 1 then 5 + gs
    when gs % 4 = 2 then 20 + (gs * 3)
    else 1 + (gs % 12)
  end
from generated
on conflict (title_key) do update
set
  title = excluded.title,
  description = excluded.description,
  unlock_type = excluded.unlock_type,
  required_metric = excluded.required_metric,
  required_value = excluded.required_value,
  active = true,
  updated_at = timezone('utc', now());

with generated as (
  select
    gs,
    (array['journeys', 'deliveries', 'goals', 'referrals'])[((gs - 1) % 4) + 1] as metric
  from generate_series(1, 125) gs
)
insert into driver.driver_missions (
  mission_key,
  title,
  description,
  cadence,
  target_metric,
  target_value,
  reward_xp,
  reward_title
)
select
  'unique_mission_' || gs::text,
  'Conquista unica ' || gs::text,
  'Complete este desafio especial para liberar pontos e destaque no perfil.',
  'unique',
  metric,
  case metric
    when 'journeys' then 5 + gs
    when 'deliveries' then 20 + (gs * 3)
    when 'goals' then 1 + (gs % 12)
    when 'referrals' then 1 + (gs % 25)
    else gs
  end,
  40 + ((gs % 10) * 5),
  'unique_' || gs::text
from generated
on conflict (mission_key) do update
set
  title = excluded.title,
  description = excluded.description,
  cadence = excluded.cadence,
  target_metric = excluded.target_metric,
  target_value = excluded.target_value,
  reward_xp = excluded.reward_xp,
  reward_title = excluded.reward_title,
  active = true,
  updated_at = timezone('utc', now());

with generated as (
  select
    gs,
    (array['journeys', 'deliveries', 'goals'])[((gs - 1) % 3) + 1] as metric
  from generate_series(1, 60) gs
)
insert into driver.driver_missions (
  mission_key,
  title,
  description,
  cadence,
  target_metric,
  target_value,
  reward_xp,
  reward_title
)
select
  'weekly_scaled_' || gs::text,
  'Semana de ritmo ' || gs::text,
  'Missao semanal que acompanha sua evolucao no Driver.',
  'weekly',
  metric,
  case metric
    when 'journeys' then 2 + ((gs - 1) / 6)::integer
    when 'deliveries' then 10 + (gs * 2)
    when 'goals' then 1 + ((gs - 1) / 15)::integer
    else gs
  end,
  25 + ((gs % 8) * 5),
  null
from generated
on conflict (mission_key) do update
set
  title = excluded.title,
  description = excluded.description,
  cadence = excluded.cadence,
  target_metric = excluded.target_metric,
  target_value = excluded.target_value,
  reward_xp = excluded.reward_xp,
  reward_title = excluded.reward_title,
  active = true,
  updated_at = timezone('utc', now());

insert into driver.driver_missions (
  mission_key,
  title,
  description,
  cadence,
  target_metric,
  target_value,
  reward_xp,
  reward_title
)
values
  ('holiday_confraternizacao', 'Virada organizada', 'Registre uma jornada no periodo de Ano Novo.', 'holiday', 'journeys', 1, 40, 'Rota da virada'),
  ('holiday_carnaval', 'Ritmo de Carnaval', 'Mantenha sua rotina ativa no periodo de Carnaval.', 'holiday', 'journeys', 2, 55, 'Folia na rota'),
  ('holiday_paixao', 'Sexta de respeito', 'Registre atividade no periodo da Paixao de Cristo.', 'holiday', 'journeys', 1, 40, 'Sexta firme'),
  ('holiday_tiradentes', 'Rota da liberdade', 'Complete entregas no periodo de Tiradentes.', 'holiday', 'deliveries', 10, 60, 'Liberdade na pista'),
  ('holiday_trabalho', 'Dia de quem corre', 'Registre sua rotina no Dia do Trabalho.', 'holiday', 'journeys', 1, 70, 'Trabalho que rende'),
  ('holiday_corpus', 'Ponto de ritmo', 'Some entregas no periodo de Corpus Christi.', 'holiday', 'deliveries', 12, 60, 'Ritmo de feriado'),
  ('holiday_independencia', 'Independencia no caixa', 'Complete entregas no periodo de 7 de setembro.', 'holiday', 'deliveries', 15, 75, 'Independente'),
  ('holiday_aparecida', 'Rota protegida', 'Registre uma jornada no periodo de Nossa Senhora Aparecida.', 'holiday', 'journeys', 1, 45, 'Rota protegida'),
  ('holiday_finados', 'Plantao tranquilo', 'Mantenha a organizacao no periodo de Finados.', 'holiday', 'journeys', 1, 45, 'Plantao tranquilo'),
  ('holiday_republica', 'Republica da entrega', 'Some entregas no periodo da Proclamacao da Republica.', 'holiday', 'deliveries', 12, 60, 'Republica da entrega'),
  ('holiday_consciencia', 'Rota consciente', 'Registre uma jornada no periodo da Consciencia Negra.', 'holiday', 'journeys', 1, 45, 'Rota consciente'),
  ('holiday_natal', 'Natal no placar', 'Complete entregas no periodo de Natal.', 'holiday', 'deliveries', 10, 70, 'Natal no placar')
on conflict (mission_key) do update
set
  title = excluded.title,
  description = excluded.description,
  cadence = excluded.cadence,
  target_metric = excluded.target_metric,
  target_value = excluded.target_value,
  reward_xp = excluded.reward_xp,
  reward_title = excluded.reward_title,
  active = true,
  updated_at = timezone('utc', now());

create or replace function driver.get_driver_level_title(p_level integer)
returns text
language sql
security definer
stable
set search_path = driver, public
as $$
  select coalesce(
    (
      select title
      from driver.driver_titles
      where active = true
        and unlock_type = 'level'
        and required_level <= greatest(coalesce(p_level, 1), 1)
      order by required_level desc
      limit 1
    ),
    'Entregador iniciante'
  );
$$;

grant execute on function driver.get_driver_level_title(integer)
  to authenticated;

create or replace function driver.get_referral_subscription_benefit()
returns jsonb
language plpgsql
security definer
stable
set search_path = driver, auth, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_premium_referrals integer := 0;
  v_free_months integer := 0;
begin
  if v_user_id is null then
    raise exception 'Usuario autenticado obrigatorio.'
      using errcode = '42501';
  end if;

  select count(*)::integer
  into v_premium_referrals
  from driver.driver_referrals r
  join driver.profiles p on p.id = r.referred_user_id
  where r.referrer_user_id = v_user_id
    and p.plan_type in (
      'premium'::driver.plan_type,
      'developer'::driver.plan_type,
      'gift'::driver.plan_type,
      'lifetime'::driver.plan_type
    )
    and p.subscription_status in (
      'active'::driver.subscription_status,
      'gifted'::driver.subscription_status
    );

  v_free_months := v_premium_referrals / 5;

  return jsonb_build_object(
    'premium_referrals', v_premium_referrals,
    'free_months_earned', v_free_months,
    'until_next_free_month',
      case
        when v_premium_referrals = 0 then 5
        when v_premium_referrals % 5 = 0 then 5
        else 5 - (v_premium_referrals % 5)
      end,
    'rule', 'A cada 5 indicados Premium ativos, o entregador ganha 1 mensalidade de beneficio.'
  );
end;
$$;

grant execute on function driver.get_referral_subscription_benefit()
  to authenticated;
