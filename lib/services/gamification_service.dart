import '../models/app_gamification.dart';
import 'auth_service.dart';

class GamificationService {
  GamificationService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<AppGamificationSummary> loadSummary() async {
    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('get_driver_gamification_summary');

    final data = Map<String, dynamic>.from(response as Map);
    final records = Map<String, dynamic>.from(
      (data['records'] as Map?) ?? const <String, dynamic>{},
    );
    final medalsRaw = (data['medals'] as List? ?? const []).cast<dynamic>();

    return AppGamificationSummary(
      xp: _toInt(data['xp']),
      level: _toInt(data['level']),
      levelTitle: _driverTitle(data['level_title']),
      nextLevelXp: _nullableInt(data['next_level_xp']),
      currentStreakDays: _toInt(data['current_streak_days']),
      bestStreakDays: _toInt(data['best_streak_days']),
      medalsCount: _toInt(data['medals_count']),
      rankingOptIn: data['ranking_opt_in'] as bool? ?? false,
      publicScore: _toInt(data['public_score']),
      records: AppDriverRecords(
        bestFridayDate: _parseDate(records['best_friday']?['date']),
        highestRevenueDayDate: _parseDate(
          records['highest_revenue_day']?['date'],
        ),
        highestProfitPerHourStartedAt: _parseDate(
          records['highest_profit_per_hour']?['started_at'],
        ),
        highestDeliveriesDayDate: _parseDate(
          records['highest_deliveries_day']?['date'],
        ),
        highestDeliveriesCount: _toInt(
          records['highest_deliveries_day']?['deliveries'],
        ),
      ),
      medals: medalsRaw
          .map(
            (item) => AppDriverMedal(
              key: (item as Map)['key']?.toString() ?? 'medal',
              name: item['name']?.toString() ?? 'Medalha',
              description: item['description']?.toString(),
              awardedAt: _parseDate(item['awarded_at']),
              metadata: Map<String, dynamic>.from(
                (item['metadata'] as Map?) ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList(),
    );
  }

  Future<AppGrowthSummary> loadGrowthSummary() async {
    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('get_driver_growth_summary');
    final data = Map<String, dynamic>.from(response as Map);
    final missionsRaw = (data['missions'] as List? ?? const []).cast<dynamic>();
    final claimedMissionKeys = await _loadClaimedMissionKeys();
    return AppGrowthSummary(
      tier: data['tier']?.toString() ?? 'Bronze',
      nextTierScore: _toInt(data['next_tier_score']),
      publicScore: _toInt(data['public_score']),
      stats: Map<String, dynamic>.from(
        (data['stats'] as Map?) ?? const <String, dynamic>{},
      ),
      missions: missionsRaw.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return AppDriverMission(
          key: row['key']?.toString() ?? 'mission',
          title: row['title']?.toString() ?? 'Missao',
          description: row['description']?.toString() ?? '',
          target: _toInt(row['target_value'] ?? row['target']),
          current: _toInt(row['current_value'] ?? row['current']),
          rewardXp: _toInt(row['reward_xp']),
          rewardTitle: row['reward_title']?.toString(),
          completed: row['completed'] as bool? ?? false,
          claimed: claimedMissionKeys.contains(row['key']?.toString()),
        );
      }).toList(),
    );
  }

  Future<Set<String>> _loadClaimedMissionKeys() async {
    try {
      final client = _authService.requireClient();
      final now = DateTime.now().toUtc();
      final weekStart = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final rows = await client
          .schema('driver')
          .from('driver_mission_claims')
          .select('mission_key')
          .gte('claimed_at', weekStart.toIso8601String());
      return rows
          .map((row) => (row as Map)['mission_key']?.toString())
          .whereType<String>()
          .toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  Future<Map<String, dynamic>> claimMission(String missionKey) async {
    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('claim_driver_mission', params: {'p_mission_key': missionKey});
    return Map<String, dynamic>.from((response as Map?) ?? const {});
  }

  String _driverTitle(Object? value) {
    return (value?.toString() ?? 'Entregador iniciante')
        .replaceAll('Motorista', 'Entregador')
        .replaceAll('motorista', 'entregador');
  }

  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
  int? _nullableInt(Object? value) => value == null ? null : _toInt(value);
  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
