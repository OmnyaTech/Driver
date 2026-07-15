# Omnya Driver - Visao Funcional do Sistema

Atualizado em 2026-07-15.

## O Que E

O Omnya Driver e um aplicativo da OmnyaTech para entregadores, motofretistas e
profissionais que trabalham com entregas em uma ou mais plataformas. O sistema
organiza a rotina financeira e operacional do entregador: jornadas, ganhos,
entregas, despesas, veiculos, manutencoes, metas, reservas e evolucao pessoal.

Na pratica, ele funciona como um painel de controle da vida na rua. O entregador
registra o que trabalhou, quanto recebeu, quais custos teve e como quer separar
o dinheiro. A partir disso, o app mostra saldo, lucro, desempenho, historico e
sugestoes para manter a rotina mais previsivel.

## Para Que Serve

O sistema serve para responder perguntas que fazem parte da rotina de quem
entrega:

- quanto eu ganhei hoje, na semana ou no mes;
- quanto desse dinheiro sobrou depois dos custos;
- quais plataformas estao rendendo melhor;
- quanto devo separar para manutencao, pneu, oleo, documentos ou emergencia;
- quais despesas estao pesando mais;
- como meu desempenho evoluiu ao longo do tempo;
- quais metas financeiras estao avancando;
- o que ja conquistei dentro do app.

O app nao substitui orientacao contabil, financeira ou juridica. Ele organiza os
dados informados pelo proprio entregador e transforma esses dados em apoio para
decisoes do dia a dia.

## Publico-Alvo

O publico principal e formado por:

- entregadores de aplicativo;
- motofretistas;
- motoristas que trabalham com entregas;
- profissionais que alternam entre plataformas, restaurantes, lojas e corridas
  particulares;
- entregadores que querem sair do controle em papel ou planilha.

## Como Funciona

O fluxo basico do sistema e:

1. O entregador cria a conta e conclui o onboarding.
2. Ele cadastra pelo menos um veiculo e uma plataforma.
3. Em cada jornada, registra horarios, entregas, valores, distancia e ganhos por
   plataforma.
4. Registra despesas, abastecimentos e manutencoes quando acontecem.
5. Acompanha o dashboard para entender receita, custos, lucro e progresso.
6. Cria metas financeiras e movimenta dinheiro entre saldo disponivel e cofres.
7. Usa relatorios, conquistas e historico para acompanhar a evolucao.

O plano gratuito permite ate 3 plataformas ativas. Planos premium, gift,
lifetime e developer liberam plataformas ilimitadas e recursos expandidos.

## Principais Modulos

### Autenticacao

A autenticacao permite entrar por e-mail e tambem por provedores sociais quando
configurados. O fluxo usa protecoes de seguranca no login, cadastro e OAuth.

O sistema tambem possui suporte a verificacao em duas etapas por aplicativo
autenticador. Na tela de codigo MFA, o usuario ve os numeros digitados e pode
usar o botao `Colar`, que aceita apenas digitos.

### Onboarding

O onboarding prepara a conta para uso. Ele coleta dados de perfil, regiao,
preferencias, primeiro veiculo e primeira plataforma. A ideia e liberar o painel
ja com as informacoes minimas para os calculos fazerem sentido.

Tambem e nesse momento que o usuario pode configurar a reserva automatica. As
opcoes disponiveis sao:

- sem reserva;
- percentual por entrega;
- valor por entrega;
- percentual por dia;
- percentual por semana;
- percentual por mes.

### Dashboard

O dashboard mostra o resumo operacional e financeiro. Ele consolida ganhos,
custos, lucro, jornadas, entregas, distancia, plataformas ativas, veiculos,
despesas, abastecimentos e manutencoes.

O objetivo da tela e dar uma leitura rapida do periodo: como o dinheiro entrou,
quanto foi consumido por custos e quanto ainda esta disponivel para metas ou
uso livre.

### Jornadas

A tela de jornadas registra os turnos de trabalho. Uma jornada pode conter:

- horario de inicio e fim;
- status aberto ou finalizado;
- quantidade de entregas;
- distancia rodada;
- receita total;
- distribuicao de ganhos por plataforma;
- observacoes.

Esse modulo e a base dos calculos de desempenho e relatorios.

### Plataformas

A tela de plataformas cadastra as fontes de entrega, como apps, restaurantes,
lojas ou clientes diretos. Cada plataforma pode ter status ativo ou arquivado e
informacoes medias de renda e entregas.

No plano gratuito, o usuario pode manter ate 3 plataformas ativas. Nos planos
expandidos, o cadastro de plataformas ativas e ilimitado.

### Veiculos

A tela de veiculos guarda os dados do veiculo usado no trabalho. Ela permite
registrar tipo, marca, modelo, ano e combustiveis. O veiculo se conecta com
abastecimentos, manutencoes e filtros operacionais.

### Despesas

As despesas registram custos do trabalho que nao sao necessariamente
abastecimento ou manutencao. Elas podem ser vinculadas a uma jornada e ajudam a
calcular o lucro real.

Exemplos: estacionamento, pedagio, alimentacao de trabalho, taxa, acessorio,
lavagem ou outro custo operacional.

### Abastecimentos

O modulo de abastecimentos registra combustivel, valor, quantidade, odometro e
veiculo. Esses registros ajudam a entender custo de operacao e historico de
uso.

### Manutencoes

Manutencoes registram revisoes, reparos e itens trocados no veiculo. A tela
permite acompanhar custos de cuidado com o veiculo e manter historico para
planejamento.

### Metas Financeiras

As metas funcionam como cofres. O usuario define um objetivo, valor alvo e,
opcionalmente, prazo. Depois pode movimentar dinheiro:

- `Aportar`: move saldo disponivel para a meta;
- `Retirar`: devolve dinheiro da meta para o saldo disponivel;
- `Saque`: registra que o dinheiro saiu do cofre para ser gasto fora da meta.

No saque, o app exibe um campo de observacao opcional para o entregador registrar
o motivo da saida. Todas as movimentacoes aparecem no historico.

Os cards principais de Metas destacam:

- disponivel;
- guardado.

### Reserva Automatica

A reserva automatica sugere quanto separar conforme a regra escolhida pelo
usuario. Ela nao tira dinheiro sozinha; a funcao e orientar o entregador com uma
referencia de valor de acordo com sua realidade.

As regras podem ser por entrega, por dia, por semana ou por mes. Assim, quem
trabalha de forma irregular pode escolher uma regra mais adequada a propria
rotina.

### Relatorios

Os relatorios consolidam dados por periodo. Eles ajudam a analisar receita,
custos, lucro, plataformas, jornadas e comportamento operacional.

O objetivo e permitir uma leitura mais ampla do desempenho, principalmente para
quem quer comparar semanas, meses ou entender onde esta ganhando ou gastando
mais.

### Assinaturas

A tela de assinaturas apresenta os planos disponiveis, beneficios e historico
de eventos. O plano gratuito e suficiente para comecar e permite ate 3
plataformas ativas. O Premium libera acesso expandido, como plataformas
ilimitadas e recursos avancados.

Pagamentos e confirmacoes de assinatura sao integrados por provider externo e
sincronizados com o perfil do usuario.

Quando um usuario entra por convite, o cadastro fica vinculado ao entregador que
enviou o link. Esse vinculo alimenta progresso, missoes e recompensas de
indicacao. Quando o indicado evolui para assinatura premium, esse historico
continua disponivel para contabilizar as missoes relacionadas ao convite.

### Comunidade, Ranking E Perfil Publico

O app possui recursos sociais opcionais. O entregador pode usar perfil publico,
ranking e gamificacao sem expor dados financeiros sensiveis.

Esses recursos destacam nivel, titulo, conquistas e indicadores nao sensiveis.

O convite publico aponta para `https://driver.omnyatech.com.br/convite/{slug}`.
Esse link abre a landing page publica do Driver, preserva o slug do entregador
que convidou e encaminha o novo usuario para cadastro antes do download do APK.

No aplicativo, o botao de convite abre a folha nativa de compartilhamento do
celular. Assim o usuario escolhe WhatsApp, Gmail, Outlook, Messenger, Facebook,
Instagram, copiar link ou qualquer app instalado que aceite texto.

## Landing Page E Download Do APK

Enquanto o Driver nao esta publicado na Play Store, o dominio
`driver.omnyatech.com.br` funciona como porta de entrada publica.

O fluxo esperado e:

1. O usuario recebe um link de convite.
2. O link abre a landing page publica com explicacao do sistema, recursos e
   planos.
3. O usuario toca em `Download`.
4. O site abre a tela de cadastro/login preservando o slug do convite.
5. Depois que o cadastro/login esta valido, o botao de download do APK aparece.
6. O usuario baixa o arquivo oficial do dominio configurado.

A URL do APK e configurada por `DRIVER_APK_URL`. Quando essa variavel nao e
informada no build, o app usa o bucket publico `driver-mobile-releases` no
Supabase, arquivo `driver-latest.apk`. O arquivo APK deve ser publicado fora do
Git, no ambiente de hospedagem ou storage escolhido.

O formato recomendado para distribuicao direta e um APK unico universal,
versionado como `driver-vX.Y.Z.apk`, com uma copia ou alias publico
`driver-latest.apk`. O bucket pode ser publico para download por caminho
conhecido, mas nao deve manter policy ampla de listagem em `storage.objects`.
As policies de escrita permanecem restritas a usuarios `developer`.

### Gamificacao E Conquistas

A gamificacao transforma progresso em XP, nivel, medalhas e conquistas. A tela
mostra proximos passos, recordes e uma vitrine de conquistas com contador.

A proposta e reforcar consistencia e bons habitos sem transformar dados
financeiros privados em comparacao publica.

### Seguranca E Dados

A area de seguranca permite configurar protecoes como biometria ou bloqueio do
aparelho, MFA/TOTP e preferencias relacionadas a dados da conta.

O sistema tambem possui fluxos de privacidade, exportacao e encerramento de
conta conforme evolucao do produto.

### Area Developer

A area developer e voltada a administracao e suporte. Ela permite consultar
usuarios, aplicar plano ou papel manualmente e visualizar auditoria de acoes
administrativas.

Essa area nao e parte da rotina comum do entregador.

## Dados Que O Sistema Organiza

O Omnya Driver organiza:

- conta e perfil;
- preferencias do app;
- veiculos;
- plataformas;
- jornadas;
- ganhos por plataforma;
- despesas;
- abastecimentos;
- manutencoes;
- metas;
- movimentacoes de metas;
- assinaturas;
- conquistas e estatisticas publicas opcionais.

## Planos

### Gratuito

Indicado para comecar a organizar a rotina. Inclui recursos essenciais e ate 3
plataformas ativas.

### Premium E Acessos Expandidos

Indicado para quem usa o app de forma mais intensa. Libera plataformas
ilimitadas e recursos avancados conforme o plano ativo.

### Gift, Lifetime E Developer

Sao acessos especiais usados para presente, acesso vitalicio ou administracao.
Eles seguem a regra de acesso expandido.

## Integracoes

O app usa Supabase para autenticacao, banco, funcoes e sincronizacao de dados.
Tambem ha integracoes para pagamentos, notificacoes e protecoes de seguranca,
conforme configuracao do ambiente.

Detalhes tecnicos e operacionais ficam em `docs/engineering/`.

## O Que O Sistema Nao Faz

O Omnya Driver nao promete renda, nao calcula imposto oficial, nao substitui
contador e nao toma decisoes financeiras pelo usuario. Ele organiza informacoes
e oferece leitura pratica para apoiar a rotina de trabalho.

## Principio Do Produto

O produto foi pensado para ser simples o suficiente para uso diario e completo o
suficiente para quem quer entender melhor o proprio trabalho. A tela inicial
deve responder rapido; os modulos detalhados ficam disponiveis para quando o
entregador quiser investigar melhor os numeros.
