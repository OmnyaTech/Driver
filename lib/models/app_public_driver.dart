class AppPublicDriverPreview {
  const AppPublicDriverPreview({
    required this.publicSlug,
    required this.displayName,
    required this.avatarUrl,
    required this.publicCity,
    required this.level,
    required this.levelTitle,
    required this.medalsCount,
    required this.publicScore,
    required this.bestStreakDays,
    this.rankPosition,
  });

  final String publicSlug;
  final String displayName;
  final String? avatarUrl;
  final String? publicCity;
  final int level;
  final String levelTitle;
  final int medalsCount;
  final int publicScore;
  final int bestStreakDays;
  final int? rankPosition;
}

class AppPublicDriverProfile {
  const AppPublicDriverProfile({
    required this.displayName,
    required this.avatarUrl,
    required this.publicSlug,
    required this.publicBio,
    required this.publicCity,
    required this.level,
    required this.levelTitle,
    required this.xp,
    required this.medalsCount,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.bestFridayDate,
    required this.highestRevenueDayDate,
    required this.highestProfitPerHourStartedAt,
    required this.highestDeliveriesDayDate,
    required this.highestDeliveriesCount,
  });

  final String displayName;
  final String? avatarUrl;
  final String publicSlug;
  final String? publicBio;
  final String? publicCity;
  final int level;
  final String levelTitle;
  final int xp;
  final int medalsCount;
  final int currentStreakDays;
  final int bestStreakDays;
  final DateTime? bestFridayDate;
  final DateTime? highestRevenueDayDate;
  final DateTime? highestProfitPerHourStartedAt;
  final DateTime? highestDeliveriesDayDate;
  final int highestDeliveriesCount;
}
