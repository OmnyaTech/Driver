import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'push_messaging_adapter.dart';

class PushNotificationService {
  PushNotificationService({
    AuthService? authService,
    PushMessagingAdapter? messagingAdapter,
  }) : _authService = authService ?? const AuthService(),
       _messagingAdapter = messagingAdapter ?? const PushMessagingAdapter();

  static const _deviceIdKey = 'driver_push_device_id';
  final AuthService _authService;
  final PushMessagingAdapter _messagingAdapter;

  Future<void> registerDeviceIfPossible() async {
    final client = _authService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final ready = await _messagingAdapter.initialize();
    if (!ready) return;

    try {
      final tokenBundle = await _messagingAdapter.requestTokenBundle();
      if (tokenBundle == null || tokenBundle.permissionDenied) return;

      final fcmToken = tokenBundle.fcmToken;
      final apnsToken = tokenBundle.apnsToken;
      if ((fcmToken == null || fcmToken.isEmpty) &&
          (apnsToken == null || apnsToken.isEmpty)) {
        return;
      }

      final deviceId = await _deviceId();
      await client.schema('driver').from('driver_push_devices').upsert({
        'user_id': user.id,
        'device_id': deviceId,
        'platform': _platformName(),
        'fcm_token': fcmToken,
        'apns_token': apnsToken,
        'enabled': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,device_id');
    } catch (_) {
      // Missing Firebase files or web VAPID keys must not prevent app usage.
    }
  }

  Future<void> enqueuePush({
    required String targetUserId,
    required String notificationType,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? notificationKey,
    DateTime? scheduledAt,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .rpc(
          'enqueue_driver_push',
          params: {
            'p_user_id': targetUserId,
            'p_event_type': notificationType,
            'p_title': title,
            'p_body': body,
            'p_payload': data,
            'p_notification_key':
                notificationKey ??
                '$notificationType:${scheduledAt?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String()}',
            'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
          },
        );
  }

  Future<String> _deviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final value =
        'driver-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 32)}';
    await preferences.setString(_deviceIdKey, value);
    return value;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
