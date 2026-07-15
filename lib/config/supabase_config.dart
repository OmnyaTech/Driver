final class SupabaseRuntimeConfig {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );
  static const driverApkUrl = String.fromEnvironment(
    'DRIVER_APK_URL',
    defaultValue:
        'https://cattokugqanpagleawpw.supabase.co/storage/v1/object/public/driver-mobile-releases/driver-latest.apk',
  );

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && turnstileSiteKey.isNotEmpty;
}
