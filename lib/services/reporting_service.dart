import '../models/app_operational_report.dart';
import 'dashboard_metrics_service.dart';
import 'journey_service.dart';

class ReportingService {
  ReportingService({
    DashboardMetricsService? dashboardMetricsService,
    JourneyService? journeyService,
  }) : _dashboardMetricsService =
           dashboardMetricsService ?? DashboardMetricsService(),
       _journeyService = journeyService ?? JourneyService();

  final DashboardMetricsService _dashboardMetricsService;
  final JourneyService _journeyService;

  Future<AppOperationalReport> loadOperationalReport({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final client = _dashboardMetricsService.authService.requireClient();

    final response = await client
        .schema('driver')
        .rpc(
          'get_operational_report',
          params: {
            'p_start_at': startAt?.toUtc().toIso8601String(),
            'p_end_at': endAt?.toUtc().toIso8601String(),
          },
        );

    final data = Map<String, dynamic>.from(response as Map);
    final topPlatformsRaw = (data['top_platforms'] as List? ?? const [])
        .cast<dynamic>();
    final expenseBreakdownRaw = (data['expense_breakdown'] as List? ?? const [])
        .cast<dynamic>();
    final vehicleComparison = await _loadVehicleComparison(
      startAt: startAt,
      endAt: endAt,
    );

    return AppOperationalReport(
      startAt: _parseDate(data['start_at']),
      endAt: _parseDate(data['end_at']),
      totalIncome: _toDouble(data['total_income']),
      totalOperationalCosts: _toDouble(data['total_operational_costs']),
      netResult: _toDouble(data['net_result']),
      totalJourneys: _toInt(data['total_journeys']),
      totalDeliveries: _toInt(data['total_deliveries']),
      totalDistanceKm: _toDouble(data['total_distance_km']),
      topPlatforms: topPlatformsRaw
          .map(
            (item) => PlatformPerformance(
              platformName:
                  (item as Map)['platform_name']?.toString() ?? 'Plataforma',
              income: _toDouble(item['income']),
              deliveries: _toInt(item['deliveries']),
            ),
          )
          .toList(),
      expenseBreakdown: expenseBreakdownRaw
          .map(
            (item) => ExpenseBreakdownItem(
              label: (item as Map)['label']?.toString() ?? 'Outro',
              amount: _toDouble(item['amount']),
            ),
          )
          .toList(),
      vehicleComparison: vehicleComparison,
    );
  }

  Future<List<VehiclePerformance>> _loadVehicleComparison({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final journeys = await _journeyService.listJourneys();
    final buckets = <String, _VehicleBucket>{};

    for (final journey in journeys) {
      final startedAt = journey.startedAt.toLocal();
      if (startAt != null && startedAt.isBefore(startAt.toLocal())) continue;
      if (endAt != null &&
          startedAt.isAfter(endAt.toLocal().add(const Duration(days: 1)))) {
        continue;
      }

      final label = journey.vehicleLabel?.trim().isNotEmpty == true
          ? journey.vehicleLabel!.trim()
          : 'Veiculo nao informado';
      final current = buckets[label] ?? const _VehicleBucket();
      buckets[label] = current.add(
        income: journey.totalIncome,
        deliveries: journey.totalDeliveries,
        distanceKm: journey.distanceKm ?? 0,
      );
    }

    final result =
        buckets.entries
            .map(
              (entry) => VehiclePerformance(
                vehicleLabel: entry.key,
                income: entry.value.income,
                deliveries: entry.value.deliveries,
                journeys: entry.value.journeys,
                distanceKm: entry.value.distanceKm,
              ),
            )
            .toList()
          ..sort((a, b) => b.income.compareTo(a.income));
    return result;
  }

  double _toDouble(Object? value) => double.tryParse('$value') ?? 0;
  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

class _VehicleBucket {
  const _VehicleBucket({
    this.income = 0,
    this.deliveries = 0,
    this.journeys = 0,
    this.distanceKm = 0,
  });

  final double income;
  final int deliveries;
  final int journeys;
  final double distanceKm;

  _VehicleBucket add({
    required double income,
    required int deliveries,
    required double distanceKm,
  }) {
    return _VehicleBucket(
      income: this.income + income,
      deliveries: this.deliveries + deliveries,
      journeys: journeys + 1,
      distanceKm: this.distanceKm + distanceKm,
    );
  }
}
