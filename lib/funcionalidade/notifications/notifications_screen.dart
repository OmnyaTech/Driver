import 'package:flutter/material.dart';

import '../../funcionalidade/gamification/gamification_screen.dart';
import '../../funcionalidade/goals/goals_screen.dart';
import '../../funcionalidade/journeys/journeys_screen.dart';
import '../../funcionalidade/reports/reports_screen.dart';
import '../../models/app_driver_notification.dart';
import '../../services/engagement_notification_service.dart';
import '../../utilities/ui/omnya_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final EngagementNotificationService _service =
      EngagementNotificationService();
  bool _loading = true;
  String? _errorMessage;
  List<AppDriverNotification> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.syncSmartNotifications();
      final items = await _service.listNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _errorMessage =
            'Nao consegui buscar seus avisos agora. Tente atualizar em alguns segundos.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Avisos',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return OmnyaSubPageScaffold(
      title: 'Avisos',
      actions: [
        TextButton(
          onPressed: _items.where((item) => !item.isRead).isEmpty
              ? null
              : () async {
                  await _service.markAllAsRead();
                  await _load();
                },
          child: const Text('Ler tudo'),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: _items.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _errorMessage == null
                                ? Icons.notifications_none_outlined
                                : Icons.wifi_tethering_error_rounded,
                            size: 34,
                            color: const Color(0xFF7582FF),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage == null
                                ? 'Tudo em ordem por aqui'
                                : 'Avisos pausados',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage ??
                                'Aqui entram lembretes de jornada, metas, desempenho e reserva.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0000CD,
                          ).withValues(alpha: item.isRead ? 0.08 : 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_iconForKind(item.kind)),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.body),
                      trailing: item.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27D17F),
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () async {
                        if (!item.isRead) {
                          await _service.markAsRead(item.id);
                          await _load();
                        }
                        if (!context.mounted) return;
                        _openAction(context, item);
                      },
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: _items.length,
              ),
      ),
    );
  }

  IconData _iconForKind(String kind) {
    return switch (kind) {
      'journey' => Icons.route_outlined,
      'goal' => Icons.savings_outlined,
      'gamification' => Icons.workspace_premium_outlined,
      'performance' => Icons.insights_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  void _openAction(BuildContext context, AppDriverNotification item) {
    final page = switch (item.actionType) {
      'journeys' => const JourneysScreen(),
      'goals' => const GoalsScreen(),
      'gamification' => const GamificationScreen(),
      'reports' => const ReportsScreen(),
      _ => null,
    };

    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
