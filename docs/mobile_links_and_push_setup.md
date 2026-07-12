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

Checklist para ativar envio real:

- Adicionar `android/app/google-services.json`.
- Aplicar o plugin `com.google.gms.google-services` no projeto Android.
- Adicionar `ios/Runner/GoogleService-Info.plist`.
- Ativar APNs no Apple Developer e configurar a chave APNs no Firebase.
- Ajustar `ios/Runner/Runner.entitlements` para o ambiente correto de APNs.
- Criar uma Supabase Edge Function ou backend que leia `driver_push_devices` e envie mensagens pelo Firebase Admin SDK.
