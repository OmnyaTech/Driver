import '../models/app_dashboard_metrics.dart';
import 'goal_service.dart';
import 'auth_service.dart';
import 'fueling_service.dart';
import 'journey_service.dart';
import 'maintenance_service.dart';
import 'platform_service.dart';
import 'trip_expense_service.dart';
import 'vehicle_service.dart';

class DashboardMetricsService {
  DashboardMetricsService({
    AuthService? authService,
    JourneyService? journeyService,
    TripExpenseService? tripExpenseService,
    FuelingService? fuelingService,
    MaintenanceService? maintenanceService,
    VehicleService? vehicleService,
    PlatformService? platformService,
    GoalService? goalService,
  }) : _authService = authService ?? const AuthService(),
       _journeyService = journeyService ?? JourneyService(),
       _tripExpenseService = tripExpenseService ?? TripExpenseService(),
       _fuelingService = fuelingService ?? FuelingService(),
       _maintenanceService = maintenanceService ?? MaintenanceService(),
       _vehicleService = vehicleService ?? VehicleService(),
       _platformService = platformService ?? PlatformService(),
       _goalService = goalService ?? GoalService(authService: authService);

  final AuthService _authService;
  final JourneyService _journeyService;
  final TripExpenseService _tripExpenseService;
  final FuelingService _fuelingService;
  final MaintenanceService _maintenanceService;
  final VehicleService _vehicleService;
  final PlatformService _platformService;
  final GoalService _goalService;

  AuthService get authService => _authService;

  Future<AppDashboardMetrics> loadMetrics({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final client = _authService.requireClient();
      final response = await client
          .schema('driver')
          .rpc(
            'get_dashboard_metrics',
            params: {
              'p_start_at': startAt?.toUtc().toIso8601String(),
              'p_end_at': endAt?.toUtc().toIso8601String(),
            },
          )
          .single();

      final goalSummary = await _goalService.loadBalanceSummary();

      return AppDashboardMetrics(
        totalIncome: _toDouble(response['total_income']),
        totalOperationalCosts: _toDouble(response['total_operational_costs']),
        netResult: _toDouble(response['net_result']),
        allocatedToGoals: goalSummary.allocatedToGoals,
        availableBalance: goalSummary.availableBalance,
        totalJourneys: _toInt(response['total_journeys']),
        openJourneys: _toInt(response['open_journeys']),
        totalDeliveries: _toInt(response['total_deliveries']),
        totalDistanceKm: _toDouble(response['total_distance_km']),
        activeVehicles: _toInt(response['active_vehicles']),
        activePlatforms: _toInt(response['active_platforms']),
        totalFuelings: _toInt(response['total_fuelings']),
        totalMaintenances: _toInt(response['total_maintenances']),
        totalTripExpenses: _toInt(response['total_trip_expenses']),
      );
    } catch (_) {
      return _loadMetricsClientSide(startAt: startAt, endAt: endAt);
    }
  }

  Future<AppDashboardMetrics> _loadMetricsClientSide({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final journeys = (await _journeyService.listJourneys())
        .where((item) => _matchesPeriod(item.startedAt, startAt, endAt))
        .toList();
    final expenses = (await _tripExpenseService.listExpenses())
        .where((item) => _matchesPeriod(item.occurredAt, startAt, endAt))
        .toList();
    final fuelings = (await _fuelingService.listFuelings())
        .where((item) => _matchesPeriod(item.fueledAt, startAt, endAt))
        .toList();
    final maintenances = (await _maintenanceService.listMaintenances())
        .where((item) => _matchesPeriod(item.maintenanceDate, startAt, endAt))
        .toList();
    final vehicles = await _vehicleService.listVehicles();
    final platforms = await _platformService.listPlatforms();

    final totalIncome = journeys.fold<double>(
      0,
      (sum, item) => sum + item.totalIncome,
    );
    final totalTripExpensesAmount = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalFuelingsCost = fuelings.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalMaintenancesCost = maintenances.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalOperationalCosts =
        totalTripExpensesAmount + totalFuelingsCost + totalMaintenancesCost;
    final totalDeliveries = journeys.fold<int>(
      0,
      (sum, item) => sum + item.totalDeliveries,
    );
    final totalDistanceKm = journeys.fold<double>(
      0,
      (sum, item) => sum + (item.distanceKm ?? 0),
    );

    return AppDashboardMetrics(
      totalIncome: totalIncome,
      totalOperationalCosts: totalOperationalCosts,
      netResult: totalIncome - totalOperationalCosts,
      allocatedToGoals: 0,
      availableBalance: totalIncome - totalOperationalCosts,
      totalJourneys: journeys.length,
      openJourneys: journeys.where((item) => !item.isFinished).length,
      totalDeliveries: totalDeliveries,
      totalDistanceKm: totalDistanceKm,
      activeVehicles: vehicles.where((item) => item.active).length,
      activePlatforms: platforms.where((item) => item.active).length,
      totalFuelings: fuelings.length,
      totalMaintenances: maintenances.length,
      totalTripExpenses: expenses.length,
    );
  }

  bool _matchesPeriod(DateTime value, DateTime? startAt, DateTime? endAt) {
    final utc = value.toUtc();
    if (startAt != null && utc.isBefore(startAt.toUtc())) return false;
    if (endAt != null && utc.isAfter(endAt.toUtc())) return false;
    return true;
  }

  double _toDouble(Object? value) => double.tryParse('$value') ?? 0;
  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
}
