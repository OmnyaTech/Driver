class AppOperationalReport {
  const AppOperationalReport({
    required this.startAt,
    required this.endAt,
    required this.totalIncome,
    required this.totalOperationalCosts,
    required this.netResult,
    required this.totalJourneys,
    required this.totalDeliveries,
    required this.totalDistanceKm,
    required this.topPlatforms,
    required this.expenseBreakdown,
    this.vehicleComparison = const [],
  });

  final DateTime? startAt;
  final DateTime? endAt;
  final double totalIncome;
  final double totalOperationalCosts;
  final double netResult;
  final int totalJourneys;
  final int totalDeliveries;
  final double totalDistanceKm;
  final List<PlatformPerformance> topPlatforms;
  final List<ExpenseBreakdownItem> expenseBreakdown;
  final List<VehiclePerformance> vehicleComparison;
}

class PlatformPerformance {
  const PlatformPerformance({
    required this.platformName,
    required this.income,
    required this.deliveries,
  });

  final String platformName;
  final double income;
  final int deliveries;
}

class ExpenseBreakdownItem {
  const ExpenseBreakdownItem({required this.label, required this.amount});

  final String label;
  final double amount;
}

class VehiclePerformance {
  const VehiclePerformance({
    required this.vehicleLabel,
    required this.income,
    required this.deliveries,
    required this.journeys,
    required this.distanceKm,
  });

  final String vehicleLabel;
  final double income;
  final int deliveries;
  final int journeys;
  final double distanceKm;
}
