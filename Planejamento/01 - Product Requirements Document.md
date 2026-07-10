# 01 - Product Requirements Document (PRD)

# Omnya Driver

**Produto:** Omnya Driver\
**Empresa:** OmnyaTech

## Visão

Omnya Driver é um aplicativo Android desenvolvido em Flutter para
entregadores e motofretistas que desejam controlar jornadas, ganhos,
despesas, produtividade e evolução profissional de forma rápida,
confiável e privada.

**Slogan:** Gerencie sua renda. Não apenas suas entregas.

## Problema

Grande parte dos entregadores utiliza planilhas ou anotações,
dificultando o entendimento do lucro real, custos por quilômetro e
evolução financeira.

## Objetivos

-   Registrar jornadas em menos de 1 minuto.
-   Tornar os relatórios compreensíveis.
-   Calcular lucro líquido real.
-   Incentivar disciplina financeira através de objetivos e gamificação.
-   Ser referência nacional para controle financeiro de entregadores.

## Público-alvo

-   Entregadores de aplicativos
-   Motofretistas
-   Entregadores autônomos
-   Restaurantes e comércios com entregadores próprios

## Plataformas

-   Android (MVP)
-   iOS (futuro)

## Tecnologias

-   Flutter
-   Supabase
-   PostgreSQL
-   Supabase Auth
-   Firebase Cloud Messaging
-   Firebase Crashlytics
-   Firebase Analytics
-   Asaas

## Modelo de Negócio

### Gratuito

-   1 veículo
-   Jornadas ilimitadas
-   Dashboard básico
-   Objetivos
-   Despesas
-   Abastecimentos
-   Manutenções

### Premium

-   Veículos ilimitados
-   Relatórios completos
-   Comparativos
-   Exportação PDF/Excel
-   Gamificação avançada
-   Ranking
-   Insights

## Planos internos

-   FREE
-   PREMIUM
-   GIFT
-   LIFETIME
-   DEVELOPER

## Requisitos Funcionais

-   Cadastro
-   Login Google/Microsoft/E-mail
-   Cadastro de veículos
-   Cadastro de plataformas
-   Cadastro de estabelecimentos
-   Registro manual e automático de jornadas
-   Objetivos
-   Relatórios
-   Perfil público
-   Gamificação
-   Ranking
-   Painel Developer

## Requisitos Não Funcionais

### Performance

-   Inicialização até 2 segundos
-   Dashboard até 1 segundo
-   Consultas paginadas
-   Cache inteligente
-   Carregamento incremental
-   Interface fluida

### Segurança

-   Supabase Auth
-   JWT
-   RLS obrigatório
-   Rate Limit
-   LGPD
-   Rotas protegidas
-   Biometria opcional
-   Bloqueio após 5 horas (configurável)
-   Persistência local da jornada ativa

### Escalabilidade

-   100 mil usuários
-   Múltiplos idiomas
-   Múltiplas moedas
-   Timezone por usuário

## Arquitetura

Mesmo projeto Supabase do OmnyaFinance.

**Regra:** nenhum objeto do OmnyaFinance poderá ser alterado.

Todo novo recurso utilizará o schema:

driver

Auth compartilhado:

auth.users

## Indicadores

-   Lucro bruto
-   Lucro líquido
-   Lucro/hora
-   Lucro/km
-   Lucro/entrega
-   Horas
-   Jornadas
-   Entregas
-   Custos
-   Ranking
-   XP
-   Medalhas
-   Títulos

## Roadmap

### MVP

-   Login
-   Onboarding
-   Veículos
-   Jornadas
-   Dashboard
-   Relatórios básicos

### V1.1

-   Gamificação
-   Objetivos automáticos
-   Ranking

### V2

-   Melhorias contínuas

## Princípios

-   Performance é requisito.
-   Privacidade por padrão.
-   OmnyaFinance permanece intacto.
-   Tudo novo pertence ao schema driver.
-   Clean Architecture obrigatória.
-   Documentação sempre atualizada.
