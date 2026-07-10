# Mapa de Arquivos

Atualizado em 2026-07-10.

## Flutter app

- `lib/app.dart`
  Decide entre login, onboarding e dashboard.

- `lib/dashboard/dashboard_screen.dart`
  Shell principal do app, home com metricas filtraveis e abas operacionais.

- `lib/login/login_screen.dart`
  Tela de login, cadastro e login social.

- `lib/funcionalidade/onboarding/onboarding_screen.dart`
  Onboarding em etapas do motorista.

- `lib/funcionalidade/journeys/journeys_screen.dart`
  Jornadas com formulario real e breakdown por plataforma.

- `lib/funcionalidade/expenses/trip_expenses_screen.dart`
  Despesas operacionais com vinculacao opcional de jornada.

- `lib/funcionalidade/fuelings/fuelings_screen.dart`
  Abastecimentos por veiculo com vinculacao opcional de jornada.

- `lib/funcionalidade/maintenances/maintenances_screen.dart`
  Manutencoes com itens opcionais e custo total.

- `lib/funcionalidade/vehicles/vehicles_screen.dart`
  Gestao de veiculos com limite de plano.

- `lib/funcionalidade/platforms/platforms_screen.dart`
  Gestao de plataformas com limite de plano.

- `lib/funcionalidade/developer/developer_access_screen.dart`
  Area administrativa para developer com auditoria.

- `lib/funcionalidade/reports/reports_screen.dart`
  Relatorios operacionais com filtro por periodo.

- `lib/funcionalidade/subscriptions/subscriptions_screen.dart`
  Tela de planos, checkout e historico de billing.

## Models

- `lib/models/app_profile.dart`
  Perfil autenticado e estado de onboarding.

- `lib/models/app_journey.dart`
  Jornada, distancia e breakdown por plataforma.

- `lib/models/app_trip_expense.dart`
  Despesa operacional.

- `lib/models/app_fueling.dart`
  Abastecimento.

- `lib/models/app_maintenance.dart`
  Manutencao e itens.

- `lib/models/app_dashboard_metrics.dart`
  Agregados operacionais do dashboard.

- `lib/models/app_subscription.dart`
  Historico de assinatura e consulta administrativa.

- `lib/models/app_operational_report.dart`
  Estrutura do relatorio operacional consolidado.

- `lib/models/app_admin_audit_log.dart`
  Evento de auditoria administrativa.

- `lib/models/app_billing_checkout.dart`
  Resposta de abertura de checkout externo.

## Services

- `lib/services/auth_service.dart`
  Auth, OAuth, Turnstile e bootstrap do perfil.

- `lib/services/profile_service.dart`
  Atualizacao de perfil e onboarding.

- `lib/services/journey_service.dart`
  CRUD inicial e consolidacao de jornadas.

- `lib/services/trip_expense_service.dart`
  CRUD inicial de despesas.

- `lib/services/fueling_service.dart`
  CRUD inicial de abastecimentos.

- `lib/services/maintenance_service.dart`
  CRUD inicial de manutencoes.

- `lib/services/vehicle_service.dart`
  CRUD inicial de veiculos.

- `lib/services/platform_service.dart`
  CRUD inicial de plataformas.

- `lib/services/dashboard_metrics_service.dart`
  Carrega metricas do dashboard via RPC no Supabase com fallback local.

- `lib/services/subscription_service.dart`
  Le historico de assinaturas do usuario atual.

- `lib/services/reporting_service.dart`
  Consome RPC de relatorio operacional por periodo.

- `lib/services/billing_service.dart`
  Abre checkout de assinatura e le eventos de billing.

- `lib/services/developer_admin_service.dart`
  Consome RPCs administrativas do schema `driver`, incluindo auditoria.

- `lib/services/plan_access_service.dart`
  Regras simples de acesso por plano.

- `lib/services/developer_access_service.dart`
  Regras de abertura da area developer.

## SQL manual

- `sql/manual/001_driver_schema_foundation.sql`
- `sql/manual/002_driver_profile_bootstrap_trigger.sql`
- `sql/manual/003_driver_schema_api_grants.sql`
- `sql/manual/004_driver_admin_access_functions.sql`
- `sql/manual/005_driver_promote_first_developer.sql`
- `sql/manual/006_driver_reporting_and_audit.sql`
- `sql/manual/007_driver_billing_sync.sql`

## Documentacao viva

- `docs/engineering/00-current-system-state.md`
  Estado implementado de hoje.

- `docs/engineering/01-architecture.md`
  Estrutura arquitetural do projeto.

- `docs/engineering/03-supabase-integration-plan.md`
  Fronteira do Supabase e regras do schema `driver`.

- `docs/engineering/04-manual-setup-checklist.md`
  Passos manuais de ambiente, OAuth, Data API, billing e Supabase.
