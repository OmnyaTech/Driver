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
  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && turnstileSiteKey.isNotEmpty;
}
