class AppJourney {
  const AppJourney({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.odometerStart,
    required this.odometerEnd,
    required this.notes,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.totalIncome,
    required this.totalDeliveries,
    required this.platformBreakdown,
  });

  final String id;
  final String mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? odometerStart;
  final double? odometerEnd;
  final String? notes;
  final String? vehicleId;
  final String? vehicleLabel;
  final double totalIncome;
  final int totalDeliveries;
  final List<JourneyPlatformSummary> platformBreakdown;

  bool get isFinished => endedAt != null;

  Duration get workedDuration {
    final end = endedAt;
    if (end == null || end.isBefore(startedAt)) return Duration.zero;
    return end.difference(startedAt);
  }

  double? get distanceKm {
    if (odometerStart == null || odometerEnd == null) return null;
    final distance = odometerEnd! - odometerStart!;
    return distance < 0 ? null : distance;
  }
}

class JourneyPlatformSummary {
  const JourneyPlatformSummary({
    required this.platformId,
    required this.platformName,
    required this.income,
    required this.deliveries,
  });

  final String? platformId;
  final String platformName;
  final double income;
  final int deliveries;
}
