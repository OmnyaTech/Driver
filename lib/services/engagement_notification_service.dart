import '../models/app_driver_notification.dart';
import 'auth_service.dart';
import 'dashboard_metrics_service.dart';
import 'device_notification_service.dart';
import 'driver_preference_service.dart';
import 'gamification_service.dart';
import 'goal_service.dart';
import 'journey_service.dart';
import 'push_notification_service.dart';

class EngagementNotificationService {
  EngagementNotificationService({
    AuthService? authService,
    JourneyService? journeyService,
    GoalService? goalService,
    DashboardMetricsService? dashboardMetricsService,
    GamificationService? gamificationService,
    DriverPreferenceService? driverPreferenceService,
    PushNotificationService? pushNotificationService,
    DeviceNotificationService? deviceNotificationService,
  }) : _authService = authService ?? const AuthService(),
       _journeyService =
           journeyService ?? JourneyService(authService: authService),
       _goalService = goalService ?? GoalService(authService: authService),
       _dashboardMetricsService =
           dashboardMetricsService ??
           DashboardMetricsService(authService: authService),
       _gamificationService =
           gamificationService ?? GamificationService(authService: authService),
       _driverPreferenceService =
           driverPreferenceService ?? DriverPreferenceService(),
       _pushNotificationService =
           pushNotificationService ??
           PushNotificationService(authService: authService),
       _deviceNotificationService =
           deviceNotificationService ?? DeviceNotificationService.instance;

  final AuthService _authService;
  final JourneyService _journeyService;
  final GoalService _goalService;
  final DashboardMetricsService _dashboardMetricsService;
  final GamificationService _gamificationService;
  final DriverPreferenceService _driverPreferenceService;
  final PushNotificationService _pushNotificationService;
  final DeviceNotificationService _deviceNotificationService;

  Future<void> syncSmartNotifications() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return;

    final journeys = await _journeyService.listJourneys();
    final balance = await _goalService.loadBalanceSummary();
    final goals = await _goalService.listGoals();
    final summary = await _gamificationService.loadSummary();
    final reservePreference = await _driverPreferenceService
        .loadReservePreference();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayMetrics = await _dashboardMetricsService.loadMetrics(
      startAt: todayStart,
      endAt: now,
    );

    final notifications = <Map<String, dynamic>>[];

    final openJourneys = journeys.where((item) => !item.isFinished).toList();
    if (openJourneys.isNotEmpty) {
      notifications.add(
        _buildNotification(
          userId: user.id,
          key: 'open-journey-${todayStart.toIso8601String()}',
          kind: 'journey',
          title: 'Jornada em aberto',
          body:
              'Tem uma jornada aberta. Se ja terminou, encerre para o app fechar suas contas direitinho.',
          actionType: 'journeys',
        ),
      );
    }

    final finishedToday = journeys.where((item) {
      final endedAt = item.endedAt?.toLocal();
      return endedAt != null && !endedAt.isBefore(todayStart);
    }).toList();
    if (finishedToday.isNotEmpty && balance.availableBalance > 0) {
      final reserve = _driverPreferenceService
          .calculateSuggestedReserve(
            preference: reservePreference,
            netResult: todayMetrics.netResult,
            deliveries: finishedToday.fold<int>(
              0,
              (sum, item) => sum + item.totalDeliveries,
            ),
          )
          .clamp(
            0,
            balance.availableBalance > 0 ? balance.availableBalance : 5000,
          )
          .toDouble();
      final reserveLabel = _driverPreferenceService.buildSuggestionLabel(
        preference: reservePreference,
        amount: reserve,
        periodLabel: 'hoje',
      );
      if (reserve > 0) {
        notifications.add(
          _buildNotification(
            userId: user.id,
            key: 'reserve-${todayStart.toIso8601String()}',
            kind: 'goal',
            title: 'Boa hora para guardar',
            body: reserveLabel,
            actionType: 'goals',
            actionPayload: {'suggested_amount': reserve},
          ),
        );
      }
    }

    final remainingXp = summary.remainingXpToNextLevel;
    if (remainingXp != null && remainingXp <= 120) {
      notifications.add(
        _buildNotification(
          userId: user.id,
          key: 'level-${summary.level + 1}',
          kind: 'gamification',
          title: 'Falta pouco para subir',
          body:
              'So mais $remainingXp XP para subir de nivel e ganhar mais destaque.',
          actionType: 'gamification',
        ),
      );
    }

    for (final goal in goals) {
      final progress = goal.targetAmount <= 0
          ? 0.0
          : goal.currentAmount / goal.targetAmount;
      if (progress >= 0.8 && progress < 1) {
        notifications.add(
          _buildNotification(
            userId: user.id,
            key: 'goal-near-${goal.id}',
            kind: 'goal',
            title: 'Meta quase la',
            body:
                '"${goal.title}" ja passou de ${(progress * 100).toStringAsFixed(0)}%. Falta pouco.',
            actionType: 'goals',
            actionPayload: {'goal_id': goal.id},
          ),
        );
      }
    }

    if (todayMetrics.totalDeliveries >= 10) {
      notifications.add(
        _buildNotification(
          userId: user.id,
          key: 'performance-${todayStart.toIso8601String()}',
          kind: 'performance',
          title: 'Bom ritmo hoje',
          body:
              'Voce ja fez ${todayMetrics.totalDeliveries} entregas hoje. Olhe o melhor horario e tente repetir esse ritmo.',
          actionType: 'reports',
        ),
      );
    }

    if (notifications.isEmpty) return;
    final newNotifications = await _filterNewNotifications(
      user.id,
      notifications,
    );
    await client
        .schema('driver')
        .from('driver_notifications')
        .upsert(notifications, onConflict: 'user_id,notification_key');
    for (final notification in newNotifications) {
      await _enqueueDevicePush(notification);
      await _showLocalDeviceNotification(notification);
    }
    await showUndeliveredUnreadDeviceNotifications();
  }

  Future<List<Map<String, dynamic>>> _filterNewNotifications(
    String userId,
    List<Map<String, dynamic>> notifications,
  ) async {
    final keys = notifications
        .map((notification) => notification['notification_key']?.toString())
        .whereType<String>()
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList();
    if (keys.isEmpty) return notifications;

    try {
      final existingRows = await _authService
          .requireClient()
          .schema('driver')
          .from('driver_notifications')
          .select('notification_key')
          .eq('user_id', userId)
          .inFilter('notification_key', keys);
      final existingKeys = existingRows
          .map<String>((row) => row['notification_key']?.toString() ?? '')
          .where((key) => key.isNotEmpty)
          .toSet();
      return notifications
          .where(
            (notification) => !existingKeys.contains(
              notification['notification_key']?.toString() ?? '',
            ),
          )
          .toList();
    } catch (_) {
      return notifications;
    }
  }

  Future<void> _enqueueDevicePush(Map<String, dynamic> notification) async {
    try {
      await _pushNotificationService.enqueuePush(
        targetUserId: notification['user_id'].toString(),
        notificationType: notification['kind'].toString(),
        title: notification['title'].toString(),
        body: notification['body'].toString(),
        notificationKey: notification['notification_key'].toString(),
        data: {
          'action_type': notification['action_type'],
          'action_payload': notification['action_payload'],
        },
      );
    } catch (_) {
      // In-app notices should still exist even if server push is unavailable.
    }
  }

  Future<void> _showLocalDeviceNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      await _deviceNotificationService.showAlert(
        notificationKey: notification['notification_key'].toString(),
        title: notification['title'].toString(),
        body: notification['body'].toString(),
      );
      await _markDeliveredByKey(notification['notification_key'].toString());
    } catch (_) {
      // Local system notifications should never block in-app notices.
    }
  }

  Future<void> showUndeliveredUnreadDeviceNotifications() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return;

    final rows = await client
        .schema('driver')
        .from('driver_notifications')
        .select('notification_key,title,body')
        .eq('user_id', user.id)
        .isFilter('read_at', null)
        .isFilter('delivered_at', null)
        .order('created_at', ascending: false)
        .limit(5);

    for (final row in rows) {
      final key = row['notification_key']?.toString() ?? '';
      if (key.isEmpty) continue;
      try {
        await _deviceNotificationService.showAlert(
          notificationKey: key,
          title: row['title']?.toString() ?? 'Aviso',
          body: row['body']?.toString() ?? '',
        );
        await _markDeliveredByKey(key);
      } catch (_) {
        // Keep it unread/undelivered so the next sync can try again.
      }
    }
  }

  Future<void> _markDeliveredByKey(String notificationKey) async {
    if (notificationKey.isEmpty) return;
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .schema('driver')
        .from('driver_notifications')
        .update({
          'delivered_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('notification_key', notificationKey)
        .isFilter('read_at', null);
  }

  Future<List<AppDriverNotification>> listNotifications() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('driver_notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map<AppDriverNotification>(
          (row) => AppDriverNotification(
            id: row['id'].toString(),
            notificationKey: row['notification_key']?.toString() ?? '',
            kind: row['kind']?.toString() ?? 'info',
            title: row['title']?.toString() ?? 'Aviso',
            body: row['body']?.toString() ?? '',
            actionType: row['action_type']?.toString(),
            actionPayload: Map<String, dynamic>.from(
              (row['action_payload'] as Map?) ?? const <String, dynamic>{},
            ),
            readAt: _parseDate(row['read_at']),
            deliveredAt: _parseDate(row['delivered_at']),
            createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<int> unreadCount() async {
    final notifications = await listNotifications();
    return notifications.where((item) => !item.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('driver_notifications')
        .update({
          'read_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .schema('driver')
        .from('driver_notifications')
        .update({
          'read_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id)
        .isFilter('read_at', null);
  }

  Map<String, dynamic> _buildNotification({
    required String userId,
    required String key,
    required String kind,
    required String title,
    required String body,
    String? actionType,
    Map<String, dynamic>? actionPayload,
  }) {
    return {
      'user_id': userId,
      'notification_key': key,
      'kind': kind,
      'title': title,
      'body': body,
      'action_type': actionType,
      'action_payload': actionPayload ?? const <String, dynamic>{},
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
