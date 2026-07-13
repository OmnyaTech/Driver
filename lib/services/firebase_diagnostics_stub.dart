final class FirebaseDiagnostics {
  const FirebaseDiagnostics._();

  static Future<void> initialize() async {
    // Web/local preview keeps diagnostics optional so FlutterFire plugin drift
    // never blocks the app from opening.
  }
}
