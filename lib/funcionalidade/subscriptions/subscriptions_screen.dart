import 'package:flutter/material.dart';

import '../../models/app_subscription.dart';
import '../../services/billing_service.dart';
import '../../services/subscription_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with WidgetsBindingObserver {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final BillingService _billingService = BillingService();
  bool _loading = true;
  bool _creatingCheckout = false;
  bool _managingSubscription = false;
  bool _annualBilling = false;
  List<AppSubscription> _subscriptions = const [];
  List<BillingEventItem> _billingEvents = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final subscriptions = await _subscriptionService
          .listCurrentUserSubscriptions();
      final events = await _billingService.listBillingEvents();
      if (!mounted) return;
      setState(() {
        _subscriptions = subscriptions;
        _billingEvents = events;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Nao foi possivel carregar os dados de assinatura agora.',
          en: 'Could not load subscription data right now.',
          es: 'No fue posible cargar los datos de suscripcion ahora.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (_loading) {
      return OmnyaSubPageScaffold(
        title: strings.subscription,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentPlan = _subscriptionService.currentSubscription(
      _subscriptions,
    );
    final planCards = _buildPlanCards(context, annualBilling: _annualBilling);
    final hasPendingCheckout = currentPlan?.isPending ?? false;
    final hasActivePlan = currentPlan?.isActive ?? false;
    final checkoutBlockReason = _checkoutBlockReason(
      hasPendingCheckout: hasPendingCheckout,
      hasActivePlan: hasActivePlan,
    );

    return OmnyaSubPageScaffold(
      title: strings.subscription,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              strings.pick(
                pt: 'Planos e assinatura',
                en: 'Plans and subscription',
                es: 'Planes y suscripcion',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.pick(
                pt: 'Escolha o nivel ideal para liberar mais historico, varias fontes de ganho e mais controle.',
                en: 'Choose the right level to unlock more history, multiple earning sources and more control.',
                es: 'Elige el nivel ideal para liberar mas historial, varias fuentes de ingreso y mas control.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _CurrentPlanCard(subscription: currentPlan),
            if (hasPendingCheckout) ...[
              const SizedBox(height: 12),
              _PendingCheckoutNotice(onRefresh: _loadData),
            ],
            if (currentPlan != null && currentPlan.isCurrent) ...[
              const SizedBox(height: 12),
              _SubscriptionManagementCard(
                subscription: currentPlan,
                busy: _managingSubscription,
                onCancel: _requestCancellation,
                onChangePlan: () => _requestPlanChange('premium'),
              ),
            ],
            const SizedBox(height: 16),
            _BillingCycleBar(
              annualBilling: _annualBilling,
              onChanged: (value) => setState(() => _annualBilling = value),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                if (compact) {
                  return Column(
                    children: planCards
                        .map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SubscriptionPlanCard(
                              plan: plan,
                              busy: _creatingCheckout,
                              blockedReason: plan.planType == null
                                  ? null
                                  : checkoutBlockReason,
                              onTap:
                                  plan.planType == null ||
                                      checkoutBlockReason != null
                                  ? null
                                  : () => _startCheckout(
                                      planType: plan.planType!,
                                      billingCycle: _annualBilling
                                          ? 'YEARLY'
                                          : 'MONTHLY',
                                    ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: planCards
                      .map(
                        (plan) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: plan == planCards.last ? 0 : 16,
                            ),
                            child: _SubscriptionPlanCard(
                              plan: plan,
                              busy: _creatingCheckout,
                              blockedReason: plan.planType == null
                                  ? null
                                  : checkoutBlockReason,
                              onTap:
                                  plan.planType == null ||
                                      checkoutBlockReason != null
                                  ? null
                                  : () => _startCheckout(
                                      planType: plan.planType!,
                                      billingCycle: _annualBilling
                                          ? 'YEARLY'
                                          : 'MONTHLY',
                                    ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick(
                        pt: 'Historico de assinatura',
                        en: 'Subscription history',
                        es: 'Historial de suscripcion',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_subscriptions.isEmpty)
                      Text(
                        strings.pick(
                          pt: 'Nenhum historico de assinatura encontrado.',
                          en: 'No subscription history found.',
                          es: 'No se encontro historial de suscripcion.',
                        ),
                      ),
                    ..._subscriptions.map(
                      (subscription) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_capitalize(subscription.planType)} - ${_capitalize(subscription.status)}',
                        ),
                        subtitle: Text(
                          [
                            if (subscription.provider != null)
                              subscription.provider!,
                            if (subscription.startedAt != null)
                              '${strings.pick(pt: 'Inicio', en: 'Start', es: 'Inicio')} ${_formatDate(subscription.startedAt!)}',
                            if (subscription.expiresAt != null)
                              '${strings.pick(pt: 'Expira', en: 'Expires', es: 'Expira')} ${_formatDate(subscription.expiresAt!)}',
                          ].join(' - '),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick(
                        pt: 'Movimentos de pagamento',
                        en: 'Payment activity',
                        es: 'Movimientos de pago',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_billingEvents.isEmpty)
                      Text(
                        strings.pick(
                          pt: 'Nenhum movimento de pagamento registrado ainda.',
                          en: 'No payment activity recorded yet.',
                          es: 'Aun no hay movimientos de pago registrados.',
                        ),
                      ),
                    ..._billingEvents.map(
                      (event) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(event.eventType),
                        subtitle: Text(
                          [
                            if (event.status != null) event.status!,
                            _formatDateTime(event.createdAt),
                            if (event.externalReference != null)
                              event.externalReference!,
                          ].join(' - '),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCheckout({
    required String planType,
    required String billingCycle,
  }) async {
    setState(() {
      _creatingCheckout = true;
      _errorMessage = null;
    });

    try {
      final checkout = await _billingService.createCheckout(
        planType: planType,
        billingCycle: billingCycle,
      );
      final opened = await _billingService.openCheckout(checkout);
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _errorMessage = AppStrings.of(context).pick(
            pt: 'Nao foi possivel abrir o checkout do Asaas.',
            en: 'Could not open Asaas checkout.',
            es: 'No fue posible abrir el checkout de Asaas.',
          );
        });
      } else {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(context).pick(
                pt: 'Checkout aberto. Seu plano fica pendente ate o pagamento cair.',
                en: 'Checkout opened. Your plan stays pending until payment is confirmed.',
                es: 'Checkout abierto. Tu plan queda pendiente hasta confirmar el pago.',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _creatingCheckout = false);
      }
    }
  }

  Future<void> _requestCancellation() async {
    if (_managingSubscription) return;
    setState(() {
      _managingSubscription = true;
      _errorMessage = null;
    });

    try {
      await _billingService.manageSubscription(action: 'cancel');
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: 'Cancelamento registrado. Se houver cobranca ativa no Asaas, a baixa ja foi solicitada.',
              en: 'Cancellation requested. If there is an active Asaas charge, we already asked to stop it.',
              es: 'Cancelacion registrada. Si hay cobro activo en Asaas, ya pedimos la baja.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _managingSubscription = false);
    }
  }

  Future<void> _requestPlanChange(String planType) async {
    if (_managingSubscription) return;
    setState(() {
      _managingSubscription = true;
      _errorMessage = null;
    });

    try {
      await _billingService.manageSubscription(
        action: 'change_plan',
        planType: planType,
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: 'Troca registrada para a proxima renovacao. Vamos te avisar quando virar.',
              en: 'Plan change saved for the next renewal. We will let you know when it changes.',
              es: 'Cambio registrado para la proxima renovacion. Te avisaremos cuando ocurra.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _managingSubscription = false);
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${_formatDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String? _checkoutBlockReason({
    required bool hasPendingCheckout,
    required bool hasActivePlan,
  }) {
    final strings = AppStrings.of(context);
    if (hasActivePlan) {
      return strings.pick(
        pt: 'Plano ativo',
        en: 'Active plan',
        es: 'Plan activo',
      );
    }
    if (hasPendingCheckout) {
      return strings.pick(
        pt: 'Pagamento pendente',
        en: 'Payment pending',
        es: 'Pago pendiente',
      );
    }
    return null;
  }

  List<_DriverPlanCardData> _buildPlanCards(
    BuildContext context, {
    required bool annualBilling,
  }) {
    final strings = AppStrings.of(context);
    if (annualBilling) {
      return [
        _DriverPlanCardData(
          title: strings.pick(pt: 'Gratis', en: 'Free', es: 'Gratis'),
          description: strings.pick(
            pt: 'Entrada sem custo para iniciar os registros do dia a dia.',
            en: 'Free entry to start tracking your daily routine.',
            es: 'Entrada sin costo para empezar a registrar tu dia a dia.',
          ),
          price: 0,
          caption: strings.pick(pt: 'sem custo', en: 'free', es: 'sin costo'),
          features: [
            strings.pick(
              pt: '1 plataforma ativa por conta',
              en: '1 active platform per account',
              es: '1 plataforma activa por cuenta',
            ),
            strings.pick(
              pt: 'Historico operacional inicial',
              en: 'Initial operating history',
              es: 'Historial operativo inicial',
            ),
            strings.pick(
              pt: 'Metas e saldo do motorista',
              en: 'Goals and driver balance',
              es: 'Metas y saldo del conductor',
            ),
            strings.pick(
              pt: 'Tema claro/escuro e perfil base',
              en: 'Light/dark theme and base profile',
              es: 'Tema claro/oscuro y perfil base',
            ),
          ],
          buttonLabel: strings.pick(
            pt: 'Plano base',
            en: 'Base plan',
            es: 'Plan base',
          ),
          icon: Icons.shield_outlined,
        ),
        _DriverPlanCardData(
          title: strings.pick(
            pt: 'Premium anual',
            en: 'Annual Premium',
            es: 'Premium anual',
          ),
          description: strings.pick(
            pt: 'Melhor custo para manter a operacao completa o ano inteiro.',
            en: 'Best value to keep the full operation running all year.',
            es: 'Mejor costo para mantener la operacion completa todo el ano.',
          ),
          price: 149.90,
          caption: strings.pick(
            pt: 'cobranca anual',
            en: 'annual billing',
            es: 'cobro anual',
          ),
          features: [
            strings.pick(
              pt: 'Multiplas plataformas e veiculos',
              en: 'Multiple platforms and vehicles',
              es: 'Multiples plataformas y vehiculos',
            ),
            strings.pick(
              pt: 'Historico e uso expandido',
              en: 'Expanded history and usage',
              es: 'Historial y uso ampliado',
            ),
            strings.pick(
              pt: 'Gestao completa com menor custo mensal',
              en: 'Full management with lower monthly cost',
              es: 'Gestion completa con menor costo mensual',
            ),
            strings.pick(
              pt: 'Checkout anual no Asaas',
              en: 'Annual checkout on Asaas',
              es: 'Checkout anual en Asaas',
            ),
          ],
          buttonLabel: strings.pick(
            pt: 'Assinar anual',
            en: 'Subscribe yearly',
            es: 'Suscribir anual',
          ),
          icon: Icons.workspace_premium_outlined,
          planType: 'premium',
          badge: strings.pick(
            pt: 'Economize no anual',
            en: 'Save yearly',
            es: 'Ahorra anual',
          ),
          highlighted: true,
        ),
      ];
    }

    return [
      _DriverPlanCardData(
        title: strings.pick(pt: 'Gratis', en: 'Free', es: 'Gratis'),
        description: strings.pick(
          pt: 'Para organizar o basico do mes atual com o essencial.',
          en: 'For organizing the basics of the current month.',
          es: 'Para organizar lo basico del mes actual.',
        ),
        price: 0,
        caption: strings.pick(pt: 'sem custo', en: 'free', es: 'sin costo'),
        features: [
          strings.pick(
            pt: '1 plataforma ativa por conta',
            en: '1 active platform per account',
            es: '1 plataforma activa por cuenta',
          ),
          strings.pick(
            pt: 'Cadastro de jornadas, despesas e objetivos',
            en: 'Shift, expense and goal tracking',
            es: 'Registro de jornadas, gastos y metas',
          ),
          strings.pick(
            pt: 'Relatorios operacionais do periodo',
            en: 'Operational reports for the period',
            es: 'Reportes operativos del periodo',
          ),
          strings.pick(
            pt: 'Perfil publico opcional',
            en: 'Optional public profile',
            es: 'Perfil publico opcional',
          ),
        ],
        buttonLabel: strings.pick(
          pt: 'Plano base',
          en: 'Base plan',
          es: 'Plan base',
        ),
        icon: Icons.shield_outlined,
      ),
      _DriverPlanCardData(
        title: strings.pick(
          pt: 'Premium mensal',
          en: 'Monthly Premium',
          es: 'Premium mensual',
        ),
        description: strings.pick(
          pt: 'Para ganhar ritmo com historico, multiplas fontes e mais controle.',
          en: 'For more rhythm with history, multiple sources and more control.',
          es: 'Para ganar ritmo con historial, multiples fuentes y mas control.',
        ),
        price: 14.90,
        caption: strings.pick(
          pt: 'cobranca mensal',
          en: 'monthly billing',
          es: 'cobro mensual',
        ),
        features: [
          strings.pick(
            pt: 'Multiplas plataformas ativas',
            en: 'Multiple active platforms',
            es: 'Multiples plataformas activas',
          ),
          strings.pick(
            pt: 'Mais veiculos e operacao expandida',
            en: 'More vehicles and expanded operation',
            es: 'Mas vehiculos y operacion ampliada',
          ),
          strings.pick(
            pt: 'Historico ampliado de uso',
            en: 'Expanded usage history',
            es: 'Historial de uso ampliado',
          ),
          strings.pick(
            pt: 'Checkout e cobranca recorrente',
            en: 'Checkout and recurring billing',
            es: 'Checkout y cobro recurrente',
          ),
        ],
        buttonLabel: strings.pick(
          pt: 'Assinar mensal',
          en: 'Subscribe monthly',
          es: 'Suscribir mensual',
        ),
        icon: Icons.flash_on_outlined,
        planType: 'premium',
        badge: strings.pick(
          pt: 'Mais popular',
          en: 'Most popular',
          es: 'Mas popular',
        ),
        highlighted: true,
      ),
    ];
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final AppSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF111522), Color(0xFF191E2E), Color(0xFF0000CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.pick(
              pt: 'Plano atual',
              en: 'Current plan',
              es: 'Plan actual',
            ),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            strings.pick(
              pt: 'Gerencie cobranca, periodo atual e proximos passos do seu acesso.',
              en: 'Manage billing, current period and next steps for your access.',
              es: 'Gestiona cobro, periodo actual y proximos pasos de tu acceso.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _CurrentPlanMetric(
                label: strings.pick(pt: 'Plano', en: 'Plan', es: 'Plan'),
                value:
                    subscription?.planType.toUpperCase() ??
                    strings.pick(pt: 'Free', en: 'Free', es: 'Gratis'),
              ),
              _CurrentPlanMetric(
                label: strings.pick(pt: 'Status', en: 'Status', es: 'Estado'),
                value:
                    subscription?.status.toUpperCase() ??
                    strings.pick(
                      pt: 'Sem assinatura',
                      en: 'No subscription',
                      es: 'Sin suscripcion',
                    ),
              ),
              _CurrentPlanMetric(
                label: strings.pick(
                  pt: 'Proximo vencimento',
                  en: 'Next due date',
                  es: 'Proximo vencimiento',
                ),
                value: subscription?.expiresAt == null
                    ? strings.pick(
                        pt: 'Sem vencimento',
                        en: 'No due date',
                        es: 'Sin vencimiento',
                      )
                    : '${subscription!.expiresAt!.day.toString().padLeft(2, '0')}/${subscription!.expiresAt!.month.toString().padLeft(2, '0')}/${subscription!.expiresAt!.year}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCheckoutNotice extends StatelessWidget {
  const _PendingCheckoutNotice({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFF27D17F)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.pick(
                  pt: 'Pagamento em andamento. Assim que o Asaas confirmar, o Premium entra sozinho aqui no app.',
                  en: 'Payment in progress. Once Asaas confirms it, Premium turns on automatically in the app.',
                  es: 'Pago en curso. Cuando Asaas lo confirme, Premium se activa automaticamente en la app.',
                ),
              ),
            ),
            TextButton(
              onPressed: onRefresh,
              child: Text(
                strings.pick(pt: 'Atualizar', en: 'Refresh', es: 'Actualizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionManagementCard extends StatelessWidget {
  const _SubscriptionManagementCard({
    required this.subscription,
    required this.busy,
    required this.onCancel,
    required this.onChangePlan,
  });

  final AppSubscription subscription;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final hasCancel = subscription.hasCancelRequest;
    final hasChange = subscription.hasScheduledPlanChange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Controle do plano',
                en: 'Plan control',
                es: 'Control del plan',
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasCancel
                  ? strings.pick(
                      pt: 'Seu pedido de cancelamento ja esta na fila. O acesso continua ate a confirmacao.',
                      en: 'Your cancellation request is already in line. Access stays on until confirmation.',
                      es: 'Tu pedido de cancelacion ya esta en fila. El acceso sigue hasta la confirmacion.',
                    )
                  : hasChange
                  ? strings.pick(
                      pt: 'A troca de plano ja ficou anotada para o proximo ciclo.',
                      en: 'The plan change is already scheduled for the next cycle.',
                      es: 'El cambio de plan ya quedo programado para el proximo ciclo.',
                    )
                  : strings.pick(
                      pt: 'Aqui voce acompanha pendencias e pede alteracoes sem criar outro checkout sem querer.',
                      en: 'Track pending items and request changes without creating another checkout by accident.',
                      es: 'Acompana pendientes y pide cambios sin crear otro checkout por accidente.',
                    ),
            ),
            if (subscription.cancelRequestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                strings.pick(
                  pt: 'Cancelamento pedido em ${_shortDate(subscription.cancelRequestedAt!)}',
                  en: 'Cancellation requested on ${_shortDate(subscription.cancelRequestedAt!)}',
                  es: 'Cancelacion solicitada el ${_shortDate(subscription.cancelRequestedAt!)}',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (subscription.scheduledPlanStartsAt != null) ...[
              const SizedBox(height: 8),
              Text(
                strings.pick(
                  pt: 'Troca prevista para ${_shortDate(subscription.scheduledPlanStartsAt!)}',
                  en: 'Change expected on ${_shortDate(subscription.scheduledPlanStartsAt!)}',
                  es: 'Cambio previsto para ${_shortDate(subscription.scheduledPlanStartsAt!)}',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: busy || hasCancel ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                    hasCancel
                        ? strings.pick(
                            pt: 'Ja solicitado',
                            en: 'Already requested',
                            es: 'Ya solicitado',
                          )
                        : strings.pick(
                            pt: 'Cancelar plano',
                            en: 'Cancel plan',
                            es: 'Cancelar plan',
                          ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy || hasChange ? null : onChangePlan,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(
                    hasChange
                        ? strings.pick(
                            pt: 'Troca anotada',
                            en: 'Change saved',
                            es: 'Cambio guardado',
                          )
                        : strings.pick(
                            pt: 'Trocar no ciclo',
                            en: 'Change next cycle',
                            es: 'Cambiar en el ciclo',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _CurrentPlanMetric extends StatelessWidget {
  const _CurrentPlanMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BillingCycleBar extends StatelessWidget {
  const _BillingCycleBar({
    required this.annualBilling,
    required this.onChanged,
  });

  final bool annualBilling;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: isDark ? const Color(0xFF0F1320) : Colors.white,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: Text(
                  strings.pick(pt: 'Mensal', en: 'Monthly', es: 'Mensual'),
                ),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(
                  strings.pick(pt: 'Anual', en: 'Yearly', es: 'Anual'),
                ),
              ),
            ],
            selected: {annualBilling},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF27D17F).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.pick(
                pt: annualBilling ? 'Economia no anual' : 'Cobranca recorrente',
                en: annualBilling ? 'Yearly savings' : 'Recurring billing',
                es: annualBilling ? 'Ahorro anual' : 'Cobro recurrente',
              ),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: const Color(0xFF27D17F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
    required this.busy,
    required this.blockedReason,
    required this.onTap,
  });

  final _DriverPlanCardData plan;
  final bool busy;
  final String? blockedReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: plan.highlighted
              ? const Color(0xFF0000CD)
              : theme.dividerColor,
        ),
        boxShadow: plan.highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF0000CD).withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.badge != null) ...[
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0000CD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0000CD).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(plan.icon, color: const Color(0xFF7582FF)),
          ),
          const SizedBox(height: 18),
          Text(plan.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(plan.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          Text(
            AppFormat.of(context).currency(plan.price),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(plan.caption, style: theme.textTheme.bodySmall),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF27D17F),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: plan.planType == null
                ? OutlinedButton(
                    onPressed: null,
                    child: Text(
                      strings.pick(
                        pt: 'Plano base',
                        en: 'Base plan',
                        es: 'Plan base',
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: busy ? null : onTap,
                    child: Text(blockedReason ?? plan.buttonLabel),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DriverPlanCardData {
  const _DriverPlanCardData({
    required this.title,
    required this.description,
    required this.price,
    required this.caption,
    required this.features,
    required this.buttonLabel,
    required this.icon,
    this.planType,
    this.badge,
    this.highlighted = false,
  });

  final String title;
  final String description;
  final double price;
  final String caption;
  final List<String> features;
  final String buttonLabel;
  final IconData icon;
  final String? planType;
  final String? badge;
  final bool highlighted;
}
