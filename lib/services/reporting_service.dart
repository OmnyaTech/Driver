import '../models/app_operational_report.dart';
import 'dashboard_metrics_service.dart';

class ReportingService {
  ReportingService({DashboardMetricsService? dashboardMetricsService})
    : _dashboardMetricsService =
          dashboardMetricsService ?? DashboardMetricsService();

  final DashboardMetricsService _dashboardMetricsService;

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
    );
  }

  double _toDouble(Object? value) => double.tryParse('$value') ?? 0;
  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
