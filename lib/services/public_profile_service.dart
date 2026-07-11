import '../models/app_public_driver.dart';
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

    final normalizedSlug = _normalizeSlug(publicSlug);

    await client
        .schema('driver')
        .from('profiles')
        .update({
          'public_profile_enabled': publicProfileEnabled,
          'public_slug': normalizedSlug,
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
    }, onConflict: 'user_id');
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<String> ensureInviteSlug({
    PublicProfileSettings? currentSettings,
    String? displayName,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final settings = currentSettings ?? await loadSettings();
    final existing = _normalizeSlug(settings.publicSlug);
    if (existing != null && settings.publicProfileEnabled) {
      return existing;
    }

    final suggested =
        existing ?? _suggestSlug(displayName, user.email, user.id);
    try {
      await updateSettings(
        publicProfileEnabled: true,
        publicSlug: suggested,
        publicBio: settings.publicBio,
        publicCity: settings.publicCity,
        rankingOptIn: true,
      );
      return suggested;
    } catch (_) {
      final fallback =
          '$suggested-${user.id.replaceAll('-', '').substring(0, 4)}';
      await updateSettings(
        publicProfileEnabled: true,
        publicSlug: fallback,
        publicBio: settings.publicBio,
        publicCity: settings.publicCity,
        rankingOptIn: true,
      );
      return fallback;
    }
  }

  static String buildInviteUrl(String slug) {
    final cleanSlug = _normalizeSlug(slug) ?? slug.trim();
    return 'https://driver.omnyatech.com.br/?ref=$cleanSlug';
  }

  static String? _normalizeSlug(String? value) {
    final normalized = _normalizeSearchQuery(value ?? '');
    if (normalized.isEmpty) return null;
    return normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
  }

  static String _normalizeSearchQuery(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) return '';
    normalized = normalized.split(RegExp(r'\s+')).first;
    normalized = normalized.replaceFirst(RegExp(r'^https?://[^/]+/?'), '');
    normalized = normalized.replaceFirst(RegExp(r'^(u/|perfil/|@)'), '');
    normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
    return normalized.trim();
  }

  String _suggestSlug(String? displayName, String? email, String userId) {
    final source =
        _normalize(displayName) ??
        _normalize(email?.split('@').first) ??
        'motorista-${userId.replaceAll('-', '').substring(0, 6)}';
    final slug = _normalizeSlug(source);
    return slug == null || slug.isEmpty
        ? 'motorista-${userId.replaceAll('-', '').substring(0, 6)}'
        : slug;
  }

  Future<AppPublicDriverProfile?> loadPublicProfile(String slug) async {
    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('get_public_driver_profile', params: {'p_slug': slug});

    if (response == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(response as Map);
    final records = Map<String, dynamic>.from(
      (data['records'] as Map?) ?? const <String, dynamic>{},
    );

    return AppPublicDriverProfile(
      displayName: data['display_name']?.toString() ?? 'Motorista',
      avatarUrl: data['avatar_url']?.toString(),
      publicSlug: data['public_slug']?.toString() ?? slug,
      publicBio: data['public_bio']?.toString(),
      publicCity: data['public_city']?.toString(),
      level: _toInt(data['level']),
      levelTitle: data['level_title']?.toString() ?? 'Motorista',
      xp: _toInt(data['xp']),
      medalsCount: _toInt(data['medals_count']),
      currentStreakDays: _toInt(data['current_streak_days']),
      bestStreakDays: _toInt(data['best_streak_days']),
      bestFridayDate: _parseDate(records['best_friday']?['date']),
      highestRevenueDayDate: _parseDate(
        records['highest_revenue_day']?['date'],
      ),
      highestProfitPerHourStartedAt: _parseDate(
        records['highest_profit_per_hour']?['started_at'],
      ),
      highestDeliveriesDayDate: _parseDate(
        records['highest_deliveries_day']?['date'],
      ),
      highestDeliveriesCount: _toInt(
        records['highest_deliveries_day']?['deliveries'],
      ),
    );
  }

  Future<List<AppPublicDriverPreview>> listRankingPreview({
    int limit = 20,
  }) async {
    final client = _authService.requireClient();
    final rows = await client
        .schema('driver')
        .rpc('get_public_ranking_preview', params: {'p_limit': limit});

    return (rows as List)
        .map<AppPublicDriverPreview>(
          (item) => AppPublicDriverPreview(
            rankPosition: _toInt((item as Map)['rank_position']),
            publicSlug: item['public_slug']?.toString() ?? '',
            displayName: item['display_name']?.toString() ?? 'Motorista',
            avatarUrl: item['avatar_url']?.toString(),
            publicCity: null,
            level: _toInt(item['level']),
            levelTitle: item['level_title']?.toString() ?? 'Motorista',
            medalsCount: _toInt(item['medals_count']),
            publicScore: _toInt(item['public_score']),
            bestStreakDays: _toInt(item['best_streak_days']),
          ),
        )
        .toList();
  }

  Future<List<AppPublicDriverPreview>> searchDrivers(
    String query, {
    int limit = 20,
  }) async {
    final client = _authService.requireClient();
    final normalizedQuery = _normalizeSearchQuery(query);
    final rows = await client
        .schema('driver')
        .rpc(
          'list_public_driver_profiles',
          params: {
            'p_query': normalizedQuery.isEmpty ? null : normalizedQuery,
            'p_limit': limit,
          },
        );

    return (rows as List)
        .map<AppPublicDriverPreview>(
          (item) => AppPublicDriverPreview(
            publicSlug: (item as Map)['public_slug']?.toString() ?? '',
            displayName: item['display_name']?.toString() ?? 'Motorista',
            avatarUrl: item['avatar_url']?.toString(),
            publicCity: item['public_city']?.toString(),
            level: _toInt(item['level']),
            levelTitle: item['level_title']?.toString() ?? 'Motorista',
            medalsCount: _toInt(item['medals_count']),
            publicScore: _toInt(item['public_score']),
            bestStreakDays: _toInt(item['best_streak_days']),
          ),
        )
        .toList();
  }

  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
