# Omnya Driver

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

- Projeto Flutter inicial criado.
- Arquitetura base montada a partir do padrao de organizacao do `ciacat`.
- Base de autenticacao, perfis, papeis e planos desenhada para o mesmo projeto
  Supabase do OmnyaFinance, em schema isolado `driver`.
- Integracao real com Supabase inicializada com login por e-mail.
- Bootstrap automatico de `driver.profiles` apos autenticacao.
- SQL inicial preparado para execucao manual no SQL Editor.
- Documentacao viva criada em `docs/engineering`.

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
