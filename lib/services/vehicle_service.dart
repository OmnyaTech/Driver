import '../models/app_vehicle.dart';
import 'auth_service.dart';

class VehicleService {
  VehicleService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppVehicle>> listVehicles() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return rows
        .map<AppVehicle>(
          (row) => AppVehicle(
            id: row['id'].toString(),
            brand: row['brand'].toString(),
            model: row['model'].toString(),
            active: row['active'] as bool? ?? true,
            type: row['vehicle_type'] as String?,
            modelYear: row['model_year'] as int?,
            plate: row['plate'] as String?,
            fuelType: row['fuel_type'] as String?,
            fuelTypes: _parseStringList(row['fuel_types']),
            averageConsumption: _parseDouble(row['average_consumption']),
          ),
        )
        .toList();
  }

  Future<void> createVehicle({
    required String brand,
    required String model,
    String? type,
    String? year,
    String? plate,
    String? fuelType,
    List<String> fuelTypes = const [],
    String? averageConsumption,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client.schema('driver').from('vehicles').insert({
      'user_id': user.id,
      'brand': brand.trim(),
      'model': model.trim(),
      'vehicle_type': _normalizeString(type),
      'model_year': _stringToInt(year),
      'plate': _normalizeString(plate),
      'fuel_type': _normalizeString(
        fuelTypes.isNotEmpty ? fuelTypes.join(', ') : fuelType,
      ),
      'fuel_types': _normalizeFuelTypes(fuelTypes, fallback: fuelType),
      'average_consumption': _stringToDouble(averageConsumption),
    });
  }

  Future<void> updateVehicle({
    required String id,
    required String brand,
    required String model,
    String? type,
    String? year,
    String? plate,
    String? fuelType,
    List<String> fuelTypes = const [],
    String? averageConsumption,
    required bool active,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('vehicles')
        .update({
          'brand': brand.trim(),
          'model': model.trim(),
          'vehicle_type': _normalizeString(type),
          'model_year': _stringToInt(year),
          'plate': _normalizeString(plate),
          'fuel_type': _normalizeString(
            fuelTypes.isNotEmpty ? fuelTypes.join(', ') : fuelType,
          ),
          'fuel_types': _normalizeFuelTypes(fuelTypes, fallback: fuelType),
          'average_consumption': _stringToDouble(averageConsumption),
          'active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> archiveVehicle(String id) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('vehicles')
        .update({
          'active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteVehicle(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('vehicles').delete().eq('id', id);
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  double? _parseDouble(Object? value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  List<String> _parseStringList(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == '{}') return const [];
    return raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(',')
        .map((item) => item.trim().replaceAll('"', ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _normalizeFuelTypes(List<String> values, {String? fallback}) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isNotEmpty) return normalized;
    final legacy = _normalizeString(fallback);
    return legacy == null ? const [] : [legacy];
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
