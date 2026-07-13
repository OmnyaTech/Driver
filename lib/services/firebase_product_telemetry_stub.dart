final class FirebaseProductTelemetry {
  const FirebaseProductTelemetry._();

  static Future<void> track(
    String eventName, {
    String? screen,
    required Map<String, dynamic> metadata,
    required String platform,
  }) async {
    // Firebase Analytics is optional in web preview; product_events remains active.
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    // Crash reporting is optional in web preview.
  }
}
