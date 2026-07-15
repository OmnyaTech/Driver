# Driver

Aplicativo Flutter da OmnyaTech para controle de jornadas, ganhos, despesas,
veiculos, objetivos e evolucao de entregadores e motofretistas.

## Publicacao segura

Este repositorio foi preparado para ficar publico. Nenhum secret operacional,
token privado, chave administrativa ou configuracao de release deve ser
versionado aqui.

Configuracoes de ambiente devem ser passadas em tempo de build, usando
`--dart-define`.

Exemplo:

```powershell
flutter run -d chrome --web-port 5173 `
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=SUA_PUBLISHABLE_KEY `
  --dart-define=TURNSTILE_SITE_KEY=SUA_TURNSTILE_SITE_KEY
```

Para builds Android:

```powershell
flutter build apk `
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=SUA_PUBLISHABLE_KEY `
  --dart-define=TURNSTILE_SITE_KEY=SUA_TURNSTILE_SITE_KEY
```

## Estado atual

- App Flutter instalavel chamado **Driver**, produto da OmnyaTech.
- Supabase Auth compartilhado, com dados do app isolados no schema `driver`.
- Login por e-mail, Google e Microsoft com Turnstile; no APK, o captcha roda
  internamente/invisivel, mantendo a exigencia ativa para a web.
- Onboarding com telefone formatado por pais, regiao selecionavel para Brasil
  e cidades de Goias, reserva automatica flexivel, primeiro veiculo e primeira
  plataforma.
- Veiculos com tipo selecionavel, marca/modelo digitaveis com sugestoes,
  combustivel multi-selecao e fallback para dados legados.
- Dashboard, jornadas, despesas, abastecimentos, manutencoes, objetivos,
  relatorios, assinaturas, comunidade, seguranca e area developer em operacao.
- Objetivos financeiros com aporte, retirada, saque com observacao opcional e
  historico de movimentacoes.
- Plano free com ate 3 plataformas ativas; premium e acessos expandidos com
  plataformas ilimitadas.
- SQLs manuais versionados em `sql/manual`, incluindo o `042` para saques em
  objetivos e historico tipado de movimentacoes.
- Templates de e-mail Supabase Auth padronizados em
  `docs/supabase_auth_email_templates_omnyatech.md`.

## Pastas principais

- `lib/`: app Flutter.
- `docs/engineering/`: mapeamento tecnico vivo do sistema.
- `sql/manual/`: scripts SQL para execucao manual.
- `Planejamento/`: documentacao funcional e de produto.
- `src/`: referencias visuais e branding.

## Diretriz arquitetural

- Nao alterar tabelas, funcoes ou policies do OmnyaFinance.
- Todo objeto novo do banco pertence ao schema `driver`.
- Auth continua compartilhado por `auth.users`.
- Fluxos administrativos, presentes e assinaturas devem seguir a mesma logica
  madura do OmnyaFinance, mas isolados para o Omnya Driver.

## Configuracao de billing

As integracoes de billing do Asaas usam Edge Functions e secrets do Supabase.
Os nomes esperados dos secrets estao documentados em:

- `docs/engineering/04-manual-setup-checklist.md`
