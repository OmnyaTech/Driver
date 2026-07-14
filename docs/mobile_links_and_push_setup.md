# Mobile links and push setup

## Convites abrindo o app

O app ja escuta links nos formatos:

- `https://driver.omnyatech.com.br/?ref=slug`
- `https://driver.omnyatech.com.br/convite/slug`
- `https://driver.omnyatech.com.br/@slug`
- `omnyadriver://invite/slug`

Para Android App Links funcionar em producao, publique `web/.well-known/assetlinks.json` com o SHA-256 real da chave release ou Play App Signing. O arquivo atual tem um placeholder.

Para iOS Universal Links funcionar em producao, publique `web/.well-known/apple-app-site-association` com o Team ID real da Apple. O arquivo atual tem um placeholder.

## Push notification real

O app registra o token do aparelho em `driver.driver_push_devices` quando Firebase esta configurado.

O Android esta preparado para aplicar o plugin `com.google.gms.google-services`
automaticamente quando `android/app/google-services.json` existir. Sem esse
arquivo, o APK continua abrindo, mas o Firebase Messaging nao gera token FCM e
notificacoes com o app fechado nao chegam ao aparelho.

Checklist gratuito para ativar envio real no Android:

1. No Firebase Console, crie ou abra um projeto gratuito da OmnyaTech.
2. Adicione um app Android com package name `br.com.omnyatech.omnyadriver`.
3. Baixe o arquivo `google-services.json`.
4. Coloque esse arquivo em `android/app/google-services.json`.
5. Gere um novo APK release para registrar o token FCM corretamente.
6. No Supabase, faca deploy da Edge Function `driver-send-push`.
7. Configure os secrets da Edge Function:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `DRIVER_PUSH_SECRET`
   - Preferencial: `DRIVER_FIREBASE_PROJECT_ID` e
     `DRIVER_FIREBASE_SERVICE_ACCOUNT_JSON`
   - Alternativa legada: `DRIVER_FCM_SERVER_KEY` ou `FCM_SERVER_KEY`
8. Execute o SQL manual `028_driver_push_cron.sql` trocando os placeholders:
   - `<SUPABASE_SERVICE_ROLE_KEY>`
   - `<DRIVER_PUSH_SERVICE_SECRET>`
9. Abra o app, faca login e confira se a tabela `driver.driver_push_devices`
   recebeu um registro Android com `fcm_token` preenchido.
10. Confira se `driver.driver_push_jobs` sai de `queued` para `sent` depois do
    cron chamar a Edge Function.

Para gerar `DRIVER_FIREBASE_SERVICE_ACCOUNT_JSON` sem custo:

1. No Firebase/Google Cloud Console, abra o projeto.
2. Va em Project settings > Service accounts.
3. Gere uma nova chave privada.
4. Copie o JSON inteiro para o secret `DRIVER_FIREBASE_SERVICE_ACCOUNT_JSON`.
5. Use o `project_id` desse JSON em `DRIVER_FIREBASE_PROJECT_ID`.

Enquanto o app estiver aberto ou em segundo plano com o processo vivo, avisos
novos tambem sao exibidos como notificacao local do aparelho. Com o app fechado,
o envio depende obrigatoriamente de FCM + Edge Function + cron.

## MFA / 2FA

O app usa Supabase TOTP MFA. O fluxo correto e:

1. O usuario toca em configurar 2FA.
2. O app pede confirmacao do autenticador atual se o Supabase responder
   `insufficient_aal`.
3. Depois da confirmacao, o app mostra QR Code e chave manual.
4. O usuario cadastra no Google Authenticator, Microsoft Authenticator,
   Authy ou equivalente.
5. O app so marca `totp_mfa_enabled` depois que o primeiro codigo e validado.

Se o usuario perdeu acesso ao autenticador antigo e o Supabase exige AAL2 para
alterar MFA, a recuperacao precisa ser administrativa no Supabase:

1. Acesse Authentication > Users.
2. Abra o usuario afetado.
3. Remova/desabilite os fatores MFA TOTP antigos desse usuario.
4. No banco, garanta que `driver.profiles.totp_mfa_enabled = false` para esse
   usuario.
5. Peça para o usuario entrar novamente e configurar o 2FA do zero.
