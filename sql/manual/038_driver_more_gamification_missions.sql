-- Omnya Driver
-- More gamification missions for the Driver growth system.
-- Date: 2026-07-14
-- Execute manually in Supabase SQL Editor after sql/manual/037_driver_onboarding_vehicle_metrics_refinements.sql.

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
  ('daily_first_route', 'Primeira rota do dia', 'Registre 1 jornada para tirar o dia do zero.', 'daily', 'journeys', 1, 15, 'Dia iniciado'),
  ('daily_delivery_5', 'Cinco entregas no bolso', 'Some 5 entregas e mantenha o painel vivo.', 'daily', 'deliveries', 5, 20, 'Ritmo ligado'),
  ('daily_delivery_10', 'Dez entregas de respeito', 'Some 10 entregas no dia e ganhe XP extra.', 'daily', 'deliveries', 10, 35, 'Dezena forte'),
  ('weekly_5_journeys', 'Semana consistente', 'Registre 5 jornadas para provar constancia.', 'weekly', 'journeys', 5, 55, 'Constancia'),
  ('weekly_50_deliveries', 'Semana de volume', 'Some 50 entregas e avance no ranking.', 'weekly', 'deliveries', 50, 80, 'Volume alto'),
  ('weekly_100_deliveries', 'Cem na semana', 'Some 100 entregas para liberar uma missao pesada.', 'weekly', 'deliveries', 100, 140, 'Cem entregas'),
  ('monthly_12_journeys', 'Mes no trilho', 'Registre 12 jornadas no mes e mantenha historico forte.', 'monthly', 'journeys', 12, 90, 'Mes no trilho'),
  ('monthly_200_deliveries', 'Duzentas entregas', 'Some 200 entregas no mes para ganhar destaque.', 'monthly', 'deliveries', 200, 180, 'Duzentas entregas'),
  ('goals_3_created', 'Tres destinos para o dinheiro', 'Crie ou acompanhe 3 metas para organizar suas reservas.', 'unique', 'goals', 3, 70, 'Organizador'),
  ('goals_5_created', 'Planejamento de verdade', 'Use 5 metas para separar melhor o que entra.', 'unique', 'goals', 5, 110, 'Planejador forte'),
  ('referral_3_partners', 'Rede de parceiros', 'Convide 3 motoristas e aumente sua presenca na comunidade.', 'unique', 'referrals', 3, 120, 'Rede ativa'),
  ('referral_10_partners', 'Embaixador de rota', 'Convide 10 motoristas para liberar um titulo especial.', 'unique', 'referrals', 10, 250, 'Embaixador de rota')
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
