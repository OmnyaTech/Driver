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
      levelTitle: data['level_title']?.toString() ?? 'Motorista iniciante',
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

  int _toInt(Object? value) => int.tryParse('$value') ?? 0;
  int? _nullableInt(Object? value) => value == null ? null : _toInt(value);
  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
