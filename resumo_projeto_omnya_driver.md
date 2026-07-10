# Omnya Driver - Produto Esperado

Atualizado em 2026-07-10.

Este arquivo descreve o que o Omnya Driver deve ter quando estiver pronto,
conforme as solicitacoes consolidadas do projeto. Ele nao e um diario do estado
atual; ele e um mapa do produto-alvo.

## Objetivo do produto

O Omnya Driver deve ser um app Flutter para motofretistas e entregadores
registrarem operacao diaria, calcularem lucro real, acompanharem veiculos,
fontes de renda e acesso contratado, tudo isolado tecnicamente no dominio
`driver` do Supabase.

## Estrutura principal de telas

### 1. Autenticacao

- Login por e-mail e senha.
- Cadastro real com Supabase Auth.
- Login social Google.
- Login social Microsoft.
- Captcha Turnstile no login, cadastro e OAuth.
- Deep link de retorno para mobile e web.

### 2. Onboarding inicial

- Etapa de perfil:
  - nome exibido;
  - nome completo;
  - telefone.
- Etapa de primeiro veiculo:
  - marca;
  - modelo;
  - ano;
  - placa;
  - combustivel;
  - consumo medio.
- Etapa de primeira plataforma:
  - nome;
  - tipo;
  - media diaria de ganhos;
  - media diaria de entregas.

### 3. Dashboard / Home

- resumo da conta atual:
  - nome;
  - e-mail;
  - plano;
  - papel;
  - status do onboarding.
- metricas consolidadas:
  - receita total;
  - custos operacionais;
  - resultado liquido;
  - total de jornadas;
  - jornadas em aberto;
  - total de entregas;
  - distancia medida;
  - custo por km;
  - ticket medio por entrega;
  - media de receita por jornada.
- leituras rapidas do negocio:
  - veiculos ativos;
  - plataformas ativas;
  - quantidade de abastecimentos;
  - quantidade de manutencoes;
  - quantidade de despesas.
- filtros por periodo:
  - hoje;
  - semana;
  - mes;
  - intervalo customizado.

### 4. Relatorios

- tela dedicada de relatorios operacionais;
- filtros por periodo;
- consolidacao de:
  - receita;
  - custos;
  - resultado liquido;
  - jornadas;
  - entregas;
  - distancia;
- ranking de plataformas;
- quebra de custos por categoria;
- preparacao para exportacao futura.

### 5. Jornadas

- listar jornadas abertas e finalizadas;
- criar jornada manual, rapida ou automatica;
- vincular veiculo opcionalmente;
- registrar:
  - inicio;
  - fim opcional;
  - km inicial;
  - km final;
  - observacoes.
- vincular uma ou varias plataformas na jornada;
- registrar por plataforma:
  - receita;
  - entregas.
- mostrar detalhamento por plataforma dentro da jornada.

### 6. Despesas de percurso

- listar despesas por data;
- criar despesa com:
  - tipo;
  - valor;
  - descricao;
  - data/hora;
  - vinculo opcional de jornada.
- consolidar total gasto no modulo.

### 7. Abastecimentos

- listar abastecimentos por data;
- criar abastecimento com:
  - veiculo;
  - jornada opcional;
  - data/hora;
  - km atual;
  - posto;
  - combustivel;
  - litros;
  - valor por litro;
  - valor total.
- mostrar historico por veiculo e custo acumulado.

### 8. Manutencoes

- listar manutencoes por data;
- criar manutencao com:
  - veiculo;
  - data;
  - oficina;
  - motivo;
  - descricao;
  - valor total.
- permitir itens opcionais da manutencao:
  - descricao;
  - valor.
- mostrar expansao com itens detalhados.

### 9. Veiculos

- listar veiculos ativos e arquivados;
- criar veiculo;
- arquivar veiculo;
- aplicar regra de plano:
  - free com limite reduzido;
  - premium/gift/lifetime/developer com expansao.

### 10. Plataformas

- listar plataformas ativas e arquivadas;
- criar plataforma;
- arquivar plataforma;
- aplicar regra de plano:
  - free com limite reduzido;
  - premium/gift/lifetime/developer com expansao.

### 11. Assinaturas e acesso

- tela de planos e assinatura;
- contratacao real com provedor externo;
- historico de assinaturas;
- historico de eventos de billing;
- estados esperados:
  - free;
  - active;
  - gifted;
  - overdue;
  - canceled;
- suporte a:
  - premium mensal;
  - premium anual;
  - lifetime;
  - gift;
  - developer.

### 12. Area Developer / Administrativa

- visivel apenas para usuarios com papel `developer`;
- consultar usuario por e-mail;
- visualizar:
  - plano;
  - papel;
  - status da assinatura;
  - status do onboarding.
- conceder acesso manual:
  - free;
  - premium;
  - gift;
  - lifetime;
  - developer.
- alterar papel:
  - user;
  - developer.
- definir expiracao opcional de acesso;
- visualizar historico da propria conta administrativa;
- visualizar auditoria administrativa:
  - quem alterou;
  - quem recebeu a alteracao;
  - qual acao foi executada;
  - quando ocorreu;
  - metadata da operacao.

## Funcoes de negocio esperadas

### Autenticacao e seguranca

- usar Supabase Auth compartilhando apenas `auth.users`;
- isolar todo o dominio do app no schema `driver`;
- endurecer login social com Edge Function de validacao Turnstile;
- suportar callbacks web e mobile.

### Dados operacionais

- registrar operacao diaria do motorista;
- consolidar ganhos por plataforma;
- consolidar custos por jornada, abastecimento e manutencao;
- permitir leitura simples de lucro e produtividade;
- filtrar metricas e relatorios por periodo;
- manter dashboard e relatorios apoiados por functions/views no Supabase.

### Planos, assinatura e presentes

- suportar planos:
  - free;
  - premium;
  - gift;
  - lifetime;
  - developer.
- refletir o plano no perfil do usuario;
- manter historico em `driver.subscriptions`;
- manter eventos do provedor em `driver.billing_events`;
- permitir concessao manual de presente/acesso por developer;
- permitir bootstrap manual do primeiro developer.

## Estrutura de backend esperada

### Supabase

- schema `driver` com tabelas:
  - `profiles`;
  - `vehicles`;
  - `platforms`;
  - `journeys`;
  - `journey_platforms`;
  - `trip_expenses`;
  - `fuelings`;
- `maintenances`;
- `maintenance_items`;
- `goals`;
- `goal_transactions`;
- `subscriptions`;
- `billing_events`;
- `developer_audit_logs`.
- RLS por usuario;
- funcoes seguras para operacoes administrativas de developer;
- funcoes seguras para checkout, sincronizacao e auditoria;
- functions/views para metricas e relatorios;
- trigger para bootstrap automatico de `driver.profiles`.

### Edge Functions

- validacao de Turnstile para OAuth;
- checkout de assinatura com provedor externo;
- webhook de billing para sincronizacao de status;
- futuras automacoes administrativas e financeiras.

## Organizacao esperada do codigo

- `lib/login/`
  autenticacao e captcha.
- `lib/funcionalidade/onboarding/`
  entrada inicial do usuario.
- `lib/dashboard/`
  home, metricas e shell principal.
- `lib/funcionalidade/reports/`
  relatorios operacionais.
- `lib/funcionalidade/journeys/`
  modulo de jornadas.
- `lib/funcionalidade/expenses/`
  modulo de despesas.
- `lib/funcionalidade/fuelings/`
  modulo de abastecimentos.
- `lib/funcionalidade/maintenances/`
  modulo de manutencoes.
- `lib/funcionalidade/vehicles/`
  modulo de veiculos.
- `lib/funcionalidade/platforms/`
  modulo de plataformas.
- `lib/funcionalidade/developer/`
  area administrativa.
- `lib/funcionalidade/subscriptions/`
  planos, checkout e historico de billing.
- `lib/services/`
  integracao com Supabase e regras de negocio.
- `sql/manual/`
  scripts de banco para execucao manual no SQL Editor.
- `docs/engineering/`
  mapeamento vivo da engenharia.

## Regra estrutural permanente

Tudo que for Omnya Driver deve permanecer identificado e isolado:

- banco em `driver.*`;
- Edge Functions do Driver identificadas;
- SQL manual versionado;
- documentacao `.md` mantendo arquitetura, mapa e estado atual do sistema.
