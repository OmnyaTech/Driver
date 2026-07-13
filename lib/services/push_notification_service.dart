import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class PushNotificationService {
  PushNotificationService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  static const _deviceIdKey = 'driver_push_device_id';
  final AuthService _authService;
  bool _firebaseTried = false;
  bool _firebaseReady = false;

  Future<void> registerDeviceIfPossible() async {
    final client = _authService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final ready = await _ensureFirebase();
    if (!ready) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final fcmToken = await messaging.getToken();
      final apnsToken = await _apnsToken(messaging);
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
      // Missing Firebase files or web VAPID keys should not prevent app usage.
    }
  }

  Future<void> enqueuePush({
    required String targetUserId,
    required String notificationType,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    DateTime? scheduledAt,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .rpc(
          'enqueue_driver_push',
          params: {
            'p_target_user_id': targetUserId,
            'p_notification_type': notificationType,
            'p_title': title,
            'p_body': body,
            'p_data': data,
            'p_notification_key':
                '$notificationType:${scheduledAt?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String()}',
            'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
          },
        );
  }

  Future<bool> _ensureFirebase() async {
    if (_firebaseTried) return _firebaseReady;
    _firebaseTried = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
    }

    return _firebaseReady;
  }

  Future<String?> _apnsToken(FirebaseMessaging messaging) async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return null;
    }
    try {
      return messaging.getAPNSToken();
    } catch (_) {
      return null;
    }
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
