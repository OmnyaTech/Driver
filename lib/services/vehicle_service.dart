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
            modelYear: row['model_year'] as int?,
            plate: row['plate'] as String?,
            fuelType: row['fuel_type'] as String?,
            averageConsumption: _parseDouble(row['average_consumption']),
          ),
        )
        .toList();
  }

  Future<void> createVehicle({
    required String brand,
    required String model,
    String? year,
    String? plate,
    String? fuelType,
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
      'model_year': _stringToInt(year),
      'plate': _normalizeString(plate),
      'fuel_type': _normalizeString(fuelType),
      'average_consumption': _stringToDouble(averageConsumption),
    });
  }

  Future<void> updateVehicle({
    required String id,
    required String brand,
    required String model,
    String? year,
    String? plate,
    String? fuelType,
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
          'model_year': _stringToInt(year),
          'plate': _normalizeString(plate),
          'fuel_type': _normalizeString(fuelType),
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
