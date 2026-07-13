import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

final class PushMessagingTokenBundle {
  const PushMessagingTokenBundle({
    this.fcmToken,
    this.apnsToken,
    this.permissionDenied = false,
  });

  final String? fcmToken;
  final String? apnsToken;
  final bool permissionDenied;
}

final class PushMessagingAdapter {
  const PushMessagingAdapter();

  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PushMessagingTokenBundle?> requestTokenBundle() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return const PushMessagingTokenBundle(permissionDenied: true);
    }

    return PushMessagingTokenBundle(
      fcmToken: await messaging.getToken(),
      apnsToken: await _apnsToken(messaging),
    );
  }

  Future<String?> _apnsToken(FirebaseMessaging messaging) async {
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
}
