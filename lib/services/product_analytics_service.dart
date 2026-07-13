import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_product_telemetry.dart';

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
      await FirebaseProductTelemetry.track(
        eventName,
        screen: screen,
        metadata: metadata,
        platform: platform,
      );
    } catch (error, stackTrace) {
      await _recordNonFatal(error, stackTrace, reason: 'firebase_analytics');
    }
  }

  Future<void> _recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    if (kIsWeb) return;
    await FirebaseProductTelemetry.recordNonFatal(
      error,
      stackTrace,
      reason: reason,
    );
  }
}
