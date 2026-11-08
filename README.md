# Omnya Driver

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white) ![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=flat-square&logo=supabase&logoColor=white) ![Em produção](https://img.shields.io/badge/Em%20produ%C3%A7%C3%A3o-16a34a?style=flat-square)

**Produto:** [driver.omnyatech.com.br](https://driver.omnyatech.com.br/)

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
- Plano gratuito com plataformas ilimitadas e 1 veiculo ativo; Premium libera
  multiplos veiculos e recursos avancados.
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

Para o site publico, o download do APK e servido pelo link MediaFire retornado
pela Edge Function `driver-download-links`. Atualize a secret
`DRIVER_MEDIAFIRE_APK_URL` sempre que trocar o arquivo publicado. O formato
recomendado de distribuicao e um APK unico universal, publicado fora do Git.

## Cuidados

Nao coloque chaves, tokens, URLs privadas de ambiente, certificados ou segredos
no repositorio. Configuracoes sensiveis devem ficar no ambiente local, no
Supabase ou no provedor de CI/CD.

O schema de banco usado pelo app e isolado para o Driver. Mudancas de banco
devem ser feitas por SQL versionado em `sql/manual/` e aplicadas manualmente no
ambiente correto.

---

<sub>Desenvolvido por <a href="https://github.com/Yan-Oliv">Yan Monteiro</a> · <a href="https://www.linkedin.com/in/yan-de-oliveira-gon%C3%A7alves-monteiro-a2886619a/">LinkedIn</a> · <a href="https://github.com/OmnyaTech">OmnyaTech</a></sub>

