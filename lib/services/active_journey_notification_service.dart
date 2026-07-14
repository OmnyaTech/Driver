import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const _androidChannel = MethodChannel(
    'br.com.omnyatech.omnyadriver/android',
  );
  static const String _finishRequestedKey =
      'omnya_driver_finish_active_journey_requested';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('ic_stat_driver');
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
        ? 'Toque para informar km final, entregas e ganhos antes de encerrar.'
        : '$vehicle em jornada. Toque para informar km final, entregas e ganhos.';

    final foregroundStarted = await _startForegroundJourney(draft, body);
    if (defaultTargetPlatform == TargetPlatform.android && foregroundStarted) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        icon: 'ic_stat_driver',
        channelDescription:
            'Mostra que existe uma jornada em andamento no Driver.',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        silent: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: draft.startedAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: false,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.progress,
        actions: const [
          AndroidNotificationAction(
            'open_active_journey',
            'Finalizar com dados',
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
      'Jornada em andamento',
      body,
      details,
      payload: 'active_journey',
    );
  }

  Future<void> cancelActiveJourney() async {
    if (kIsWeb) return;
    await initialize();
    await _stopForegroundJourney();
    await _notifications.cancel(_notificationId);
  }

  Future<bool> _startForegroundJourney(
    ActiveJourneyDraft draft,
    String body,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _androidChannel
              .invokeMethod<bool>('startActiveJourneyForeground', {
                'startedAt': draft.startedAt.millisecondsSinceEpoch,
                'title': 'Jornada em andamento',
                'body': body,
              }) ??
          false;
    } catch (_) {
      // The plugin notification remains as a fallback.
      return false;
    }
  }

  Future<void> _stopForegroundJourney() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _androidChannel.invokeMethod<void>('stopActiveJourneyForeground');
    } catch (_) {
      // Best effort; the local notification is still cancelled below.
    }
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
