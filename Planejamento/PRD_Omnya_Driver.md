# PRD --- Omnya Driver

> **Produto:** Omnya Driver\
> **Marca:** OmnyaTech

> **Observação:** Este documento consolida o levantamento realizado nas
> conversas. Devido ao limite de contexto do chat, ele representa a
> especificação funcional consolidada e servirá como base para expansão
> contínua.

# 1. Visão do Produto

**Slogan:** Gerencie sua renda. Não apenas suas entregas.

O Omnya Driver é um aplicativo Android (Flutter + Supabase) para
entregadores e motofretistas controlarem jornadas, ganhos, despesas,
veículos, metas e produtividade.

## Objetivos

-   Registro rápido (\<1 minuto).
-   Interface fluida.
-   Privacidade por padrão.
-   Escalável para 100.000+ usuários.
-   Arquitetura preparada para múltiplos produtos OmnyaTech.

# 2. Tecnologias

-   Flutter
-   Supabase
-   PostgreSQL
-   Supabase Auth
-   RLS obrigatório
-   Firebase Cloud Messaging
-   Firebase Crashlytics
-   Firebase Analytics
-   Asaas (assinaturas)
-   Cloudflare Turnstile

# 3. Arquitetura Supabase

Mesmo projeto do OmnyaFinance.

**Regra:** Não alterar qualquer recurso existente do OmnyaFinance.

Novo schema:

    driver

Todas as tabelas do Driver pertencem ao schema `driver`.

Auth compartilhado:

    auth.users

# 4. Banco de Dados (resumo)

driver.profiles driver.vehicles driver.platforms driver.businesses
driver.journeys driver.journey_platforms driver.trip_expenses
driver.fuelings driver.maintenances driver.maintenance_items
driver.goals driver.goal_transactions driver.achievements
driver.user_achievements driver.referrals driver.user_statistics
driver.audit_logs driver.feature_flags

Relacionamento principal:

auth.users -\> driver.profiles

# 5. Planos

Free Premium Gift Lifetime Developer

Premium: - mensal - anual

Pagamento: - Cartão (Asaas)

# 6. Jornada

Estados: - INICIADA - EM_ANDAMENTO - FINALIZADA - CANCELADA

Uma jornada: - pertence ao usuário - pertence ao veículo - possui
múltiplas plataformas - pode possuir despesas - pode possuir
abastecimento - pode possuir manutenção proporcional

# 7. Gamificação

XP: +10 jornada +2 entrega +100 medalha +500 objetivo concluído

Progressão:

XP = Base × Nível\^1.8

Medalhas: Bronze Prata Ouro Diamante Lendária

Conquistas: Primeira entrega Primeira jornada 100 entregas 1000 entregas
30 dias consecutivos Primeiros R\$1000 etc.

Títulos: Entregador Iniciante Veterano Especialista Mestre das Entregas
Lenda das Estradas Imperador da Logística

# 8. Perfil Público

Exibe: - nível - estrelas - entregas - medalhas - título -
personalização (Lendária)

Nunca exibe ganhos.

# 9. Indicadores

Financeiros: - bruto - líquido - lucro/hora - lucro/km - lucro/entrega

Operacionais: - horas - km - jornadas - entregas

Custos: - combustível - manutenção - pedágio

# 10. Regras Financeiras

Lucro líquido:

Bruto - despesas - combustível proporcional - manutenção proporcional

Reserva: 30% (configurável)

Manutenção: amortizada historicamente.

# 11. Segurança

-   Auth obrigatório
-   JWT
-   RLS
-   LGPD
-   Rate Limit
-   Rotas protegidas
-   Biometria opcional
-   Bloqueio após inatividade (padrão 5h)
-   Persistência local da jornada

# 12. Configurações

Idioma Tema Moeda Reserva Meta diária Meta semanal Meta mensal Biometria
Tempo de bloqueio Notificações Sons Vibração

# 13. Painel Developer

Somente métricas agregadas: - usuários - assinantes - DAU - MAU -
retenção - conversão - versões - idiomas - feature flags - push

Sem acesso aos dados financeiros individuais.

# 14. Feature Flags

Estrutura preparada para liberar recursos por: - Developer - Beta -
Premium - Todos

# 15. Performance

-   abertura até 2s
-   dashboard até 1s
-   carregamento incremental
-   consultas paginadas
-   cache inteligente
-   UX fluida

# 16. Roadmap

MVP: Login Onboarding Jornadas Veículos Relatórios

V1.1 Gamificação Objetivos

V2 Ranking Expansões

# 17. Princípios

-   Rapidez acima de tudo.
-   Privacidade por padrão.
-   OmnyaFinance não deve ser alterado.
-   Tudo novo pertence ao schema driver.
-   Clean Architecture.
-   Documentação sempre atualizada.
