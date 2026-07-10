import '../models/app_fueling.dart';
import 'auth_service.dart';

class FuelingService {
  FuelingService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppFueling>> listFuelings() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('fuelings')
        .select()
        .eq('user_id', user.id)
        .order('fueled_at', ascending: false);

    final vehicleRows = await client
        .schema('driver')
        .from('vehicles')
        .select('id, brand, model')
        .eq('user_id', user.id);

    final vehicleLabels = {
      for (final row in vehicleRows)
        row['id'].toString(): '${row['brand']} ${row['model']}',
    };

    return rows.map<AppFueling>((row) {
      final vehicleId = row['vehicle_id'].toString();
      return AppFueling(
        id: row['id'].toString(),
        fueledAt: DateTime.parse(row['fueled_at'].toString()),
        vehicleId: vehicleId,
        vehicleLabel: vehicleLabels[vehicleId],
        journeyId: row['journey_id']?.toString(),
        stationName: row['station_name'] as String?,
        fuelType: row['fuel_type'] as String?,
        odometer: _nullableDouble(row['odometer']),
        liters: _toDouble(row['liters']),
        pricePerLiter: _toDouble(row['price_per_liter']),
        totalAmount: _toDouble(row['total_amount']),
      );
    }).toList();
  }

  Future<void> createFueling({
    required String vehicleId,
    required DateTime fueledAt,
    required String liters,
    required String pricePerLiter,
    required String totalAmount,
    String? odometer,
    String? journeyId,
    String? stationName,
    String? fuelType,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client.schema('driver').from('fuelings').insert({
      'user_id': user.id,
      'vehicle_id': vehicleId,
      'journey_id': _normalizeString(journeyId),
      'fueled_at': fueledAt.toUtc().toIso8601String(),
      'odometer': _stringToDouble(odometer),
      'station_name': _normalizeString(stationName),
      'fuel_type': _normalizeString(fuelType),
      'liters': _stringToDouble(liters),
      'price_per_liter': _stringToDouble(pricePerLiter),
      'total_amount': _stringToDouble(totalAmount),
    });
  }

  Future<void> updateFueling({
    required String id,
    required String vehicleId,
    required DateTime fueledAt,
    required String liters,
    required String pricePerLiter,
    required String totalAmount,
    String? odometer,
    String? journeyId,
    String? stationName,
    String? fuelType,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('fuelings')
        .update({
          'vehicle_id': vehicleId,
          'journey_id': _normalizeString(journeyId),
          'fueled_at': fueledAt.toUtc().toIso8601String(),
          'odometer': _stringToDouble(odometer),
          'station_name': _normalizeString(stationName),
          'fuel_type': _normalizeString(fuelType),
          'liters': _stringToDouble(liters),
          'price_per_liter': _stringToDouble(pricePerLiter),
          'total_amount': _stringToDouble(totalAmount),
        })
        .eq('id', id);
  }

  Future<void> deleteFueling(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('fuelings').delete().eq('id', id);
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  double _toDouble(Object? value) => double.tryParse(value.toString()) ?? 0;
  double? _nullableDouble(Object? value) =>
      value == null ? null : double.tryParse(value.toString());

  double? _stringToDouble(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
