class AppGamificationSummary {
  const AppGamificationSummary({
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.nextLevelXp,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.medalsCount,
    required this.rankingOptIn,
    required this.publicScore,
    required this.records,
    required this.medals,
  });

  final int xp;
  final int level;
  final String levelTitle;
  final int? nextLevelXp;
  final int currentStreakDays;
  final int bestStreakDays;
  final int medalsCount;
  final bool rankingOptIn;
  final int publicScore;
  final AppDriverRecords records;
  final List<AppDriverMedal> medals;

  double get progressToNextLevel {
    if (nextLevelXp == null) return 1;
    final startXp = _levelThreshold(level);
    final span = (nextLevelXp! - startXp).clamp(1, 1000000);
    return ((xp - startXp) / span).clamp(0, 1).toDouble();
  }

  int? get remainingXpToNextLevel {
    if (nextLevelXp == null) return null;
    return (nextLevelXp! - xp).clamp(0, 1000000);
  }

  static int _levelThreshold(int level) {
    return switch (level) {
      8 => 3500,
      7 => 2600,
      6 => 1900,
      5 => 1350,
      4 => 900,
      3 => 550,
      2 => 250,
      _ => 0,
    };
  }
}

class AppDriverRecords {
  const AppDriverRecords({
    required this.bestFridayDate,
    required this.highestRevenueDayDate,
    required this.highestProfitPerHourStartedAt,
    required this.highestDeliveriesDayDate,
    required this.highestDeliveriesCount,
  });

  final DateTime? bestFridayDate;
  final DateTime? highestRevenueDayDate;
  final DateTime? highestProfitPerHourStartedAt;
  final DateTime? highestDeliveriesDayDate;
  final int highestDeliveriesCount;
}

class AppDriverMedal {
  const AppDriverMedal({
    required this.key,
    required this.name,
    required this.description,
    required this.awardedAt,
    required this.metadata,
  });

  final String key;
  final String name;
  final String? description;
  final DateTime? awardedAt;
  final Map<String, dynamic> metadata;
}

class AppDriverMission {
  const AppDriverMission({
    required this.key,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.rewardXp,
    required this.completed,
  });

  final String key;
  final String title;
  final String description;
  final int target;
  final int current;
  final int rewardXp;
  final bool completed;

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
}

class AppGrowthSummary {
  const AppGrowthSummary({
    required this.tier,
    required this.nextTierScore,
    required this.publicScore,
    required this.missions,
    required this.stats,
  });

  final String tier;
  final int nextTierScore;
  final int publicScore;
  final List<AppDriverMission> missions;
  final Map<String, dynamic> stats;

  int get totalDeliveries => int.tryParse('${stats['total_deliveries']}') ?? 0;
  int get accountDays => int.tryParse('${stats['account_days']}') ?? 0;
  int get visibleBadges => int.tryParse('${stats['visible_badges']}') ?? 0;
}
