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

    await client.schema('driver').from('platforms').insert({
      'user_id': user.id,
      'name': name.trim(),
      'type': type,
      'average_income': _stringToDouble(averageIncome),
      'average_deliveries': _stringToInt(averageDeliveries),
    });
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
}
