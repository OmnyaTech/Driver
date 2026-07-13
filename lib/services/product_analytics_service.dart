import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductAnalyticsService {
  const ProductAnalyticsService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> track(
    String eventName, {
    String? screen,
    Map<String, dynamic> metadata = const {},
  }) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    await _trackFirebase(
      eventName,
      screen: screen,
      metadata: metadata,
      platform: platform,
    );

    try {
      await _client.rpc(
        'track_product_event',
        params: {
          'p_event_name': eventName,
          'p_screen': screen,
          'p_metadata': metadata,
          'p_app_version': 'web',
          'p_platform': platform,
        },
      );
    } catch (error, stackTrace) {
      await _recordNonFatal(error, stackTrace, reason: 'product_event_rpc');
      // Analytics must never block the driver flow.
    }
  }

  Future<void> _trackFirebase(
    String eventName, {
    String? screen,
    required Map<String, dynamic> metadata,
    required String platform,
  }) async {
    try {
      await _ensureFirebase();
      await FirebaseAnalytics.instance.logEvent(
        name: _firebaseEventName(eventName),
        parameters: {
          if (screen != null && screen.isNotEmpty) 'screen': screen,
          'platform': platform,
          ..._firebaseParameters(metadata),
        },
      );
    } catch (error, stackTrace) {
      await _recordNonFatal(error, stackTrace, reason: 'firebase_analytics');
    }
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  String _firebaseEventName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final cleaned = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = cleaned.isEmpty ? 'driver_event' : cleaned;
    return safe.length <= 40 ? safe : safe.substring(0, 40);
  }

  Map<String, Object> _firebaseParameters(Map<String, dynamic> metadata) {
    final result = <String, Object>{};
    metadata.forEach((key, value) {
      if (value == null) return;
      final safeKey = key
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      if (safeKey.isEmpty) return;
      if (value is num || value is String || value is bool) {
        result[safeKey.length <= 40 ? safeKey : safeKey.substring(0, 40)] =
            value;
      } else {
        result[safeKey.length <= 40 ? safeKey : safeKey.substring(0, 40)] =
            value.toString();
      }
    });
    return result;
  }

  Future<void> _recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    if (kIsWeb) return;
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
}
