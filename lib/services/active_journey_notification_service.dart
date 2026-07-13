import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'active_journey_storage_service.dart';

class ActiveJourneyNotificationService {
  ActiveJourneyNotificationService._();

  static final ActiveJourneyNotificationService instance =
      ActiveJourneyNotificationService._();

  static const int _notificationId = 7107;
  static const String _channelId = 'omnya_driver_active_journey';
  static const String _channelName = 'Jornada em andamento';
  static const String _finishRequestedKey =
      'omnya_driver_finish_active_journey_requested';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showActiveJourney(ActiveJourneyDraft draft) async {
    if (kIsWeb) return;
    await initialize();

    final vehicle = draft.vehicleLabel?.trim();
    final body = vehicle == null || vehicle.isEmpty
        ? 'Jornada em andamento. Toque para voltar ao app e encerrar.'
        : '$vehicle em jornada. Toque para voltar ao app e encerrar.';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Mostra que existe uma jornada em andamento no Omnya Driver.',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: true,
        when: draft.startedAt.millisecondsSinceEpoch,
        usesChronometer: true,
        actions: const [
          AndroidNotificationAction(
            'open_active_journey',
            'Encerrar no app',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );

    await _notifications.show(
      _notificationId,
      'Jornada rodando',
      body,
      details,
      payload: 'active_journey',
    );
  }

  Future<void> cancelActiveJourney() async {
    if (kIsWeb) return;
    await initialize();
    await _notifications.cancel(_notificationId);
  }

  Future<bool> consumeFinishRequest() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool(_finishRequestedKey) ?? false;
    if (requested) {
      await prefs.remove(_finishRequestedKey);
    }
    return requested;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId != 'open_active_journey' &&
        response.payload != 'active_journey') {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_finishRequestedKey, true);
  }
}
