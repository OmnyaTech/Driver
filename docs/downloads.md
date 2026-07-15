# Downloads

## Driver Android

O Omnya Driver usa APK unico universal para distribuicao fora da Play Store.
Como o APK atual passa de 50 MB e o plano gratuito do Supabase limita upload a
50 MB, o canal de download publico e o MediaFire.

- APK versionado: `build/app/outputs/flutter-apk/driver-v1.0.17.apk`
- Link MediaFire:
  `https://www.mediafire.com/file/cehfkctgxvhcqlu/driver-v1.0.17.apk/file`

O APK nao deve ser versionado no Git. Depois de gerar a release, publique o
arquivo no MediaFire e atualize a secret da Edge Function.

## Fluxo No Site

O dominio `driver.omnyatech.com.br` apresenta a landing publica, explica o
sistema, preserva o convite recebido e libera o download somente depois do
cadastro/login. Isso permite vincular o indicado ao entregador que enviou o
convite antes de entregar o APK.

A tela de download busca o link dinamico na Edge Function
`driver-download-links`. O link do MediaFire fica na secret
`DRIVER_MEDIAFIRE_APK_URL`; assim, quando o arquivo mudar, basta atualizar a
secret sem alterar o codigo do Flutter.

## Storage E Policies

O bucket `driver-mobile-releases` pode continuar existindo para historico de
arquivos pequenos ou releases split, mas nao e mais o canal publico principal
do APK universal.

Ele nao deve ter policy ampla de `SELECT` em `storage.objects`, porque isso
permite listar todos os arquivos do bucket pelo cliente e gera alerta no painel
do Supabase.

As policies de insert, update e delete devem permanecer restritas a usuarios
autenticados com papel `developer` no schema `driver`.

## Atualizacao Do Link

Para trocar o arquivo publicado:

1. Subir o novo APK no MediaFire.
2. Copiar o link publico do arquivo.
3. Atualizar a secret `DRIVER_MEDIAFIRE_APK_URL` no Supabase.
4. Validar a tela `/download` autenticada.

## Validacao Manual

1. Abrir `driver.omnyatech.com.br`.
2. Conferir que a landing carrega sem exigir login.
3. Entrar por um link `/convite/{slug}` e confirmar que o slug e preservado.
4. Clicar em `Download`.
5. Concluir cadastro ou login.
6. Confirmar que o botao final abre o MediaFire configurado.
7. Conferir que o bucket do Supabase nao permite listagem ampla de arquivos pelo cliente.
