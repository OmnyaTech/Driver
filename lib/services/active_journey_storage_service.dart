import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ActiveJourneyDraft {
  const ActiveJourneyDraft({
    this.journeyId,
    required this.startedAt,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.odometerStart,
  });

  final String? journeyId;
  final DateTime startedAt;
  final String? vehicleId;
  final String? vehicleLabel;
  final String odometerStart;

  Map<String, dynamic> toJson() => {
    'journeyId': journeyId,
    'startedAt': startedAt.toIso8601String(),
    'vehicleId': vehicleId,
    'vehicleLabel': vehicleLabel,
    'odometerStart': odometerStart,
  };

  ActiveJourneyDraft copyWith({
    String? journeyId,
    DateTime? startedAt,
    String? vehicleId,
    String? vehicleLabel,
    String? odometerStart,
  }) {
    return ActiveJourneyDraft(
      journeyId: journeyId ?? this.journeyId,
      startedAt: startedAt ?? this.startedAt,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      odometerStart: odometerStart ?? this.odometerStart,
    );
  }

  factory ActiveJourneyDraft.fromJson(Map<String, dynamic> json) {
    return ActiveJourneyDraft(
      journeyId: json['journeyId']?.toString(),
      startedAt: DateTime.parse(json['startedAt'].toString()),
      vehicleId: json['vehicleId']?.toString(),
      vehicleLabel: json['vehicleLabel']?.toString(),
      odometerStart: json['odometerStart']?.toString() ?? '',
    );
  }
}

class ActiveJourneyStorageService {
  static const _key = 'driver.active_journey.v1';

  Future<ActiveJourneyDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      return ActiveJourneyDraft.fromJson(data);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(ActiveJourneyDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
