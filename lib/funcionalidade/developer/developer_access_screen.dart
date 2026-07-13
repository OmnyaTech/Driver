import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_admin_audit_log.dart';
import '../../models/app_subscription.dart';
import '../../services/developer_admin_service.dart';
import '../../services/subscription_service.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';

class DeveloperAccessScreen extends StatefulWidget {
  const DeveloperAccessScreen({super.key});

  @override
  State<DeveloperAccessScreen> createState() => _DeveloperAccessScreenState();
}

class _DeveloperAccessScreenState extends State<DeveloperAccessScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final DeveloperAdminService _developerAdminService = DeveloperAdminService();
  bool _loading = true;
  List<AppSubscription> _subscriptions = const [];
  List<AppAdminAuditLog> _auditLogs = const [];
  Map<String, dynamic> _metrics = const {};
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
      final auditLogs = await _developerAdminService.listAuditLogs();
      final metrics = await _developerAdminService.loadMetrics();
      if (!mounted) return;
      setState(() {
        _subscriptions = subscriptions;
        _auditLogs = auditLogs;
        _metrics = metrics;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar a area administrativa agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;

    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Developer',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final content = RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Developer e acessos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conta atual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Email: ${profile?.email ?? '-'}'),
                  Text('Plano: ${profile?.planType.name ?? '-'}'),
                  Text('Papel: ${profile?.role.name ?? '-'}'),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DeveloperMetricsCard(metrics: _metrics),
          const SizedBox(height: 16),
          _LookupProfileCard(service: _developerAdminService),
          const SizedBox(height: 16),
          _GrantAccessCard(
            service: _developerAdminService,
            onUpdated: _loadData,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditoria administrativa',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_auditLogs.isEmpty)
                    const Text(
                      'Nenhum evento administrativo foi registrado ainda.',
                    ),
                  ..._auditLogs.map(
                    (log) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(log.action),
                      subtitle: Text(
                        [
                          if (log.summary != null &&
                              log.summary!.trim().isNotEmpty)
                            log.summary!,
                          if (log.actorEmail != null) 'ator: ${log.actorEmail}',
                          if (log.targetEmail != null)
                            'destino: ${log.targetEmail}',
                          _formatDateTime(log.createdAt),
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
                    'Historico da conta atual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_subscriptions.isEmpty)
                    const Text(
                      'Nenhum registro administrativo ou de assinatura foi encontrado ainda.',
                    ),
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
        ],
      ),
    );

    return OmnyaSubPageScaffold(title: 'Developer', body: content);
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

class _DeveloperMetricsCard extends StatelessWidget {
  const _DeveloperMetricsCard({required this.metrics});

  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final cards = <(String, String, IconData)>[
      ('Usuarios', _value(metrics, 'users', 'total'), Icons.people_outline),
      ('Ativos hoje', _value(metrics, 'activity', 'dau'), Icons.bolt_outlined),
      (
        'Ativos no mes',
        _value(metrics, 'activity', 'mau'),
        Icons.calendar_month_outlined,
      ),
      (
        'Assinantes',
        _value(metrics, 'billing', 'active'),
        Icons.workspace_premium_outlined,
      ),
      (
        'Checkouts pendentes',
        _value(metrics, 'billing', 'pending'),
        Icons.hourglass_top_rounded,
      ),
      (
        'Dispositivos push',
        _value(metrics, 'devices', 'push_enabled'),
        Icons.notifications_active_outlined,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Painel do produto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 900
                    ? 3
                    : width >= 560
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: (width - (12 * (columns - 1))) / columns,
                          child: _DeveloperMetricTile(
                            title: card.$1,
                            value: card.$2,
                            icon: card.$3,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _value(Map<String, dynamic> source, String group, String key) {
    final nested = source[group];
    if (nested is! Map) return '0';
    return (nested[key] ?? 0).toString();
  }
}

class _DeveloperMetricTile extends StatelessWidget {
  const _DeveloperMetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7582FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupProfileCard extends StatefulWidget {
  const _LookupProfileCard({required this.service});

  final DeveloperAdminService service;

  @override
  State<_LookupProfileCard> createState() => _LookupProfileCardState();
}

class _LookupProfileCardState extends State<_LookupProfileCard> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  AdminAccessProfile? _profile;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consultar usuario por e-mail',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _lookup,
              child: const Text('Consultar'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_profile != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome: ${_profile!.displayName ?? _profile!.fullName ?? '-'}',
                    ),
                    Text('Plano: ${_profile!.planType}'),
                    Text('Papel: ${_profile!.role}'),
                    Text('Status: ${_profile!.subscriptionStatus}'),
                    Text(
                      'Onboarding: ${_profile!.onboardingCompletedAt == null ? 'pendente' : 'concluido'}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _lookup() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _profile = null;
    });

    try {
      final profile = await widget.service.lookupProfileByEmail(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (profile == null) {
          _errorMessage = 'Nenhum usuario foi encontrado para esse e-mail.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _GrantAccessCard extends StatefulWidget {
  const _GrantAccessCard({required this.service, required this.onUpdated});

  final DeveloperAdminService service;
  final Future<void> Function() onUpdated;

  @override
  State<_GrantAccessCard> createState() => _GrantAccessCardState();
}

class _GrantAccessCardState extends State<_GrantAccessCard> {
  final _emailController = TextEditingController();
  String _planType = 'gift';
  String _role = 'user';
  DateTime? _expiresAt;
  bool _saving = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplicar acesso manual',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail destino'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _planType,
              decoration: const InputDecoration(labelText: 'Plano'),
              items: const [
                DropdownMenuItem(value: 'free', child: Text('Free')),
                DropdownMenuItem(value: 'premium', child: Text('Premium')),
                DropdownMenuItem(value: 'gift', child: Text('Gift')),
                DropdownMenuItem(value: 'developer', child: Text('Developer')),
              ],
              onChanged: (value) => setState(() => _planType = value ?? 'gift'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Papel'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'developer', child: Text('Developer')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'user'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiracao opcional'),
              subtitle: Text(
                _expiresAt == null
                    ? 'Sem expiracao definida'
                    : _formatDate(_expiresAt!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: const Text('Aplicar acesso'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _expiresAt = null),
                  child: const Text('Limpar expiracao'),
                ),
              ],
            ),
            if (_feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    color: _feedbackIsError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initialDate =
        _expiresAt ?? DateTime.now().add(const Duration(days: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      _expiresAt = DateTime(date.year, date.month, date.day, 23, 59, 59);
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    try {
      final message = await widget.service.grantAccess(
        email: _emailController.text,
        planType: _planType,
        role: _role,
        expiresAt: _expiresAt,
      );
      await widget.onUpdated();
      if (!mounted) return;
      setState(() {
        _feedbackMessage = message;
        _feedbackIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = error.toString();
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
