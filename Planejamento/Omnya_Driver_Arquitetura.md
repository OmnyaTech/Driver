> O usuário deve gastar menos de 1 minuto para registrar uma jornada.



Todo o restante deve ser calculado pelo sistema.


---

Omnya Driver

Slogan

Gerencie sua renda. Não apenas suas entregas.


---

Público-alvo

Entregadores de aplicativos

Motofretistas

Entregadores de restaurantes

Profissionais que trabalham em múltiplas plataformas



---

Modelo de negócio

?? Gratuito

Ideal para quem está começando.

Inclui

Cadastro de 1 veículo

Cadastro ilimitado de plataformas

Registro manual de jornadas

Registro automático de jornadas

Dashboard básico

Estatísticas do dia

Estatísticas da semana

Estatísticas do mês

Histórico ilimitado

Objetivos financeiros

Registro de abastecimentos

Registro de manutenções



---

? Premium (R$ 14,90/mês)

Inclui

Tudo do gratuito +

Comparativos semanais

Comparativos mensais

Comparativos anuais

Gráficos completos

Exportação PDF

Exportação Excel

Insights inteligentes

Relatório de lucro por plataforma

Relatório de custos do veículo

Relatório de produtividade

Comparação entre veículos (caso tenha mais de um)

Múltiplos veículos



---

Estrutura das telas

1. Login

Google
Microsoft
Email



---

2. Onboarding

Cadastro

Nome

Email

Telefone

Profile (Foto de perfil)



---

Cadastro do veículo

Marca

Modelo

Ano

Tipo de combustível

Consumo médio (Km/L)



---

Cadastro das plataformas

Para cada plataforma:

Nome

Tipo

Plataforma

Restaurante

Mercado

Outro


Média diária (opcional)

Média de entregas (opcional)



---

Navegação principal

?? Home

?? Jornadas

?? Despesas

?? Veículos

?? Relatórios

?? Perfil

Se for Desenvolvedor:

? Admin

UI Design Menu Styles Mobile
{
Menu Stile: Tab Bar/Rudder
Login Stile: Sheet
CRUD: FAB
}
---

Home

Cards

Hoje

Horas trabalhadas

Km rodados

Entregas

Faturamento bruto

Reserva (30%)

Lucro líquido



---

Semana

Total bruto

Total líquido

Total de entregas

Total de Km



---

Mês

Total bruto

Total líquido

Total de jornadas



---

Objetivos

Exemplo

Advogado

???????????

R$650 / R$800


---

Jornadas

Lista das jornadas.

Cada card mostra:

11h às 14h

R$152

8 entregas

42 Km

Pode existir várias jornadas no mesmo dia.


---

Registrar Jornada

Modo Automático

Início

Solicita apenas:

Km inicial

Hora e data são automáticas.


---

Encerramento

Para cada plataforma cadastrada:

99

Entregas

Valor

Depois:

Km Final

Salvar.


---

Modo Manual

Solicita:

Data

Hora início

Hora fim

Km inicial

Km final


Depois exatamente o mesmo formulário das plataformas.


---

Despesas

A tela será dividida em 3 categorias, cada uma com um objetivo diferente.


---

1. Despesas de percurso

São despesas ligadas a uma jornada específica.

Campos:

Data

Jornada (opcional)

Tipo

Pedágio

Estacionamento

Outro


Valor

Observação (opcional)


Essas despesas entram no cálculo do lucro líquido da jornada e dos relatórios.


---

2. Abastecimentos

Campos:

Data

Km atual

Tipo de combustível

Nome do posto (opcional)

Litros abastecidos

Valor por litro

Valor total


O sistema calcula automaticamente:

Consumo médio real

Custo por Km

Autonomia estimada (futuro)



---

3. Manutenções

Campos

Data

Oficina

Motivo

Valor total


Itens opcionais

Exemplo

Óleo

R$65

Filtro

R$25

Mão de obra

R$30

Valor total

R$120


---

Veículos

Lista de veículos.

No gratuito:

Apenas um.

Premium:

Quantos quiser.


---

Relatórios

Diário

Mostra

Horas

Km

Entregas

Lucro

Custos



---

Semanal

Compara

Semana atual

×

Semana passada

Mostrando

Lucro

Horas

Km

Entregas



---

Mensal

Compara

Julho

Agosto

Setembro

Mostra

Crescimento

Média diária

Média por hora



---

Anual

Comparação mês a mês.


---

Plataformas

Ranking

Quem mais faturou

Quem teve mais entregas

Melhor média por entrega



---

Horários

Qual faixa horária gera maior lucro.


---

Dias da semana

Qual dia gera maior faturamento.


---

Veículo

Mostra

Km rodados

Combustível gasto

Gastos com manutenção

Gastos de percurso

Custo médio por Km



---

Dashboard (cálculos automáticos)

Jornada

Calcula automaticamente:

Tempo trabalhado

Km rodados

Total de entregas

Total bruto

Reserva de 30%

Lucro líquido

Média por hora

Média por entrega

Média por Km



---

Dia

Soma todas as jornadas do dia.


---

Semana

Calcula:

Total bruto

Total líquido

Horas

Km

Entregas


Comparação percentual com a semana anterior.


---

Mês

Calcula:

Total bruto

Total líquido

Média diária

Média por hora

Média por entrega

Média por Km


Comparação com o mês anterior.


---

Ano

Calcula:

Lucro anual

Faturamento anual

Km anual

Entregas anuais



---

Objetivos Financeiros

O usuário pode criar quantos objetivos desejar.

Exemplo

Casamento

R$15.000

Lua de Mel

R$8.000

Reserva

R$5.000

Advogado

R$800

Ao finalizar uma jornada o aplicativo pergunta:

Deseja destinar o lucro de hoje?

( ) Casamento

( ) Lua de Mel

( ) Reserva

( ) Advogado


---

Estrutura do banco

users

id
name
email
phone
birth_date
gender

role

plan

plan_origin

plan_started_at
plan_expires_at

created_at
updated_at


---

vehicles

id

user_id

brand

model

year

fuel_type

average_consumption

plate

active

created_at


---

platforms

id

user_id

name

type

average_income

average_deliveries

active


---

journeys

id

user_id

vehicle_id

mode

started_at

ended_at

odometer_start

odometer_end

notes


---

journey_platforms

id

journey_id

platform_id

deliveries

income


---

trip_expenses

id

journey_id

type
    PEDAGIO
    ESTACIONAMENTO
    OUTRO

description

amount

created_at


---

fuelings

id

vehicle_id

date

odometer

station

fuel_type

liters

price_per_liter

total


---

maintenances

id

vehicle_id

date

workshop

reason

description

total


---

maintenance_items

id

maintenance_id

description

price


---

goals

id

user_id

title

target_amount

current_amount

deadline

icon


---

goal_transactions

id

goal_id

journey_id

amount


---

Painel do Desenvolvedor

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

Quantidade de jornadas registradas

Valor estimado movimentado pelos usuários



---

Uma recomendação de produto

Eu faria uma pequena alteração na tela Despesas: incluiria um campo "Associar a uma jornada" em despesas de percurso e abastecimentos (opcional). Assim, quem abasteceu durante o expediente ou pagou um pedágio em uma jornada específica pode vincular esse custo e obter um lucro líquido mais preciso daquela jornada. Quem não quiser preencher esse detalhe continua usando o app de forma simples.

Esse equilíbrio entre simplicidade para o uso diário e profundidade para quem deseja analisar custos é, na minha opinião, o que pode diferenciar o Omnya Driver de uma simples planilha ou de um aplicativo de controle financeiro genérico.