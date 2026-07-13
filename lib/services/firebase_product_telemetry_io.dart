import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final class FirebaseProductTelemetry {
  const FirebaseProductTelemetry._();

  static Future<void> track(
    String eventName, {
    String? screen,
    required Map<String, dynamic> metadata,
    required String platform,
  }) async {
    await _ensureFirebase();
    await FirebaseAnalytics.instance.logEvent(
      name: _firebaseEventName(eventName),
      parameters: {
        if (screen != null && screen.isNotEmpty) 'screen': screen,
        'platform': platform,
        ..._firebaseParameters(metadata),
      },
    );
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    try {
      await _ensureFirebase();
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      // Crash reporting must never block analytics.
    }
  }

  static Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  static String _firebaseEventName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final cleaned = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = cleaned.isEmpty ? 'driver_event' : cleaned;
    return safe.length <= 40 ? safe : safe.substring(0, 40);
  }

  static Map<String, Object> _firebaseParameters(
    Map<String, dynamic> metadata,
  ) {
    final result = <String, Object>{};
    metadata.forEach((key, value) {
      if (value == null) return;
      final safeKey = key
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      if (safeKey.isEmpty) return;
      final normalizedKey = safeKey.length <= 40
          ? safeKey
          : safeKey.substring(0, 40);
      if (value is num || value is String || value is bool) {
        result[normalizedKey] = value;
      } else {
        result[normalizedKey] = value.toString();
      }
    });
    return result;
  }
}
