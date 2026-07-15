# Omnya Driver

O Omnya Driver e um app Flutter da OmnyaTech feito para entregadores
acompanharem a rotina sem depender de planilhas. Ele ajuda a registrar jornadas,
ganhos, despesas, abastecimentos, manutencoes, metas financeiras e evolucao do
perfil em um so lugar.

O foco do produto e simples: transformar o dinheiro e o tempo da rua em numeros
faceis de entender, para o entregador decidir melhor quanto guardar, onde
trabalhar, quando revisar o veiculo e como acompanhar seu progresso.

## O Que Ja Funciona

- Login por e-mail, Google e Microsoft.
- Onboarding com perfil, regiao, preferencias, primeiro veiculo e primeira
  plataforma.
- Cadastro de jornadas, ganhos por plataforma, entregas, distancia e horarios.
- Controle de despesas, abastecimentos e manutencoes.
- Metas financeiras com aporte, retirada, saque e historico de movimentacoes.
- Reserva automatica configuravel por entrega, dia, semana ou mes.
- Landing publica em `driver.omnyatech.com.br` com convite, cadastro e download
  oficial do APK.
- Dashboard com indicadores operacionais e financeiros.
- Relatorios, ranking, conquistas, vitrine publica opcional e area de
  seguranca.
- Plano gratuito com ate 3 plataformas ativas; planos expandidos com
  plataformas ilimitadas.
- Area administrativa para acesso developer e operacoes de suporte.

## Documentacao

A documentacao funcional principal esta em:

- `docs/omnya_driver_system_overview.md`
- `docs/downloads.md`

Documentos tecnicos vivos ficam em:

- `docs/engineering/`

Scripts SQL manuais ficam em:

- `sql/manual/`

## Estrutura

- `lib/`: codigo Flutter do app.
- `supabase/functions/`: Edge Functions usadas pelo backend.
- `sql/manual/`: scripts SQL versionados para aplicar no Supabase.
- `docs/`: documentacao funcional, tecnica e operacional.
- `Planejamento/`: material de produto e planejamento.
- `src/`: referencias visuais e assets de apoio.

## Configuracao Local

Crie um arquivo `.env` local com as variaveis necessarias para o ambiente de
desenvolvimento. Esse arquivo nao deve ser versionado.

Para rodar o app, use os comandos Flutter normais do projeto. Para gerar APK de
release, use o script:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_driver_release.ps1
```

O script le as configuracoes locais, injeta os `dart-define` necessarios e copia
o APK final para `build/app/outputs/flutter-apk/`.

Para o site publico, a URL do APK pode ser definida com `DRIVER_APK_URL`. Sem
essa variavel, a landing usa o bucket publico `driver-mobile-releases` do
Supabase, arquivo `driver-latest.apk`. O formato recomendado de distribuicao e
um APK unico universal, publicado fora do Git.

## Cuidados

Nao coloque chaves, tokens, URLs privadas de ambiente, certificados ou segredos
no repositorio. Configuracoes sensiveis devem ficar no ambiente local, no
Supabase ou no provedor de CI/CD.

O schema de banco usado pelo app e isolado para o Driver. Mudancas de banco
devem ser feitas por SQL versionado em `sql/manual/` e aplicadas manualmente no
ambiente correto.
