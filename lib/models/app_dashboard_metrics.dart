class AppDashboardMetrics {
  const AppDashboardMetrics({
    required this.totalIncome,
    required this.totalOperationalCosts,
    required this.netResult,
    required this.allocatedToGoals,
    required this.availableBalance,
    required this.totalJourneys,
    required this.openJourneys,
    required this.totalDeliveries,
    required this.totalDistanceKm,
    required this.activeVehicles,
    required this.activePlatforms,
    required this.totalFuelings,
    required this.totalMaintenances,
    required this.totalTripExpenses,
  });

  final double totalIncome;
  final double totalOperationalCosts;
  final double netResult;
  final double allocatedToGoals;
  final double availableBalance;
  final int totalJourneys;
  final int openJourneys;
  final int totalDeliveries;
  final double totalDistanceKm;
  final int activeVehicles;
  final int activePlatforms;
  final int totalFuelings;
  final int totalMaintenances;
  final int totalTripExpenses;

  double get averageIncomePerJourney =>
      totalJourneys == 0 ? 0 : totalIncome / totalJourneys;

  double get averageDeliveriesPerJourney =>
      totalJourneys == 0 ? 0 : totalDeliveries / totalJourneys;

  double get costPerKm =>
      totalDistanceKm <= 0 ? 0 : totalOperationalCosts / totalDistanceKm;

  double get incomePerDelivery =>
      totalDeliveries == 0 ? 0 : totalIncome / totalDeliveries;
}
