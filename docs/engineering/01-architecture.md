# Arquitetura Base

## Referencias adotadas

- Organizacao Flutter baseada no estilo do `B:\Projeto Cia\Frontend\ciacat`.
- Regras de autenticacao, captcha, developer access, assinatura e gifts
  inspiradas no `B:\OmnyaTech Project's\omnyafinance`.

## Estrutura do app

`lib/config`

- bootstrap da aplicacao;
- configuracao do Supabase;
- tema;
- roteamento.

`lib/login`

- entrada de autenticacao;
- login e cadastro reais ligados;
- Google e Microsoft ligados no app;
- Turnstile acoplado aos fluxos de auth.

`lib/dashboard`

- area inicial apos autenticacao;
- container dos modulos do MVP;
- shell atual com visao geral, jornadas, despesas, abastecimentos,
  manutencoes, veiculos e plataformas.

`lib/funcionalidade/onboarding`

- onboarding em 3 passos;
- perfil do motorista;
- primeiro veiculo;
- primeira plataforma.

`lib/funcionalidade/vehicles`

- listagem;
- criacao;
- arquivamento.

`lib/funcionalidade/platforms`

- listagem;
- criacao;
- arquivamento.

`lib/funcionalidade/journeys`

- listagem;
- criacao inicial;
- receita por plataforma.

`lib/funcionalidade/expenses`

- listagem;
- criacao de despesas de percurso;
- vinculacao opcional a jornada.

`lib/funcionalidade/fuelings`

- listagem;
- criacao de abastecimentos;
- vinculacao opcional a jornada.

`lib/funcionalidade/maintenances`

- listagem;
- criacao de manutencoes;
- itens opcionais por manutencao.

`lib/funcionalidade`

- notas e modulos do dominio;
- auth, developer, journeys e subscriptions.

`lib/models`

- tipos de dominio compartilhados.

`lib/services`

- integracao com backend e regras centrais de acesso.

`lib/utilities`

- estado de sessao e guards.

`lib/utils`

- utilitarios leves e logging.

## Estrategia de autenticacao

- Supabase Auth como provedor principal.
- Login por e-mail ja ligado.
- Cadastro real com e-mail e senha ligado.
- Google e Microsoft ligados no cliente com redirect PKCE.
- Captcha Cloudflare Turnstile seguindo a mesma filosofia do OmnyaFinance:
  visual no web e invisivel/tecnico no mobile.
- Perfil do app persistido em `driver.profiles`.
- `driver.profiles` e bootstrapado automaticamente apos login valido.
- Onboarding concluido marca `driver.profiles.onboarding_completed_at`.

## Estrategia de autorizacao

- papel do usuario em `driver.profiles.role`;
- plano em `driver.profiles.plan_type`;
- acesso efetivo resolvido com suporte a `free`, `premium`, `gift`,
  `lifetime` e `developer`;
- a camada cliente apenas consome o acesso efetivo, sem ser a fonte de
  verdade para privilegios.

## Estrategia de documentacao viva

Cada mudanca estrutural relevante deve atualizar:

- `docs/engineering/00-current-system-state.md`;
- `docs/engineering/01-architecture.md`;
- `docs/engineering/02-file-map.md`;
- `docs/engineering/03-supabase-integration-plan.md`.
- `docs/engineering/04-manual-setup-checklist.md`.
