# Downloads

## Driver Android

O Omnya Driver usa APK unico universal para distribuicao fora da Play Store.
Esse e o formato esperado para publicacao manual no site ou no storage:

- APK versionado: `build/app/outputs/flutter-apk/driver-v1.0.17.apk`
- Alias publico recomendado: `driver-latest.apk`
- Bucket Supabase: `driver-mobile-releases`
- URL padrao da landing:
  `https://cattokugqanpagleawpw.supabase.co/storage/v1/object/public/driver-mobile-releases/driver-latest.apk`

O APK nao deve ser versionado no Git. Depois de gerar a release, publique o
arquivo no storage ou no provedor de download escolhido.

## Fluxo No Site

O dominio `driver.omnyatech.com.br` apresenta a landing publica, explica o
sistema, preserva o convite recebido e libera o download somente depois do
cadastro/login. Isso permite vincular o indicado ao entregador que enviou o
convite antes de entregar o APK.

A URL real do APK pode ser alterada no build web por `DRIVER_APK_URL`. Sem essa
variavel, a landing usa o bucket publico `driver-mobile-releases` e o arquivo
`driver-latest.apk`.

## Storage E Policies

O bucket `driver-mobile-releases` fica publico para permitir download por
caminho conhecido. Ele nao deve ter policy ampla de `SELECT` em
`storage.objects`, porque isso permite listar todos os arquivos do bucket pelo
cliente e gera alerta no painel do Supabase.

As policies de insert, update e delete devem permanecer restritas a usuarios
autenticados com papel `developer` no schema `driver`.

## Quando O Upload Automatico Falhar

O APK universal pode passar de 50 MB. Se o upload automatico pelo Supabase CLI
ou painel falhar por limite do ambiente, suba manualmente o arquivo
`driver-v1.0.17.apk` e mantenha uma copia ou alias com o nome
`driver-latest.apk`.

Uma alternativa futura, seguindo o modelo do OmnyaFinance, e usar uma camada de
download/proxy em um Worker. Nesse modelo, o frontend chama uma URL propria do
dominio, e o Worker busca o APK real no storage, responde com
`Content-Disposition: attachment`, `Content-Type:
application/vnd.android.package-archive` e CORS restrito ao dominio publico do
Driver.

## Validacao Manual

1. Abrir `driver.omnyatech.com.br`.
2. Conferir que a landing carrega sem exigir login.
3. Entrar por um link `/convite/{slug}` e confirmar que o slug e preservado.
4. Clicar em `Download`.
5. Concluir cadastro ou login.
6. Confirmar que o botao final baixa o APK configurado.
7. Conferir que o bucket nao permite listagem ampla de arquivos pelo cliente.
