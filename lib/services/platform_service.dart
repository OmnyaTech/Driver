import '../models/app_platform.dart';
import 'auth_service.dart';

class PlatformService {
  PlatformService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppPlatform>> listPlatforms() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('platforms')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return rows
        .map<AppPlatform>(
          (row) => AppPlatform(
            id: row['id'].toString(),
            name: row['name'].toString(),
            type: row['type'].toString(),
            active: row['active'] as bool? ?? true,
            logoUrl: row['logo_url'] as String?,
            averageIncome: _parseDouble(row['average_income']),
            averageDeliveries: row['average_deliveries'] as int?,
          ),
        )
        .toList();
  }

  Future<void> createPlatform({
    required String name,
    required String type,
    String? averageIncome,
    String? averageDeliveries,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final location = await _loadProfileLocation(user.id);
    final logoUrl = await _findCatalogLogo(
      name: name,
      type: type,
      city: location.city,
      state: location.state,
      country: location.country,
    );

    await client.schema('driver').from('platforms').insert({
      'user_id': user.id,
      'name': name.trim(),
      'type': type,
      'logo_url': logoUrl,
      'average_income': _stringToDouble(averageIncome),
      'average_deliveries': _stringToInt(averageDeliveries),
    });

    await _upsertCatalogEntry(
      name: name,
      type: type,
      city: location.city,
      state: location.state,
      country: location.country,
      logoUrl: logoUrl,
    );
  }

  Future<List<PlatformCatalogSuggestion>> findCatalogSuggestions({
    required String name,
    required String type,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null || name.trim().length < 2) return const [];

    final location = await _loadProfileLocation(user.id);
    try {
      dynamic query = client
          .schema('driver')
          .from('platform_catalog')
          .select('id, name, type, city, state, country, logo_url')
          .ilike('name', '%${name.trim()}%')
          .ilike('type', type.trim())
          .eq('country', location.country);

      if ((location.state ?? '').trim().isNotEmpty) {
        query = query.ilike('state', location.state!.trim());
      }
      if ((location.city ?? '').trim().isNotEmpty) {
        query = query.ilike('city', location.city!.trim());
      }

      final rows = await query.limit(5);
      if (rows is! List) return const [];
      return rows
          .map(
            (row) => PlatformCatalogSuggestion(
              id: (row as Map)['id']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              type: row['type']?.toString() ?? '',
              city: row['city']?.toString(),
              state: row['state']?.toString(),
              country: row['country']?.toString() ?? location.country,
              logoUrl: row['logo_url']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> updatePlatform({
    required String id,
    required String name,
    required String type,
    String? averageIncome,
    String? averageDeliveries,
    required bool active,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('platforms')
        .update({
          'name': name.trim(),
          'type': type,
          'average_income': _stringToDouble(averageIncome),
          'average_deliveries': _stringToInt(averageDeliveries),
          'active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> updatePlatformLogo({
    required String id,
    required String? logoUrl,
  }) async {
    final client = _authService.requireClient();
    final current = await client
        .schema('driver')
        .from('platforms')
        .select('name, type, user_id')
        .eq('id', id)
        .limit(1);
    final row = current.isNotEmpty
        ? Map<String, dynamic>.from(current.first as Map)
        : null;

    await client
        .schema('driver')
        .from('platforms')
        .update({
          'logo_url': logoUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);

    if (row != null && logoUrl != null && logoUrl.trim().isNotEmpty) {
      final location = await _loadProfileLocation(row['user_id'].toString());
      await _upsertCatalogEntry(
        name: row['name'].toString(),
        type: row['type'].toString(),
        city: location.city,
        state: location.state,
        country: location.country,
        logoUrl: logoUrl,
      );
    }
  }

  Future<void> archivePlatform(String id) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('platforms')
        .update({
          'active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deletePlatform(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('platforms').delete().eq('id', id);
  }

  double? _parseDouble(Object? value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  double? _stringToDouble(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _stringToInt(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  Future<_PlatformLocation> _loadProfileLocation(String userId) async {
    try {
      final rows = await _authService
          .requireClient()
          .schema('driver')
          .from('profiles')
          .select('city, state, country')
          .eq('id', userId)
          .limit(1);
      final row = rows.isNotEmpty
          ? Map<String, dynamic>.from(rows.first as Map)
          : const <String, dynamic>{};
      return _PlatformLocation(
        city: row['city'] as String?,
        state: row['state'] as String?,
        country: (row['country'] ?? 'Brasil').toString(),
      );
    } catch (_) {
      return const _PlatformLocation(
        city: null,
        state: null,
        country: 'Brasil',
      );
    }
  }

  Future<String?> _findCatalogLogo({
    required String name,
    required String type,
    required String? city,
    required String? state,
    required String country,
  }) async {
    try {
      dynamic query = _authService
          .requireClient()
          .schema('driver')
          .from('platform_catalog')
          .select('logo_url')
          .ilike('name', name.trim())
          .ilike('type', type.trim())
          .eq('country', country);

      query = city == null || city.trim().isEmpty
          ? query.isFilter('city', null)
          : query.ilike('city', city.trim());
      query = state == null || state.trim().isEmpty
          ? query.isFilter('state', null)
          : query.ilike('state', state.trim());

      final rows = await query.not('logo_url', 'is', null).limit(1);

      if (rows is List && rows.isNotEmpty) {
        final logo = (rows.first as Map)['logo_url']?.toString();
        return logo?.trim().isEmpty == true ? null : logo;
      }
    } catch (_) {
      // Catalog is an enhancement; platform creation should never depend on it.
    }
    return null;
  }

  Future<void> _upsertCatalogEntry({
    required String name,
    required String type,
    required String? city,
    required String? state,
    required String country,
    required String? logoUrl,
  }) async {
    try {
      await _authService
          .requireClient()
          .schema('driver')
          .rpc(
            'upsert_platform_catalog_entry',
            params: {
              'p_name': name,
              'p_type': type,
              'p_city': city,
              'p_state': state,
              'p_country': country,
              'p_logo_url': logoUrl,
            },
          );
    } catch (_) {
      // Safe fallback for environments where sql/manual/023 is not applied yet.
    }
  }
}

class PlatformCatalogSuggestion {
  const PlatformCatalogSuggestion({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.state,
    required this.country,
    required this.logoUrl,
  });

  final String id;
  final String name;
  final String type;
  final String? city;
  final String? state;
  final String country;
  final String? logoUrl;

  String get locationLabel => [
    city,
    state,
    country,
  ].where((item) => item != null && item.trim().isNotEmpty).join(' - ');
}

class _PlatformLocation {
  const _PlatformLocation({
    required this.city,
    required this.state,
    required this.country,
  });

  final String? city;
  final String? state;
  final String country;
}
