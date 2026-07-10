import 'auth_service.dart';

class PublicProfileSettings {
  const PublicProfileSettings({
    required this.publicProfileEnabled,
    required this.publicSlug,
    required this.publicBio,
    required this.publicCity,
    required this.rankingOptIn,
  });

  final bool publicProfileEnabled;
  final String? publicSlug;
  final String? publicBio;
  final String? publicCity;
  final bool rankingOptIn;
}

class PublicProfileService {
  PublicProfileService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<PublicProfileSettings> loadSettings() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final profiles = await client
        .schema('driver')
        .from('profiles')
        .select('public_profile_enabled, public_slug, public_bio, public_city')
        .eq('id', user.id)
        .limit(1);

    final progress = await client
        .schema('driver')
        .from('driver_progress')
        .select('ranking_opt_in')
        .eq('user_id', user.id)
        .limit(1);

    final profile = profiles.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(profiles.first);
    final ranking = progress.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(progress.first);

    return PublicProfileSettings(
      publicProfileEnabled: profile['public_profile_enabled'] as bool? ?? false,
      publicSlug: profile['public_slug'] as String?,
      publicBio: profile['public_bio'] as String?,
      publicCity: profile['public_city'] as String?,
      rankingOptIn: ranking['ranking_opt_in'] as bool? ?? false,
    );
  }

  Future<void> updateSettings({
    required bool publicProfileEnabled,
    required String? publicSlug,
    required String? publicBio,
    required String? publicCity,
    required bool rankingOptIn,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client
        .schema('driver')
        .from('profiles')
        .update({
          'public_profile_enabled': publicProfileEnabled,
          'public_slug': _normalize(publicSlug),
          'public_bio': _normalize(publicBio),
          'public_city': _normalize(publicCity),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    await client.schema('driver').from('driver_progress').upsert({
      'user_id': user.id,
      'ranking_opt_in': rankingOptIn,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'last_calculated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
