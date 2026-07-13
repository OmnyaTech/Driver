import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductAnalyticsService {
  const ProductAnalyticsService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> track(
    String eventName, {
    String? screen,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _client.rpc(
        'track_product_event',
        params: {
          'p_event_name': eventName,
          'p_screen': screen,
          'p_metadata': metadata,
          'p_app_version': 'web',
          'p_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        },
      );
    } catch (_) {
      // Analytics must never block the driver flow.
    }
  }
}
