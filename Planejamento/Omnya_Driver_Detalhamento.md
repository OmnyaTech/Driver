Levantamento de especificações além do .md para geração do PRD:

Etapa 1 — Identidade do Produto

1. Nome
Será um aplicativo com nome Omnya Driver, da empresa/marca "OmnyaTech"

---

2. Idiomas
Preparado para vários idiomas

---

3. Plataforma
Inicialmente Android, posteriormente iOS

---

4. Login
Social: Google e Microsoft
E-mail

Sem possibilidade de entrar como convidado, acesso somente logado/cadastrado.

---

5. Público-alvo
* Entregadores (delivery/farmácias/restaurantes/entregas)
* Motofretistas

---

Etapa 2 — Tecnologia

Preferiveis: Flutter + Supabase

---

Banco de dados Supabase (PostgreSQL)

---

Login Supabase Auth

---

Notificações Firebase (versão gratuita)

---

Etapa 3 — Monetização

Plano Gratuito conforme levantado
Plano Pago/Premium (14,90 mensal ou 149,90 anual [desconto anual])

Somente assinatura (mensal ou anual)

A plataforma de pagamento será a Asaas (já tenho um sistema rodando com ela hoje o OmnyaFinance, então vai ser a mesma)

Etapa 4 — Marca

Omnya Driver será um produto da marca OmnyaTech, ou seja, deve usar a mesma identidade, vamos criar apenas uma logo própria pro aplicativo, mas seguindo o modelo da marca raiz

Etapa 5 — Dashboard

Quando abrir o aplicativo, a primeira tela de navegação que o usuário deve ver, deve ser o relatório do dia atual (hoje), ex:
Quantas entregas, tempo rodado, lucro, ganhos

Etapa 6 — Objetivos

Objetivos são apenas um controle, onde o usuário/entregador pode destinar para seus objetivos e deve ter um crud, para que ele possa registrar retiradas do dinheiro desse objetivo, seguindo a estrutura de jogos com evolução de skills, o usuário tem o saldo disponível (que se trata do saldo feito das entregas) ele só sai do saldo disponível, quando o usuário redireciona por objetivo.

Etapa 7 — Jornada
Quando colocar para iniciar a jornada, o ideal seria registrar o km, mas como nem todos tem hodometro funcionando e nem todos querem tanto controle, essa informação acredito que pode ser opcional, mas informando ao usuário que pra melhores relatórios, é ideal preencher
No encerramento da jornada, pode salvar com dados zerados, por exemplo, dia x rodei só pelo ifood e não rodei pelo 99, então não fiz entregas pelo 99 por mais que tenha cadastro nele

Etapa 8 — Estatísticas
mostrar coisas como:

> Melhor sexta-feira da história.
> Maior faturamento em um dia.
> Maior número de entregas.
> Maior lucro por hora.
> Maior lucro por Km.
> Maior faturamento mensal.
> Sequência de dias trabalhando.

Tudo isso pode virar conquistas.

Etapa 9 — Gamificação
O usuário ganha medalhas.

Exemplo

?? Primeira entrega
?? Primeiros R$1000
??100 entregas
??1000 entregas
??30 dias consecutivos
etc

E conforme vai conquistando medalhas, vai subindo de nível no app.
Da pra fazer um sistema de comparação de quantidade de medalhas entre entregadores e posições rankeadas. (somente com as medalhas, sem apresentar informações sensíveis como lucro, ganhos, objetivos, despesas, etc)

Acrescentar um perfil do entregador, que mostra quantas entregas fez, a quantos dias possui cadastro, nível, rank, etc.

Etapa 10 — Painel do Desenvolvedor

Aparece apenas para usuários com role = DEVELOPER.
Permite:
Gerenciar usuários
Alterar planos
Presentear Premium
Criar Premium vitalício
Bloquear usuários
Estatísticas da plataforma
Total de usuários
Usuários ativos
Assinantes Premium
Crescimento mensal

Como serei somente eu o developer, vou setar a role manualmente, então só eu terei acesso das configurações de administrador da plataforma.

---

Se daqui a 5 anos esse aplicativo tiver 100 mil usuários, o que você gostaria que as pessoas falassem dele?
"É o aplicativo que todo entregador usa para saber quanto realmente ganhou."

--- 

Etapa 11 - Bônus
Uma missão mensal, que a cada 2 entregadores que entrarem usando o link de indicação de um entregador, o entregador dono do link de convite, ganha 10% de desconto na próxima mensalidade

Então precisa de uma forma de registrar isso