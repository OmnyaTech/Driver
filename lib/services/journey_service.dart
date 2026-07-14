import '../models/app_journey.dart';
import 'auth_service.dart';

class JourneyService {
  JourneyService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppJourney>> listJourneys() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final journeys = await client
        .schema('driver')
        .from('journeys')
        .select()
        .eq('user_id', user.id)
        .order('started_at', ascending: false);

    final vehicleRows = await client
        .schema('driver')
        .from('vehicles')
        .select('id, brand, model')
        .eq('user_id', user.id);

    final vehicleLabels = {
      for (final row in vehicleRows)
        row['id'].toString(): '${row['brand']} ${row['model']}',
    };

    final platformRows = await client
        .schema('driver')
        .from('platforms')
        .select('id, name')
        .eq('user_id', user.id);
    final platformLabels = {
      for (final row in platformRows)
        row['id'].toString(): row['name'].toString(),
    };

    final journeyIds = journeys.map((row) => row['id'].toString()).toList();
    final totals = <String, ({double income, int deliveries})>{};
    final breakdown = <String, List<JourneyPlatformSummary>>{};

    if (journeyIds.isNotEmpty) {
      final platformRows = await client
          .schema('driver')
          .from('journey_platforms')
          .select('journey_id, platform_id, deliveries, income')
          .filter(
            'journey_id',
            'in',
            '(${journeyIds.map((id) => '"$id"').join(',')})',
          );

      for (final row in platformRows) {
        final journeyId = row['journey_id'].toString();
        final current = totals[journeyId] ?? (income: 0.0, deliveries: 0);
        totals[journeyId] = (
          income: current.income + _toDouble(row['income']),
          deliveries: current.deliveries + _toInt(row['deliveries']),
        );
        breakdown.putIfAbsent(journeyId, () => []);
        final platformId = row['platform_id']?.toString();
        breakdown[journeyId]!.add(
          JourneyPlatformSummary(
            platformId: platformId,
            platformName: platformId == null
                ? 'Plataforma'
                : (platformLabels[platformId] ?? 'Plataforma'),
            income: _toDouble(row['income']),
            deliveries: _toInt(row['deliveries']),
          ),
        );
      }
    }

    return journeys.map<AppJourney>((row) {
      final id = row['id'].toString();
      final totalsForJourney = totals[id] ?? (income: 0.0, deliveries: 0);
      final vehicleId = row['vehicle_id']?.toString();

      return AppJourney(
        id: id,
        mode: row['mode'].toString(),
        startedAt: DateTime.parse(row['started_at'].toString()),
        endedAt: row['ended_at'] == null
            ? null
            : DateTime.tryParse(row['ended_at'].toString()),
        odometerStart: _nullableDouble(row['odometer_start']),
        odometerEnd: _nullableDouble(row['odometer_end']),
        notes: row['notes'] as String?,
        vehicleId: vehicleId,
        vehicleLabel: vehicleId == null ? null : vehicleLabels[vehicleId],
        totalIncome: totalsForJourney.income,
        totalDeliveries: totalsForJourney.deliveries,
        platformBreakdown: breakdown[id] ?? const [],
      );
    }).toList();
  }

  Future<String> createJourney({
    required String mode,
    required DateTime startedAt,
    DateTime? endedAt,
    String? vehicleId,
    String? odometerStart,
    String? odometerEnd,
    String? notes,
    required List<JourneyPlatformDraft> platforms,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final inserted = await client
        .schema('driver')
        .from('journeys')
        .insert({
          'user_id': user.id,
          'vehicle_id': _normalizeString(vehicleId),
          'mode': mode,
          'started_at': startedAt.toUtc().toIso8601String(),
          'ended_at': endedAt?.toUtc().toIso8601String(),
          'odometer_start': _stringToDouble(odometerStart),
          'odometer_end': _stringToDouble(odometerEnd),
          'notes': _normalizeString(notes),
        })
        .select('id')
        .single();

    final journeyId = inserted['id'].toString();
    final rows = platforms
        .where((item) => item.platformId.isNotEmpty)
        .map(
          (item) => {
            'journey_id': journeyId,
            'platform_id': item.platformId,
            'deliveries': _stringToInt(item.deliveries) ?? 0,
            'income': _stringToDouble(item.income) ?? 0,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await client.schema('driver').from('journey_platforms').insert(rows);
    }

    return journeyId;
  }

  Future<void> updateJourney({
    required String id,
    required String mode,
    required DateTime startedAt,
    DateTime? endedAt,
    String? vehicleId,
    String? odometerStart,
    String? odometerEnd,
    String? notes,
    required List<JourneyPlatformDraft> platforms,
  }) async {
    final client = _authService.requireClient();

    await client
        .schema('driver')
        .from('journeys')
        .update({
          'vehicle_id': _normalizeString(vehicleId),
          'mode': mode,
          'started_at': startedAt.toUtc().toIso8601String(),
          'ended_at': endedAt?.toUtc().toIso8601String(),
          'odometer_start': _stringToDouble(odometerStart),
          'odometer_end': _stringToDouble(odometerEnd),
          'notes': _normalizeString(notes),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);

    await client
        .schema('driver')
        .from('journey_platforms')
        .delete()
        .eq('journey_id', id);

    final rows = platforms
        .where((item) => item.platformId.isNotEmpty)
        .map(
          (item) => {
            'journey_id': id,
            'platform_id': item.platformId,
            'deliveries': _stringToInt(item.deliveries) ?? 0,
            'income': _stringToDouble(item.income) ?? 0,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await client.schema('driver').from('journey_platforms').insert(rows);
    }
  }

  Future<void> deleteJourney(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('journeys').delete().eq('id', id);
  }

  Future<List<JourneyOption>> listJourneyOptions() async {
    final journeys = await listJourneys();
    return journeys
        .map(
          (journey) => JourneyOption(
            id: journey.id,
            label:
                '${_formatDate(journey.startedAt)}${journey.vehicleLabel == null ? '' : ' - ${journey.vehicleLabel}'}',
          ),
        )
        .toList();
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  double _toDouble(Object? value) => double.tryParse(value.toString()) ?? 0;
  int _toInt(Object? value) => int.tryParse(value.toString()) ?? 0;
  double? _nullableDouble(Object? value) =>
      value == null ? null : double.tryParse(value.toString());

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

class JourneyPlatformDraft {
  const JourneyPlatformDraft({
    required this.platformId,
    required this.income,
    required this.deliveries,
  });

  final String platformId;
  final String income;
  final String deliveries;
}

class JourneyOption {
  const JourneyOption({required this.id, required this.label});

  final String id;
  final String label;
}
