import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DeviceNotificationService {
  DeviceNotificationService._();

  static final DeviceNotificationService instance =
      DeviceNotificationService._();

  static const _androidChannel = MethodChannel(
    'br.com.omnyatech.omnyadriver/android',
  );
  static const _alertsChannelId = 'omnya_driver_alerts';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('ic_stat_driver');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        return await _androidChannel.invokeMethod<bool>(
              'areNotificationsEnabled',
            ) ??
            false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<void> showAlert({
    required String notificationKey,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final id = notificationKey.hashCode & 0x7fffffff;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final shown = await _androidChannel.invokeMethod<bool>(
          'showDriverAlertNotification',
          {'id': id, 'title': title, 'body': body},
        );
        if (shown == true) return;
      } catch (_) {
        // Fall through to the plugin implementation.
      }
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alertsChannelId,
        'Avisos do Driver',
        channelDescription:
            'Avisos importantes sobre jornadas, metas e reservas.',
        icon: 'ic_stat_driver',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(id, title, body, details);
  }
}
