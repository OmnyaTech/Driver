import '../models/app_maintenance.dart';
import 'auth_service.dart';

class MaintenanceService {
  MaintenanceService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppMaintenance>> listMaintenances() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('maintenances')
        .select()
        .eq('user_id', user.id)
        .order('maintenance_date', ascending: false);

    final vehicleRows = await client
        .schema('driver')
        .from('vehicles')
        .select('id, brand, model')
        .eq('user_id', user.id);
    final vehicleLabels = {
      for (final row in vehicleRows)
        row['id'].toString(): '${row['brand']} ${row['model']}',
    };

    final maintenanceIds = rows.map((row) => row['id'].toString()).toList();
    final itemsByMaintenance = <String, List<AppMaintenanceItem>>{};

    if (maintenanceIds.isNotEmpty) {
      final itemRows = await client
          .schema('driver')
          .from('maintenance_items')
          .select()
          .filter(
            'maintenance_id',
            'in',
            '(${maintenanceIds.map((id) => '"$id"').join(',')})',
          );

      for (final row in itemRows) {
        final maintenanceId = row['maintenance_id'].toString();
        itemsByMaintenance.putIfAbsent(maintenanceId, () => []);
        itemsByMaintenance[maintenanceId]!.add(
          AppMaintenanceItem(
            description: row['description'].toString(),
            amount: _toDouble(row['amount']),
          ),
        );
      }
    }

    return rows.map<AppMaintenance>((row) {
      final id = row['id'].toString();
      final vehicleId = row['vehicle_id'].toString();
      return AppMaintenance(
        id: id,
        maintenanceDate: DateTime.parse('${row['maintenance_date']}T00:00:00'),
        vehicleId: vehicleId,
        vehicleLabel: vehicleLabels[vehicleId],
        workshop: row['workshop'] as String?,
        reason: row['reason'] as String?,
        description: row['description'] as String?,
        totalAmount: _toDouble(row['total_amount']),
        items: itemsByMaintenance[id] ?? const [],
      );
    }).toList();
  }

  Future<void> createMaintenance({
    required String vehicleId,
    required DateTime maintenanceDate,
    required String totalAmount,
    String? workshop,
    String? reason,
    String? description,
    required List<MaintenanceItemDraft> items,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final inserted = await client
        .schema('driver')
        .from('maintenances')
        .insert({
          'user_id': user.id,
          'vehicle_id': vehicleId,
          'maintenance_date': maintenanceDate
              .toIso8601String()
              .split('T')
              .first,
          'workshop': _normalizeString(workshop),
          'reason': _normalizeString(reason),
          'description': _normalizeString(description),
          'total_amount': _stringToDouble(totalAmount) ?? 0,
        })
        .select('id')
        .single();

    final maintenanceId = inserted['id'].toString();
    final rows = items
        .where((item) => item.description.trim().isNotEmpty)
        .map(
          (item) => {
            'maintenance_id': maintenanceId,
            'description': item.description.trim(),
            'amount': _stringToDouble(item.amount) ?? 0,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await client.schema('driver').from('maintenance_items').insert(rows);
    }
  }

  Future<void> updateMaintenance({
    required String id,
    required String vehicleId,
    required DateTime maintenanceDate,
    required String totalAmount,
    String? workshop,
    String? reason,
    String? description,
    required List<MaintenanceItemDraft> items,
  }) async {
    final client = _authService.requireClient();

    await client
        .schema('driver')
        .from('maintenances')
        .update({
          'vehicle_id': vehicleId,
          'maintenance_date': maintenanceDate.toIso8601String().split('T').first,
          'workshop': _normalizeString(workshop),
          'reason': _normalizeString(reason),
          'description': _normalizeString(description),
          'total_amount': _stringToDouble(totalAmount) ?? 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);

    await client
        .schema('driver')
        .from('maintenance_items')
        .delete()
        .eq('maintenance_id', id);

    final rows = items
        .where((item) => item.description.trim().isNotEmpty)
        .map(
          (item) => {
            'maintenance_id': id,
            'description': item.description.trim(),
            'amount': _stringToDouble(item.amount) ?? 0,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await client.schema('driver').from('maintenance_items').insert(rows);
    }
  }

  Future<void> deleteMaintenance(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('maintenances').delete().eq('id', id);
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  double _toDouble(Object? value) => double.tryParse(value.toString()) ?? 0;

  double? _stringToDouble(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}

class MaintenanceItemDraft {
  const MaintenanceItemDraft({required this.description, required this.amount});

  final String description;
  final String amount;
}
