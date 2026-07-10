import '../models/app_dashboard_metrics.dart';
import '../models/app_goal.dart';
import 'auth_service.dart';
import 'fueling_service.dart';
import 'journey_service.dart';
import 'maintenance_service.dart';
import 'trip_expense_service.dart';

class GoalService {
  GoalService({
    AuthService? authService,
    JourneyService? journeyService,
    TripExpenseService? tripExpenseService,
    FuelingService? fuelingService,
    MaintenanceService? maintenanceService,
  }) : _authService = authService ?? const AuthService(),
       _journeyService = journeyService ?? JourneyService(authService: authService),
       _tripExpenseService =
           tripExpenseService ?? TripExpenseService(authService: authService),
       _fuelingService = fuelingService ?? FuelingService(authService: authService),
       _maintenanceService =
           maintenanceService ?? MaintenanceService(authService: authService);

  final AuthService _authService;
  final JourneyService _journeyService;
  final TripExpenseService _tripExpenseService;
  final FuelingService _fuelingService;
  final MaintenanceService _maintenanceService;

  Future<List<AppGoal>> listGoals() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map<AppGoal>(
          (row) => AppGoal(
            id: row['id'].toString(),
            title: row['title'].toString(),
            targetAmount: _toDouble(row['target_amount']),
            currentAmount: _toDouble(row['current_amount']),
            icon: row['icon']?.toString(),
            deadline: _tryParseDate(row['deadline']),
            createdAt: DateTime.parse(row['created_at'].toString()),
            updatedAt: DateTime.parse(row['updated_at'].toString()),
          ),
        )
        .toList();
  }

  Future<List<AppGoalTransaction>> listTransactions() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final goals = await listGoals();
    if (goals.isEmpty) return const [];

    final goalTitles = {for (final goal in goals) goal.id: goal.title};
    final goalIds = goals.map((item) => item.id).toList();
    final rows = await client
        .schema('driver')
        .from('goal_transactions')
        .select('id, goal_id, journey_id, amount, created_at')
        .filter(
          'goal_id',
          'in',
          '(${goalIds.map((id) => '"$id"').join(',')})',
        )
        .order('created_at', ascending: false);

    final journeyLabels = await _loadJourneyLabels();

    return rows
        .map<AppGoalTransaction>(
          (row) => AppGoalTransaction(
            id: row['id'].toString(),
            goalId: row['goal_id'].toString(),
            goalTitle: goalTitles[row['goal_id'].toString()] ?? 'Objetivo',
            amount: _toDouble(row['amount']),
            createdAt: DateTime.parse(row['created_at'].toString()),
            journeyId: row['journey_id']?.toString(),
            journeyLabel: row['journey_id'] == null
                ? null
                : journeyLabels[row['journey_id'].toString()],
          ),
        )
        .toList();
  }

  Future<void> createGoal({
    required String title,
    required String targetAmount,
    String? icon,
    DateTime? deadline,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client.schema('driver').from('goals').insert({
      'user_id': user.id,
      'title': title.trim(),
      'target_amount': _stringToDouble(targetAmount),
      'icon': _normalizeString(icon),
      'deadline': deadline == null ? null : _formatDate(deadline),
    });
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String targetAmount,
    String? icon,
    DateTime? deadline,
  }) async {
    final client = _authService.requireClient();
    await client
        .schema('driver')
        .from('goals')
        .update({
          'title': title.trim(),
          'target_amount': _stringToDouble(targetAmount),
          'icon': _normalizeString(icon),
          'deadline': deadline == null ? null : _formatDate(deadline),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteGoal(String id) async {
    final client = _authService.requireClient();
    await client.schema('driver').from('goals').delete().eq('id', id);
  }

  Future<void> applyTransaction({
    required String goalId,
    required String amount,
    String? journeyId,
  }) async {
    final value = _stringToDouble(amount);
    if (value == null || value == 0) {
      throw StateError('Informe um valor valido para movimentacao.');
    }

    final normalizedJourneyId = _normalizeString(journeyId);
    final client = _authService.requireClient();

    try {
      await client.schema('driver').rpc(
        'apply_goal_transaction',
        params: {
          'p_goal_id': goalId,
          'p_amount': value,
          'p_journey_id': normalizedJourneyId,
        },
      );
      return;
    } catch (_) {
      await _applyTransactionClientSide(
        goalId: goalId,
        amount: value,
        journeyId: normalizedJourneyId,
      );
    }
  }

  Future<GoalBalanceSummary> loadBalanceSummary() async {
    final AppDashboardMetrics metrics = await _loadNetMetrics();
    final goals = await listGoals();
    final allocatedToGoals = goals.fold<double>(
      0,
      (sum, item) => sum + item.currentAmount,
    );

    return GoalBalanceSummary(
      netOperationalResult: metrics.netResult,
      allocatedToGoals: allocatedToGoals,
      availableBalance: metrics.netResult - allocatedToGoals,
    );
  }

  Future<AppDashboardMetrics> _loadNetMetrics() async {
    final client = _authService.requireClient();

    try {
      final response = await client
          .schema('driver')
          .rpc('get_dashboard_metrics', params: {
            'p_start_at': null,
            'p_end_at': null,
          })
          .single();

      return AppDashboardMetrics(
        totalIncome: _toDouble(response['total_income']),
        totalOperationalCosts: _toDouble(response['total_operational_costs']),
        netResult: _toDouble(response['net_result']),
        allocatedToGoals: 0,
        availableBalance: 0,
        totalJourneys: int.tryParse('${response['total_journeys']}') ?? 0,
        openJourneys: int.tryParse('${response['open_journeys']}') ?? 0,
        totalDeliveries: int.tryParse('${response['total_deliveries']}') ?? 0,
        totalDistanceKm: _toDouble(response['total_distance_km']),
        activeVehicles: int.tryParse('${response['active_vehicles']}') ?? 0,
        activePlatforms: int.tryParse('${response['active_platforms']}') ?? 0,
        totalFuelings: int.tryParse('${response['total_fuelings']}') ?? 0,
        totalMaintenances:
            int.tryParse('${response['total_maintenances']}') ?? 0,
        totalTripExpenses:
            int.tryParse('${response['total_trip_expenses']}') ?? 0,
      );
    } catch (_) {
      final journeys = await _journeyService.listJourneys();
      final expenses = await _tripExpenseService.listExpenses();
      final fuelings = await _fuelingService.listFuelings();
      final maintenances = await _maintenanceService.listMaintenances();

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

      return AppDashboardMetrics(
        totalIncome: totalIncome,
        totalOperationalCosts: totalOperationalCosts,
        netResult: totalIncome - totalOperationalCosts,
        allocatedToGoals: 0,
        availableBalance: 0,
        totalJourneys: journeys.length,
        openJourneys: journeys.where((item) => !item.isFinished).length,
        totalDeliveries: journeys.fold<int>(
          0,
          (sum, item) => sum + item.totalDeliveries,
        ),
        totalDistanceKm: journeys.fold<double>(
          0,
          (sum, item) => sum + (item.distanceKm ?? 0),
        ),
        activeVehicles: 0,
        activePlatforms: 0,
        totalFuelings: fuelings.length,
        totalMaintenances: maintenances.length,
        totalTripExpenses: expenses.length,
      );
    }
  }

  Future<void> _applyTransactionClientSide({
    required String goalId,
    required double amount,
    required String? journeyId,
  }) async {
    final client = _authService.requireClient();
    final goals = await listGoals();
    AppGoal? goal;
    for (final item in goals) {
      if (item.id == goalId) {
        goal = item;
        break;
      }
    }
    if (goal == null) {
      throw StateError('Objetivo nao encontrado.');
    }

    final summary = await loadBalanceSummary();
    if (amount > 0 && amount > summary.availableBalance) {
      throw StateError(
        'Saldo disponivel insuficiente para aportar nesse objetivo.',
      );
    }

    if (amount < 0 && amount.abs() > goal.currentAmount) {
      throw StateError('Nao e possivel retirar mais do que o saldo do objetivo.');
    }

    final nextAmount = goal.currentAmount + amount;
    await client
        .schema('driver')
        .from('goals')
        .update({
          'current_amount': nextAmount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', goalId);

    await client.schema('driver').from('goal_transactions').insert({
      'goal_id': goalId,
      'journey_id': journeyId,
      'amount': amount,
    });
  }

  Future<Map<String, String>> _loadJourneyLabels() async {
    final options = await _journeyService.listJourneyOptions();
    return {for (final item in options) item.id: item.label};
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  DateTime? _tryParseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }

  double _toDouble(Object? value) => double.tryParse('$value') ?? 0;

  double? _stringToDouble(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
