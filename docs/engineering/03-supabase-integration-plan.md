# Plano de Integracao com Supabase

## Principio

O Omnya Driver compartilhara a infraestrutura do projeto Supabase do
OmnyaFinance, mas sem alterar o dominio existente em producao.

## O que pode ser compartilhado

- `auth.users`
- configuracoes de Auth
- captcha/Attack Protection
- buckets novos dedicados ao Driver
- Edge Functions novas com prefixo `driver-`

## O que nao pode ser alterado

- tabelas atuais do OmnyaFinance;
- policies atuais do OmnyaFinance;
- Edge Functions atuais do OmnyaFinance;
- buckets atuais do OmnyaFinance;
- triggers e functions SQL do Finance.

## Schema alvo

Todos os objetos do Driver devem nascer em:

`driver.*`

## Tabelas da fundacao inicial

- `driver.profiles`
- `driver.vehicles`
- `driver.platforms`
- `driver.journeys`
- `driver.journey_platforms`
- `driver.trip_expenses`
- `driver.fuelings`
- `driver.maintenances`
- `driver.maintenance_items`
- `driver.goals`
- `driver.goal_transactions`
- `driver.subscriptions`

## Estado da integracao

- schema `driver` aplicado com sucesso no SQL Editor;
- app inicializa com o projeto Supabase real;
- login e cadastro por e-mail usam Supabase Auth com captcha;
- login social Google e Microsoft esta integrado no cliente;
- apos login, o app faz upsert seguro do registro em `driver.profiles`;
- leitura do perfil do motorista ja acontece no cliente;
- onboarding grava perfil e marca conclusao em `driver.profiles`;
- veiculos e plataformas ja gravam no schema `driver`.

## Proxima etapa de backend

- publicar a Edge Function `driver-verify-turnstile`;
- preferir secrets com prefixo `DRIVER_`, com fallback para os secrets ja
  existentes do projeto compartilhado;
- habilitar/validar os providers Google e Azure no painel Auth do Supabase;
- definir Edge Functions do Driver para presentes, assinatura e metricas;
- implementar resolucao de plano efetivo no dominio `driver`.

## Estrategia de seguranca

- RLS habilitado em todas as tabelas do Driver.
- Leitura e escrita do proprio usuario somente nas tabelas de dominio.
- Acesso administrativo real deve passar por service role em Edge Functions.
- Nao liberar leitura ampla de dados de usuarios para o papel developer no
  client.

## Execucao manual

Os scripts em `sql/manual/` devem ser aplicados por voce manualmente no
SQL Editor do Supabase, em ambiente controlado.
