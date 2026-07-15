# Estado Atual do Sistema

Atualizado em 2026-07-15.

## Visao geral

O Driver, produto da OmnyaTech, ja opera com:

- Flutter como client principal;
- Supabase Auth real com onboarding real;
- schema isolado `driver` no mesmo projeto Supabase;
- Turnstile endurecendo login, cadastro e OAuth;
- captcha invisivel no APK e visivel na web;
- dashboard autenticado com modulos operacionais;
- relatorios com filtro por periodo;
- preparacao para billing real via Asaas;
- auditoria administrativa para a area developer;
- documentacao viva em `docs/engineering/`.

## Ja implementado

- login e cadastro por e-mail;
- login social Google e Microsoft;
- Turnstile no fluxo de auth;
- onboarding em 5 etapas:
  - perfil;
  - regiao;
  - preferencias;
  - primeiro veiculo;
  - primeira plataforma;
- telefone formatado por pais, salvando o numero nacional sem DDI;
- regiao selecionavel para Brasil, com estados brasileiros e cidades de Goias;
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
  - saque com observacao opcional;
  - historico de movimentacoes;
  - saldo disponivel baseado no resultado operacional;
- criacao e listagem de veiculos com tipo, marca/modelo sugeridos e
  combustivel multi-selecao;
- criacao e listagem de plataformas, com 3 plataformas ativas no free e
  plataformas ilimitadas nos planos expandidos;
- jornadas com detalhamento por plataforma e validacoes melhores;
- dashboard com metricas consolidadas em cima dos dados reais;
- dashboard com filtro por periodo;
- tooltip explicativo no grafico "Como o dinheiro entrou";
- relatorios operacionais via RPC no Supabase;
- tela de assinaturas com checkout externo e historico de eventos;
- area developer no app para:
  - consultar usuario por e-mail;
  - aplicar plano/papel manualmente;
  - visualizar historico da conta atual;
  - visualizar auditoria administrativa;
- regras basicas de plano para limitar multiplos veiculos e liberar ate 3
  plataformas ativas no free.
- metricas developer de assinantes pagantes excluem gift e developer.
- MFA/TOTP exibe os digitos digitados e permite colar codigo numerico.
- reserva automatica suporta sem reserva, percentual por entrega, valor por
  entrega, percentual por dia, por semana e por mes.
- vitrine de conquistas exibe contador junto ao titulo.
- landing publica web em `driver.omnyatech.com.br`, com rota de convite,
  cadastro antes do download e link MediaFire configuravel pela secret
  `DRIVER_MEDIAFIRE_APK_URL`.
- convites usam a folha nativa de compartilhamento do celular em vez de apenas
  copiar para a area de transferencia.
- bucket publico `driver-mobile-releases` reservado para APKs oficiais do
  Driver.

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

- `sql/manual/037_driver_onboarding_vehicle_metrics_refinements.sql`
  Adiciona `vehicle_type`, `fuel_types` e corrige metricas de assinantes pagos.

- `sql/manual/042_driver_goal_cash_out_transactions.sql`
  Adiciona tipo/observacao em movimentacoes de objetivos e atualiza a RPC para
  registrar saques.

- `sql/manual/043_driver_mobile_releases_storage.sql`
  Cria bucket publico `driver-mobile-releases` para APKs oficiais do Driver.

## Documentacao operacional adicional

- `docs/supabase_auth_email_templates_omnyatech.md`
  Assuntos e HTML para padronizar e-mails Supabase Auth como OmnyaTech.

- `docs/omnya_driver_system_overview.md`
  Visao funcional detalhada do sistema, telas, finalidade e funcionamento.

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
- executar os SQLs manuais pendentes em cada ambiente, incluindo o `037` antes
  de usar os novos campos de veiculo em producao;
- validar checkout, webhook e sincronizacao de plano real.
- `flutter test` pode falhar quando o workspace esta em um caminho com
  apostrofo, como `OmnyaTech Project's`, por erro do listener gerado pelo
  Flutter. `flutter analyze` segue funcionando nesse caminho.

## Proximo foco tecnico recomendado

- fechar teste ponta a ponta do billing real no ambiente Supabase;
- evoluir relatorios com exportacao e filtros adicionais;
- ampliar dashboard com comparativos entre periodos;
- expandir a area developer com mais acoes administrativas auditadas.
