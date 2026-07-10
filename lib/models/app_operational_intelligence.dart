import 'app_dashboard_metrics.dart';

class AppOperationalIntelligence {
  const AppOperationalIntelligence({
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.currentMetrics,
    required this.previousMetrics,
    required this.trend,
    required this.insights,
    required this.suggestedReserve,
    required this.suggestedReserveLabel,
  });

  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final AppDashboardMetrics currentMetrics;
  final AppDashboardMetrics previousMetrics;
  final List<OperationalTrendPoint> trend;
  final List<OperationalInsight> insights;
  final double suggestedReserve;
  final String suggestedReserveLabel;

  double incomeDeltaPct() =>
      _pct(currentMetrics.totalIncome, previousMetrics.totalIncome);

  double netDeltaPct() =>
      _pct(currentMetrics.netResult, previousMetrics.netResult);

  double deliveryDeltaPct() => _pct(
    currentMetrics.totalDeliveries.toDouble(),
    previousMetrics.totalDeliveries.toDouble(),
  );

  double _pct(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return 0;
      return 100;
    }
    return ((current - previous) / previous) * 100;
  }
}

class OperationalTrendPoint {
  const OperationalTrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class OperationalInsight {
  const OperationalInsight({
    required this.title,
    required this.value,
    required this.description,
  });

  final String title;
  final String value;
  final String description;
}
