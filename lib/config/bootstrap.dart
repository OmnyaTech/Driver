import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/active_journey_notification_service.dart';
import 'supabase_config.dart';

final class AppBootstrap {
  static Future<void> initialize() async {
    await ActiveJourneyNotificationService.instance.initialize();

    if (!SupabaseRuntimeConfig.isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: SupabaseRuntimeConfig.url,
      publishableKey: SupabaseRuntimeConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}
