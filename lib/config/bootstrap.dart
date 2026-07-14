import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/active_journey_notification_service.dart';
import '../services/device_notification_service.dart';
import '../services/firebase_diagnostics.dart';
import 'supabase_config.dart';

final class AppBootstrap {
  static Future<void> initialize() async {
    try {
      await DeviceNotificationService.instance.initialize();
      await ActiveJourneyNotificationService.instance.initialize();
    } catch (_) {
      // Local notification setup cannot block the first Flutter frame.
    }
    await _initializeFirebaseDiagnostics();

    if (!SupabaseRuntimeConfig.isConfigured) {
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseRuntimeConfig.url,
        publishableKey: SupabaseRuntimeConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          authFlowType: AuthFlowType.pkce,
        ),
      );
    } catch (_) {
      // A bad runtime config should not leave the APK on a black screen.
    }
  }

  static Future<void> _initializeFirebaseDiagnostics() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await FirebaseDiagnostics.initialize();
    } catch (_) {
      // Diagnostics cannot block the app startup.
    }
  }
}
