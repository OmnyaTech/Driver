# Checklist Manual de Ambiente e Integracoes

Atualizado em 2026-07-10.

## Conceito importante

Existem dois redirecionamentos diferentes no OAuth:

1. Provider -> Supabase
   Esse callback fica configurado no Google e no Microsoft Entra.
   Para este projeto Supabase, o valor e:

   `https://SEU-PROJETO.supabase.co/auth/v1/callback`

2. Supabase -> App final
   Esse redirect e controlado pelo `redirectTo` enviado pelo app e pela allow
   list em `Authentication > URL Configuration` no Supabase.
   Para o Omnya Driver, o app usa:

   `omnyadriver://auth/callback`

Isso significa que o mesmo projeto Supabase pode atender mais de um app sem
quebrar o OmnyaFinance, desde que:

- o callback do provider continue apontando para o mesmo Supabase;
- os redirects finais de cada app estejam na allow list do Supabase.

## URLs que voce vai usar

### Supabase

- Google provider:
  `https://supabase.com/dashboard/project/SEU_PROJECT_REF/auth/providers?provider=Google`
- Azure provider:
  `https://supabase.com/dashboard/project/SEU_PROJECT_REF/auth/providers?provider=Azure`
- URL Configuration:
  `https://supabase.com/dashboard/project/SEU_PROJECT_REF/auth/url-configuration`
- Edge Functions:
  `https://supabase.com/dashboard/project/SEU_PROJECT_REF/functions`

### Google

- Google Cloud Console:
  `https://console.cloud.google.com/`
- OAuth clients:
  `https://console.cloud.google.com/auth/clients`

### Microsoft

- Azure Portal:
  `https://portal.azure.com/`
- App registrations:
  `https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade`

## O que configurar manualmente

### 1. Supabase URL Configuration

Em `Authentication > URL Configuration`, garanta que a allow list contenha os
redirects finais dos apps.

Adicionar:

- `omnyadriver://auth/callback`

Manter os ja existentes do OmnyaFinance.

Se o OmnyaFinance tambem usa deep link nativo, nao remover:

- `omnyafinance://auth/callback`

Se houver web app do Driver no futuro, adicionar tambem a URL web exata.

## 2. Google Cloud OAuth Client

No cliente OAuth Web usado pelo provider Google do Supabase:

- Authorized redirect URI:
  `https://SEU-PROJETO.supabase.co/auth/v1/callback`

Esse valor nao deve ser trocado para `omnyadriver://auth/callback`.
O deep link do app fica no Supabase, nao no Google.

Se o cliente OAuth atual ja estiver sendo usado pelo OmnyaFinance, voce pode
continuar usando o mesmo cliente se esse callback ja estiver correto.

## 3. Microsoft Entra App Registration

Na app registration usada pelo provider Azure do Supabase:

- Platform type: `Web`
- Redirect URI:
  `https://SEU-PROJETO.supabase.co/auth/v1/callback`

Tambem aqui voce nao substitui por `omnyadriver://auth/callback`.

## 4. Publicar a Edge Function do Turnstile

Arquivo ja preparado no repositorio:

- `supabase/functions/driver-verify-turnstile/index.ts`

Comandos:

```powershell
supabase login
supabase secrets set DRIVER_TURNSTILE_SECRET_KEY="SUA_SECRET_DO_TURNSTILE" --project-ref SEU_PROJECT_REF
supabase functions deploy driver-verify-turnstile --project-ref SEU_PROJECT_REF --no-verify-jwt
```

Observacao:

- a function do Driver tambem consegue usar fallback dos secrets compartilhados
  `CLOUDFLARE_TURNSTILE_SECRET_KEY` e `TURNSTILE_SECRET_KEY`, caso voce prefira
  nao duplicar a secret agora.

## 5. Confirmar providers no Supabase

No painel do Supabase:

- Google: habilitado e salvo
- Azure: habilitado e salvo

## 6. Teste manual minimo

Depois das configuracoes:

1. Testar cadastro por e-mail no Omnya Driver.
2. Testar login por e-mail no Omnya Driver.
3. Testar login Google no Omnya Driver.
4. Testar login Microsoft no Omnya Driver.
5. Confirmar retorno ao app via `omnyadriver://auth/callback`.
6. Confirmar criacao/atualizacao em `driver.profiles`.

## Observacao para teste web local

Para teste em `flutter run -d chrome`, prefira usar porta fixa:

```powershell
flutter run -d chrome --web-port 5173
```

Isso aproveita a URL local ja liberada no Supabase:

- `http://localhost:5173/**`

## 7. SQLs adicionais desta etapa

Executar manualmente no Supabase SQL Editor:

- `sql/manual/006_driver_reporting_and_audit.sql`
- `sql/manual/007_driver_billing_sync.sql`

Esses scripts habilitam:

- auditoria administrativa;
- eventos de billing;
- funcoes RPC de dashboard por periodo;
- funcao RPC de relatorio operacional;
- sincronizacao de assinatura vinda do provedor externo.

## 8. Secrets de billing no Supabase

Configurar no projeto `SEU_PROJECT_REF`:

- `DRIVER_ASAAS_API_KEY`
- `DRIVER_ASAAS_ENV`
- `DRIVER_BILLING_SUCCESS_URL`
- `DRIVER_ASAAS_WEBHOOK_TOKEN`
- `DRIVER_PREMIUM_MONTHLY_PRICE`
- `DRIVER_PREMIUM_YEARLY_PRICE`
- `DRIVER_LIFETIME_PRICE`

Valores esperados:

- `DRIVER_ASAAS_ENV`: `sandbox` ou `production`
- `DRIVER_BILLING_SUCCESS_URL`: URL final de retorno pos-pagamento
- precos: valores numericos, por exemplo `29.90`

## 9. Publicar Edge Functions de billing

Arquivos preparados no repositorio:

- `supabase/functions/driver-create-asaas-checkout/index.ts`
- `supabase/functions/driver-asaas-webhook/index.ts`

Comandos:

```powershell
supabase functions deploy driver-create-asaas-checkout --project-ref SEU_PROJECT_REF --no-verify-jwt
supabase functions deploy driver-asaas-webhook --project-ref SEU_PROJECT_REF --no-verify-jwt
```

## 10. Configurar webhook no Asaas

Cadastrar o endpoint:

- `https://SEU-PROJETO.supabase.co/functions/v1/driver-asaas-webhook`

Se usar token de seguranca no webhook, ele deve ser o mesmo valor salvo em:

- `DRIVER_ASAAS_WEBHOOK_TOKEN`

Eventos minimos recomendados:

- criacao e atualizacao de assinatura;
- criacao, confirmacao, recebimento e vencimento de pagamento;
- cancelamento ou inativacao.

## 11. Validacao manual desta etapa

Depois de publicar tudo:

1. Abrir a tela `Planos` no app.
2. Gerar checkout de teste para `premium mensal`.
3. Confirmar criacao de evento em `driver.billing_events`.
4. Simular ou receber webhook do Asaas.
5. Confirmar atualizacao de `driver.profiles`.
6. Confirmar historico em `driver.subscriptions`.
7. Abrir `Relatorios` e validar filtro por periodo.
8. Abrir a area developer e validar a lista de auditoria.

## O que nao fazer

- nao trocar o callback do provider para `omnyadriver://auth/callback`;
- nao remover redirects do OmnyaFinance da allow list do Supabase;
- nao alterar tabelas ou policies do dominio atual do OmnyaFinance;
- nao publicar functions do Driver sem identificacao do projeto.
