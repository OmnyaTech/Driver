import 'package:flutter/material.dart';

import '../models/app_dashboard_metrics.dart';
import '../models/app_operational_intelligence.dart';
import '../models/app_journey.dart';
import 'dashboard_metrics_service.dart';
import 'driver_preference_service.dart';
import 'goal_service.dart';
import 'journey_service.dart';

enum OperationalRangePreset { today, week, month, custom }

class OperationalIntelligenceService {
  OperationalIntelligenceService({
    DashboardMetricsService? dashboardMetricsService,
    JourneyService? journeyService,
    GoalService? goalService,
    DriverPreferenceService? driverPreferenceService,
  }) : _dashboardMetricsService =
           dashboardMetricsService ?? DashboardMetricsService(),
       _journeyService = journeyService ?? JourneyService(),
       _goalService = goalService ?? GoalService(),
       _driverPreferenceService =
           driverPreferenceService ?? DriverPreferenceService();

  final DashboardMetricsService _dashboardMetricsService;
  final JourneyService _journeyService;
  final GoalService _goalService;
  final DriverPreferenceService _driverPreferenceService;

  Future<AppOperationalIntelligence> load({
    required OperationalRangePreset preset,
    DateTimeRange? customRange,
  }) async {
    final now = DateTime.now();
    final currentRange = _resolveRange(preset, customRange, now);
    final duration = currentRange.duration;
    final previousRange = DateTimeRange(
      start: currentRange.start.subtract(duration),
      end: currentRange.start,
    );

    final currentMetrics = await _dashboardMetricsService.loadMetrics(
      startAt: currentRange.start,
      endAt: currentRange.end,
    );
    final previousMetrics = await _dashboardMetricsService.loadMetrics(
      startAt: previousRange.start,
      endAt: previousRange.end,
    );
    final journeys = await _journeyService.listJourneys();
    final balance = await _goalService.loadBalanceSummary();
    final reservePreference = await _driverPreferenceService
        .loadReservePreference();

    final filteredJourneys = journeys.where(
      (item) => _inRange(item.startedAt.toLocal(), currentRange),
    );
    final journeyList = filteredJourneys.toList();
    final trend = _buildTrend(journeyList, currentRange);
    final insights = _buildInsights(journeyList, currentMetrics);
    final periodKey = _periodWordForPreset(preset);
    final suggestedReserve = _driverPreferenceService
        .calculateSuggestedReserve(
          preference: reservePreference,
          netResult: currentMetrics.netResult,
          deliveries: currentMetrics.totalDeliveries,
        )
        .clamp(
          0,
          balance.availableBalance > 0 ? balance.availableBalance : 5000,
        )
        .toDouble();

    return AppOperationalIntelligence(
      periodLabel: _labelForPreset(preset, currentRange),
      periodStart: currentRange.start,
      periodEnd: currentRange.end,
      currentMetrics: currentMetrics,
      previousMetrics: previousMetrics,
      trend: trend,
      insights: insights,
      suggestedReserve: suggestedReserve,
      suggestedReserveLabel: _driverPreferenceService.buildSuggestionLabel(
        preference: reservePreference,
        amount: suggestedReserve,
        periodLabel: periodKey,
      ),
    );
  }

  DateTimeRange _resolveRange(
    OperationalRangePreset preset,
    DateTimeRange? customRange,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (preset) {
      OperationalRangePreset.today => DateTimeRange(start: today, end: now),
      OperationalRangePreset.week => DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: now,
      ),
      OperationalRangePreset.month => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      OperationalRangePreset.custom =>
        customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    };
  }

  bool _inRange(DateTime value, DateTimeRange range) {
    return !value.isBefore(range.start) &&
        value.isBefore(range.end.add(const Duration(milliseconds: 1)));
  }

  List<OperationalTrendPoint> _buildTrend(
    Iterable<AppJourney> journeys,
    DateTimeRange range,
  ) {
    final dayBuckets = <DateTime, double>{};
    var cursor = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    while (!cursor.isAfter(end)) {
      dayBuckets[cursor] = 0;
      cursor = cursor.add(const Duration(days: 1));
    }

    for (final journey in journeys) {
      final key = DateTime(
        journey.startedAt.year,
        journey.startedAt.month,
        journey.startedAt.day,
      );
      dayBuckets.update(
        key,
        (value) => value + journey.totalIncome,
        ifAbsent: () => journey.totalIncome,
      );
    }

    return dayBuckets.entries
        .map(
          (entry) => OperationalTrendPoint(
            label:
                '${entry.key.day.toString().padLeft(2, '0')}/${entry.key.month.toString().padLeft(2, '0')}',
            value: entry.value,
          ),
        )
        .toList();
  }

  List<OperationalInsight> _buildInsights(
    List<AppJourney> journeys,
    AppDashboardMetrics metrics,
  ) {
    if (journeys.isEmpty) {
      return const [
        OperationalInsight(
          title: 'Sem base suficiente',
          value: 'Comece hoje',
          description:
              'Registre jornadas e fontes de receita para desbloquear os insights operacionais.',
        ),
      ];
    }

    final hourIncome = <int, double>{};
    final weekdayIncome = <int, double>{};
    final platformIncome = <String, double>{};

    for (final journey in journeys) {
      hourIncome.update(
        journey.startedAt.hour,
        (value) => value + journey.totalIncome,
        ifAbsent: () => journey.totalIncome,
      );
      weekdayIncome.update(
        journey.startedAt.weekday,
        (value) => value + journey.totalIncome,
        ifAbsent: () => journey.totalIncome,
      );
      for (final platform in journey.platformBreakdown) {
        platformIncome.update(
          platform.platformName,
          (value) => value + platform.income,
          ifAbsent: () => platform.income,
        );
      }
    }

    final bestHour = _maxEntry(hourIncome);
    final bestWeekday = _maxEntry(weekdayIncome);
    final bestPlatform = _maxEntry(platformIncome);
    final productivity = metrics.totalJourneys == 0
        ? 0
        : metrics.totalDeliveries / metrics.totalJourneys;

    return [
      OperationalInsight(
        title: 'Melhor horario',
        value: bestHour == null
            ? '--'
            : '${bestHour.key.toString().padLeft(2, '0')}h',
        description: bestHour == null
            ? 'Sem dados suficientes.'
            : 'Esse horario concentrou o maior faturamento da janela.',
      ),
      OperationalInsight(
        title: 'Melhor dia',
        value: bestWeekday == null ? '--' : _weekdayLabel(bestWeekday.key),
        description: bestWeekday == null
            ? 'Sem dados suficientes.'
            : 'Seu melhor dia em receita dentro do periodo atual.',
      ),
      OperationalInsight(
        title: 'Plataforma mais lucrativa',
        value: bestPlatform?.key ?? 'Sem plataforma',
        description: bestPlatform == null
            ? 'Sem dados suficientes.'
            : 'Liderou sua receita com melhor retorno consolidado.',
      ),
      OperationalInsight(
        title: 'Ritmo medio',
        value: '${productivity.toStringAsFixed(1)} ent./jornada',
        description:
            'Use esse indicador para comparar sua eficiencia por turno.',
      ),
    ];
  }

  MapEntry<T, double>? _maxEntry<T>(Map<T, double> values) {
    if (values.isEmpty) return null;
    return values.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  String _labelForPreset(OperationalRangePreset preset, DateTimeRange range) {
    return switch (preset) {
      OperationalRangePreset.today => 'Hoje',
      OperationalRangePreset.week => 'Semana atual',
      OperationalRangePreset.month => 'Mes atual',
      OperationalRangePreset.custom =>
        '${range.start.day.toString().padLeft(2, '0')}/${range.start.month.toString().padLeft(2, '0')} - ${range.end.day.toString().padLeft(2, '0')}/${range.end.month.toString().padLeft(2, '0')}',
    };
  }

  String _periodWordForPreset(OperationalRangePreset preset) {
    return switch (preset) {
      OperationalRangePreset.today => 'hoje',
      OperationalRangePreset.week => 'esta semana',
      OperationalRangePreset.month => 'este mes',
      OperationalRangePreset.custom => 'no periodo selecionado',
    };
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Segunda',
      DateTime.tuesday => 'Terca',
      DateTime.wednesday => 'Quarta',
      DateTime.thursday => 'Quinta',
      DateTime.friday => 'Sexta',
      DateTime.saturday => 'Sabado',
      DateTime.sunday => 'Domingo',
      _ => '--',
    };
  }
}
