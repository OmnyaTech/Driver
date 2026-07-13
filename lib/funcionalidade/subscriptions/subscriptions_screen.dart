import 'package:flutter/material.dart';

import '../../models/app_subscription.dart';
import '../../services/billing_service.dart';
import '../../services/subscription_service.dart';
import '../../utilities/localization/app_format.dart';
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
        _errorMessage =
            'Nao foi possivel carregar os dados de assinatura agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Assinatura',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentPlan = _subscriptionService.currentSubscription(
      _subscriptions,
    );
    final planCards = _annualBilling ? _annualPlans : _monthlyPlans;
    final hasPendingCheckout = currentPlan?.isPending ?? false;
    final hasActivePlan = currentPlan?.isActive ?? false;
    final checkoutBlockReason = _checkoutBlockReason(
      hasPendingCheckout: hasPendingCheckout,
      hasActivePlan: hasActivePlan,
    );

    return OmnyaSubPageScaffold(
      title: 'Assinatura',
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              'Planos e assinatura',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o nivel ideal do Omnya Driver para desbloquear mais operacao, multiplas plataformas e historico estendido.',
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
                      'Historico de assinatura',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_subscriptions.isEmpty)
                      const Text('Nenhum historico de assinatura encontrado.'),
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
                              'Inicio ${_formatDate(subscription.startedAt!)}',
                            if (subscription.expiresAt != null)
                              'Expira ${_formatDate(subscription.expiresAt!)}',
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
                      'Eventos de billing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_billingEvents.isEmpty)
                      const Text('Nenhum evento de billing registrado ainda.'),
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
          _errorMessage = 'Nao foi possivel abrir o checkout do Asaas.';
        });
      } else {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout aberto. Seu plano fica pendente ate o pagamento cair.',
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
      await _subscriptionService.requestCancellation();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido registrado. Seu acesso segue normal ate a equipe confirmar o cancelamento.',
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
      await _subscriptionService.requestPlanChange(planType);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Troca registrada para o proximo ciclo. Vamos te avisar quando virar.',
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
    if (hasActivePlan) return 'Plano ativo';
    if (hasPendingCheckout) return 'Pagamento pendente';
    return null;
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final AppSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Plano atual',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Gerencie cobranca, periodo atual e proximos passos do seu acesso.',
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
                label: 'Plano',
                value: subscription?.planType.toUpperCase() ?? 'Free',
              ),
              _CurrentPlanMetric(
                label: 'Status',
                value: subscription?.status.toUpperCase() ?? 'Sem assinatura',
              ),
              _CurrentPlanMetric(
                label: 'Proximo vencimento',
                value: subscription?.expiresAt == null
                    ? 'Sem vencimento'
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFF27D17F)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pagamento em andamento. Assim que o Asaas confirmar, o Premium entra sozinho aqui no app.',
              ),
            ),
            TextButton(onPressed: onRefresh, child: const Text('Atualizar')),
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
    final hasCancel = subscription.hasCancelRequest;
    final hasChange = subscription.hasScheduledPlanChange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controle do plano', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hasCancel
                  ? 'Seu pedido de cancelamento ja esta na fila. O acesso continua ate a confirmacao.'
                  : hasChange
                  ? 'A troca de plano ja ficou anotada para o proximo ciclo.'
                  : 'Aqui voce acompanha pendencias e pede alteracoes sem criar outro checkout sem querer.',
            ),
            if (subscription.cancelRequestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cancelamento pedido em ${_shortDate(subscription.cancelRequestedAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (subscription.scheduledPlanStartsAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Troca prevista para ${_shortDate(subscription.scheduledPlanStartsAt!)}',
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
                  label: Text(hasCancel ? 'Ja solicitado' : 'Cancelar plano'),
                ),
                FilledButton.icon(
                  onPressed: busy || hasChange ? null : onChangePlan,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(hasChange ? 'Troca anotada' : 'Trocar no ciclo'),
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
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Mensal')),
              ButtonSegment<bool>(value: true, label: Text('Anual')),
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
              annualBilling ? 'Economia no anual' : 'Cobranca recorrente',
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
                    child: const Text('Plano base'),
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

const List<_DriverPlanCardData> _monthlyPlans = [
  _DriverPlanCardData(
    title: 'Gratis',
    description: 'Para organizar o basico do mes atual com o essencial.',
    price: 0,
    caption: 'sem custo',
    features: [
      '1 plataforma ativa por conta',
      'Cadastro de jornadas, despesas e objetivos',
      'Relatorios operacionais do periodo',
      'Perfil publico opcional',
    ],
    buttonLabel: 'Plano base',
    icon: Icons.shield_outlined,
  ),
  _DriverPlanCardData(
    title: 'Premium mensal',
    description:
        'Para ganhar ritmo com historico, multiplas fontes e mais controle.',
    price: 14.90,
    caption: 'cobranca mensal',
    features: [
      'Multiplas plataformas ativas',
      'Mais veiculos e operacao expandida',
      'Historico ampliado de uso',
      'Checkout e cobranca recorrente',
    ],
    buttonLabel: 'Assinar mensal',
    icon: Icons.flash_on_outlined,
    planType: 'premium',
    badge: 'Mais popular',
    highlighted: true,
  ),
];

const List<_DriverPlanCardData> _annualPlans = [
  _DriverPlanCardData(
    title: 'Gratis',
    description: 'Entrada sem custo para iniciar os registros do dia a dia.',
    price: 0,
    caption: 'sem custo',
    features: [
      '1 plataforma ativa por conta',
      'Historico operacional inicial',
      'Metas e saldo do motorista',
      'Tema claro/escuro e perfil base',
    ],
    buttonLabel: 'Plano base',
    icon: Icons.shield_outlined,
  ),
  _DriverPlanCardData(
    title: 'Premium anual',
    description: 'Melhor custo para manter a operacao completa o ano inteiro.',
    price: 149.90,
    caption: 'cobranca anual',
    features: [
      'Multiplas plataformas e veiculos',
      'Historico e uso expandido',
      'Gestao completa com menor custo mensal',
      'Checkout anual no Asaas',
    ],
    buttonLabel: 'Assinar anual',
    icon: Icons.workspace_premium_outlined,
    planType: 'premium',
    badge: 'Economize no anual',
    highlighted: true,
  ),
];
