# Estado Atual do Sistema

Atualizado em 2026-07-10.

## Visao geral

O Omnya Driver ja opera com:

- Flutter como client principal;
- Supabase Auth real com onboarding real;
- schema isolado `driver` no mesmo projeto Supabase;
- Turnstile endurecendo login, cadastro e OAuth;
- dashboard autenticado com modulos operacionais;
- relatorios com filtro por periodo;
- preparacao para billing real via Asaas;
- auditoria administrativa para a area developer;
- documentacao viva em `docs/engineering/`.

## Ja implementado

- login e cadastro por e-mail;
- login social Google e Microsoft;
- Turnstile no fluxo de auth;
- onboarding em 3 etapas:
  - perfil;
  - primeiro veiculo;
  - primeira plataforma;
- criacao e listagem de jornadas;
- criacao e listagem de despesas de percurso;
- criacao e listagem de abastecimentos;
- criacao e listagem de manutencoes com itens;
- modulo de objetivos com:
  - criacao;
  - edicao;
  - exclusao;
  - aporte;
  - retirada;
  - historico de movimentacoes;
  - saldo disponivel baseado no resultado operacional;
- criacao e listagem de veiculos;
- criacao e listagem de plataformas;
- jornadas com detalhamento por plataforma e validacoes melhores;
- dashboard com metricas consolidadas em cima dos dados reais;
- dashboard com filtro por periodo;
- relatorios operacionais via RPC no Supabase;
- tela de assinaturas com checkout externo e historico de eventos;
- area developer no app para:
  - consultar usuario por e-mail;
  - aplicar plano/papel manualmente;
  - visualizar historico da conta atual;
  - visualizar auditoria administrativa;
- regras basicas de plano para limitar multiplos veiculos/plataformas no free.

## SQL manual disponivel

- `sql/manual/001_driver_schema_foundation.sql`
  Fundacao do schema `driver`, tabelas e policies.

- `sql/manual/002_driver_profile_bootstrap_trigger.sql`
  Trigger de bootstrap de `driver.profiles` a partir de `auth.users`.

- `sql/manual/003_driver_schema_api_grants.sql`
  Grants e default privileges para Data API.

- `sql/manual/004_driver_admin_access_functions.sql`
  Functions seguras para lookup administrativo e concessao manual de acesso.

- `sql/manual/005_driver_promote_first_developer.sql`
  Atalho manual para promover o primeiro developer do ambiente.

- `sql/manual/006_driver_reporting_and_audit.sql`
  Audit log administrativo e funcoes de relatorio/metricas no banco.

- `sql/manual/007_driver_billing_sync.sql`
  Funcoes de sincronizacao de billing, assinatura e eventos.

- `sql/manual/008_driver_goal_balance_functions.sql`
  Functions seguras para saldo disponivel e movimentacoes de objetivos.

## Edge Functions disponiveis

- `supabase/functions/driver-verify-turnstile`
  Validacao de token Turnstile para endurecimento do OAuth.

- `supabase/functions/driver-create-asaas-checkout`
  Abre checkout real de assinatura via Asaas e registra evento inicial.

- `supabase/functions/driver-asaas-webhook`
  Recebe webhook do Asaas e sincroniza o estado da assinatura no schema `driver`.

## Dependencias manuais ainda existentes

- publicar as Edge Functions novas do Driver;
- configurar secrets do Asaas no Supabase;
- configurar webhook do Asaas apontando para a function do Driver;
- executar os SQLs `006_driver_reporting_and_audit.sql` e
  `007_driver_billing_sync.sql` em cada ambiente;
- validar checkout, webhook e sincronizacao de plano real.

## Proximo foco tecnico recomendado

- fechar teste ponta a ponta do billing real no ambiente Supabase;
- evoluir relatorios com exportacao e filtros adicionais;
- ampliar dashboard com comparativos entre periodos;
- expandir a area developer com mais acoes administrativas auditadas.
