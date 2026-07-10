import 'package:flutter/material.dart';

import '../../models/app_subscription.dart';
import '../../services/billing_service.dart';
import '../../services/subscription_service.dart';
import '../../utilities/ui/omnya_shell.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final BillingService _billingService = BillingService();
  bool _loading = true;
  bool _creatingCheckout = false;
  List<AppSubscription> _subscriptions = const [];
  List<BillingEventItem> _billingEvents = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    final content = RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Planos e assinatura',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _PlanCard(
                title: 'Premium mensal',
                subtitle: 'Recorrencia mensal hospedada no Asaas.',
                buttonLabel: 'Assinar mensal',
                busy: _creatingCheckout,
                onTap: () => _startCheckout(
                  planType: 'premium',
                  billingCycle: 'MONTHLY',
                ),
              ),
              _PlanCard(
                title: 'Premium anual',
                subtitle: 'Recorrencia anual hospedada no Asaas.',
                buttonLabel: 'Assinar anual',
                busy: _creatingCheckout,
                onTap: () =>
                    _startCheckout(planType: 'premium', billingCycle: 'YEARLY'),
              ),
            ],
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
                        '${subscription.planType} - ${subscription.status}',
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
    );

    return OmnyaSubPageScaffold(title: 'Assinatura', body: content);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout aberto no provedor de pagamento.'),
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${_formatDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.busy,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : onTap,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
