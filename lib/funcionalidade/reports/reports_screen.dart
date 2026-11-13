import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_operational_intelligence.dart';
import '../../models/app_operational_report.dart';
import '../../models/plan_type.dart';
import '../../services/operational_intelligence_service.dart';
import '../../services/plan_access_service.dart';
import '../../services/product_analytics_service.dart';
import '../../services/report_export_service.dart';
import '../../services/reporting_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/state/app_session.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportingService _reportingService = ReportingService();
  final OperationalIntelligenceService _intelligenceService =
      OperationalIntelligenceService();
  final ReportExportService _reportExportService = ReportExportService();
  final PlanAccessService _planAccessService = const PlanAccessService();
  final ProductAnalyticsService _analyticsService =
      const ProductAnalyticsService();
  bool _loading = true;
  bool _exporting = false;
  String? _errorMessage;
  DateTimeRange? _range;
  _ReportPeriod _period = _ReportPeriod.month;
  AppOperationalReport? _report;
  AppOperationalReport? _previousReport;
  AppOperationalIntelligence? _intelligence;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final range = _currentRange;
      final previousRange = _previousRangeFor(range);
      final report = await _reportingService.loadOperationalReport(
        startAt: range.start,
        endAt: range.end,
      );
      final previousReport = await _reportingService.loadOperationalReport(
        startAt: previousRange.start,
        endAt: previousRange.end,
      );
      final intelligence = await _intelligenceService.load(
        preset: _intelligencePreset,
        customRange: range,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _previousReport = previousReport;
        _intelligence = intelligence;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Nao foi possivel carregar os relatorios nesse momento.',
          en: 'We could not load reports right now.',
          es: 'No pudimos cargar los reportes ahora.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final currentPlan =
        context.watch<AppSession>().profile?.planType ?? PlanType.free;
    final canExport = _planAccessService.canAccessAdvancedOperations(
      currentPlan,
    );

    if (!canExport) {
      final locked = _LockedReportsView(strings: strings);
      if (widget.embedded) return locked;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            strings.pick(pt: 'Relatorios', en: 'Reports', es: 'Reportes'),
          ),
        ),
        body: locked,
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final report =
        _report ??
        const AppOperationalReport(
          startAt: null,
          endAt: null,
          totalIncome: 0,
          totalOperationalCosts: 0,
          netResult: 0,
          totalJourneys: 0,
          totalDeliveries: 0,
          totalDistanceKm: 0,
          topPlatforms: [],
          expenseBreakdown: [],
        );
    final previousReport = _previousReport;
    final intelligence = _intelligence;

    final content = RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, widget.embedded ? 120 : 20),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_rangeLabel),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportReport('pdf', canExport: canExport),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportReport('excel', canExport: canExport),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel'),
                  ),
                  TextButton(
                    onPressed: _range == null
                        ? null
                        : () {
                            setState(() => _range = null);
                            _loadReport();
                          },
                    child: Text(
                      strings.pick(pt: 'Limpar', en: 'Clear', es: 'Limpiar'),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick(
                        pt: 'Relatorios operacionais',
                        en: 'Operations reports',
                        es: 'Reportes operativos',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.pick(
                        pt: 'Relatorios operacionais',
                        en: 'Operations reports',
                        es: 'Reportes operativos',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  actions,
                ],
              );
            },
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          _PeriodSelector(
            selected: _period,
            onSelected: (period) async {
              setState(() {
                _period = period;
                if (period != _ReportPeriod.custom) _range = null;
              });
              if (period == _ReportPeriod.custom) {
                await _pickRange();
              } else {
                await _loadReport();
              }
            },
          ),
          const SizedBox(height: 16),
          if (!canExport) _PremiumOnlyNotice(strings: strings),
          if (!canExport) const SizedBox(height: 16),
          if (_errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          _ReportMetricGrid(
            metrics: [
              _ReportMetricData(
                title: strings.income,
                value: _currency(report.totalIncome),
              ),
              _ReportMetricData(
                title: strings.costs,
                value: _currency(report.totalOperationalCosts),
              ),
              _ReportMetricData(
                title: strings.leftOver,
                value: _currency(report.netResult),
              ),
              _ReportMetricData(
                title: strings.journeys,
                value: '${report.totalJourneys}',
              ),
              _ReportMetricData(
                title: strings.deliveries,
                value: '${report.totalDeliveries}',
              ),
              _ReportMetricData(
                title: strings.distance,
                value: '${report.totalDistanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (previousReport != null) ...[
            _ComparisonReportCard(
              current: report,
              previous: previousReport,
              currency: _currency,
            ),
            const SizedBox(height: 16),
          ],
          _CashflowChartCard(
            income: report.totalIncome,
            costs: report.totalOperationalCosts,
            net: report.netResult,
            currency: _currency,
          ),
          const SizedBox(height: 16),
          _TopPlatformsCard(items: report.topPlatforms, currency: _currency),
          const SizedBox(height: 16),
          _CostBreakdownCard(
            items: report.expenseBreakdown,
            currency: _currency,
          ),
          const SizedBox(height: 16),
          _VehicleComparisonCard(
            items: report.vehicleComparison,
            currency: _currency,
          ),
          if (intelligence != null) ...[
            const SizedBox(height: 16),
            _ReportInsightsCard(insights: intelligence.insights),
          ],
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.pick(pt: 'Relatorios', en: 'Reports', es: 'Reportes'),
        ),
      ),
      body: content,
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange:
          _range ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = picked;
      _period = _ReportPeriod.custom;
    });
    await _loadReport();
  }

  Future<void> _exportReport(String type, {required bool canExport}) async {
    final report = _report;
    if (report == null || _exporting) return;
    if (!canExport) {
      await _analyticsService.track(
        'premium_export_blocked',
        screen: 'reports',
        metadata: {'type': type},
      );
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Exportar relatorios e um recurso Premium.',
          en: 'Report export is a Premium feature.',
          es: 'Exportar reportes es una funcion Premium.',
        );
      });
      return;
    }

    setState(() {
      _exporting = true;
      _errorMessage = null;
    });

    try {
      await _analyticsService.track(
        'report_export_started',
        screen: 'reports',
        metadata: {'type': type},
      );
      if (type == 'pdf') {
        await _reportExportService.sharePdf(
          report: report,
          currency: _currency,
        );
      } else {
        await _reportExportService.shareExcel(
          report: report,
          currency: _currency,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Nao foi possivel gerar o arquivo agora. Tente novamente em instantes.',
          en: 'We could not create the file right now. Please try again soon.',
          es: 'No pudimos crear el archivo ahora. Intentalo de nuevo pronto.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String get _rangeLabel {
    if (_period != _ReportPeriod.custom) return _period.label(context);
    if (_range == null) return AppStrings.of(context).period;
    return '${_formatDate(_range!.start)} - ${_formatDate(_range!.end)}';
  }

  DateTimeRange get _currentRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _ReportPeriod.week => DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: now,
      ),
      _ReportPeriod.month => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      _ReportPeriod.year => DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: now,
      ),
      _ReportPeriod.custom =>
        _range ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    };
  }

  DateTimeRange _previousRangeFor(DateTimeRange range) {
    final duration = range.duration;
    return DateTimeRange(
      start: range.start.subtract(duration),
      end: range.start,
    );
  }

  OperationalRangePreset get _intelligencePreset {
    return switch (_period) {
      _ReportPeriod.week => OperationalRangePreset.week,
      _ReportPeriod.month => OperationalRangePreset.month,
      _ReportPeriod.year => OperationalRangePreset.year,
      _ReportPeriod.custom => OperationalRangePreset.custom,
    };
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _currency(double value) => AppFormat.of(context).currency(value);
}

enum _ReportPeriod { week, month, year, custom }

extension _ReportPeriodLabel on _ReportPeriod {
  String label(BuildContext context) {
    final strings = AppStrings.of(context);
    return switch (this) {
      _ReportPeriod.week => strings.week,
      _ReportPeriod.month => strings.month,
      _ReportPeriod.year => strings.pick(pt: 'Ano', en: 'Year', es: 'Ano'),
      _ReportPeriod.custom => strings.custom,
    };
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ReportPeriod.values.map((period) {
        return ChoiceChip(
          selected: selected == period,
          label: Text(period.label(context)),
          onSelected: (_) => onSelected(period),
        );
      }).toList(),
    );
  }
}

class _PremiumOnlyNotice extends StatelessWidget {
  const _PremiumOnlyNotice({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.pick(
                  pt: 'Relatorios completos, comparativos e exportacoes fazem parte do Premium.',
                  en: 'Complete reports, comparisons and exports are Premium features.',
                  es: 'Reportes completos, comparativos y exportaciones son Premium.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedReportsView extends StatelessWidget {
  const _LockedReportsView({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 32),
                const SizedBox(height: 14),
                Text(
                  strings.pick(
                    pt: 'Relatorios Premium',
                    en: 'Premium reports',
                    es: 'Reportes Premium',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.pick(
                    pt: 'Comparativos semanais, mensais e anuais, graficos completos, insights, comparacao entre veiculos e exportacao PDF/Excel ficam disponiveis para Premium e Gift.',
                    en: 'Weekly, monthly and yearly comparisons, complete charts, insights, vehicle comparison and PDF/Excel export are available for Premium and Gift.',
                    es: 'Comparativos semanales, mensuales y anuales, graficos completos, insights, comparacion entre vehiculos y exportacion PDF/Excel estan disponibles para Premium y Gift.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonReportCard extends StatelessWidget {
  const _ComparisonReportCard({
    required this.current,
    required this.previous,
    required this.currency,
  });

  final AppOperationalReport current;
  final AppOperationalReport previous;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rows = [
      _ComparisonRowData(
        label: strings.income,
        current: currency(current.totalIncome),
        previous: currency(previous.totalIncome),
        delta: _moneyDelta(current.totalIncome, previous.totalIncome),
      ),
      _ComparisonRowData(
        label: strings.costs,
        current: currency(current.totalOperationalCosts),
        previous: currency(previous.totalOperationalCosts),
        delta: _moneyDelta(
          current.totalOperationalCosts,
          previous.totalOperationalCosts,
        ),
      ),
      _ComparisonRowData(
        label: strings.leftOver,
        current: currency(current.netResult),
        previous: currency(previous.netResult),
        delta: _moneyDelta(current.netResult, previous.netResult),
      ),
      _ComparisonRowData(
        label: strings.deliveries,
        current: '${current.totalDeliveries}',
        previous: '${previous.totalDeliveries}',
        delta: _countDelta(current.totalDeliveries, previous.totalDeliveries),
      ),
      _ComparisonRowData(
        label: strings.distance,
        current: '${current.totalDistanceKm.toStringAsFixed(1)} km',
        previous: '${previous.totalDistanceKm.toStringAsFixed(1)} km',
        delta: _moneyDelta(current.totalDistanceKm, previous.totalDistanceKm),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Comparativo avancado',
                en: 'Advanced comparison',
                es: 'Comparativo avanzado',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => _ComparisonRow(data: row)),
          ],
        ),
      ),
    );
  }

  String _moneyDelta(double current, double previous) {
    if (previous == 0) return current == 0 ? '0%' : '+100%';
    final value = ((current - previous) / previous.abs()) * 100;
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}%';
  }

  String _countDelta(int current, int previous) {
    if (previous == 0) return current == 0 ? '0%' : '+100%';
    final value = ((current - previous) / previous.abs()) * 100;
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}%';
  }
}

class _ComparisonRowData {
  const _ComparisonRowData({
    required this.label,
    required this.current,
    required this.previous,
    required this.delta,
  });

  final String label;
  final String current;
  final String previous;
  final String delta;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.data});

  final _ComparisonRowData data;

  @override
  Widget build(BuildContext context) {
    final positive = !data.delta.startsWith('-');
    final color = positive ? const Color(0xFF39E58C) : const Color(0xFFFF6F6F);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(data.current, style: Theme.of(context).textTheme.labelLarge),
              Text(
                'Antes: ${data.previous}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.delta,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleComparisonCard extends StatelessWidget {
  const _VehicleComparisonCard({required this.items, required this.currency});

  final List<VehiclePerformance> items;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final maxIncome = items.isEmpty
        ? 1.0
        : items
              .map((item) => item.income)
              .reduce(math.max)
              .clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Comparacao entre veiculos',
                en: 'Vehicle comparison',
                es: 'Comparacion entre vehiculos',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                strings.pick(
                  pt: 'Nenhuma jornada vinculada a veiculos nesse periodo.',
                  en: 'No journeys linked to vehicles in this period.',
                  es: 'No hay jornadas vinculadas a vehiculos en este periodo.',
                ),
              ),
            ...items.map(
              (item) => _ProgressRow(
                label: item.vehicleLabel,
                detail:
                    '${strings.deliveriesCount(item.deliveries)} | ${strings.journeysCount(item.journeys)} | ${item.distanceKm.toStringAsFixed(1)} km',
                value: currency(item.income),
                factor: (item.income / maxIncome).clamp(0.04, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportInsightsCard extends StatelessWidget {
  const _ReportInsightsCard({required this.insights});

  final List<OperationalInsight> insights;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Insights inteligentes',
                en: 'Smart insights',
                es: 'Insights inteligentes',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...insights.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: Text(
                  item.value,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetricData {
  const _ReportMetricData({required this.title, required this.value});

  final String title;
  final String value;
}

class _ReportMetricGrid extends StatelessWidget {
  const _ReportMetricGrid({required this.metrics});

  final List<_ReportMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 460
            ? 2
            : width < 900
            ? 3
            : 6;
        final spacing = width < 460 ? 10.0 : 14.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _ReportMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({required this.metric});

  final _ReportMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.title, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(metric.value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashflowChartCard extends StatelessWidget {
  const _CashflowChartCard({
    required this.income,
    required this.costs,
    required this.net,
    required this.currency,
  });

  final double income;
  final double costs;
  final double net;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final maxValue = [
      income.abs(),
      costs.abs(),
      net.abs(),
      1.0,
    ].reduce(math.max);
    final items = [
      _BarData(strings.income, income, const Color(0xFF39E58C)),
      _BarData(strings.costs, costs, const Color(0xFFFF6F6F)),
      _BarData(strings.leftOver, net, const Color(0xFF4E63FF)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Pulso financeiro',
                en: 'Money pulse',
                es: 'Pulso financiero',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                currency(item.value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: (item.value.abs() / maxValue)
                                        .clamp(0.08, 1.0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: LinearGradient(
                                          colors: [
                                            item.color.withValues(alpha: 0.32),
                                            item.color,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: const SizedBox(width: 42),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarData {
  const _BarData(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _TopPlatformsCard extends StatelessWidget {
  const _TopPlatformsCard({required this.items, required this.currency});

  final List<PlatformPerformance> items;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final maxIncome = items.isEmpty
        ? 1.0
        : items
              .map((item) => item.income)
              .reduce(math.max)
              .clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Top plataformas',
                en: 'Top platforms',
                es: 'Mejores plataformas',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                strings.pick(
                  pt: 'Nenhuma plataforma acumulada no periodo selecionado.',
                  en: 'No platform activity in the selected period.',
                  es: 'No hay actividad de plataformas en el periodo seleccionado.',
                ),
              ),
            ...items.map(
              (platform) => _ProgressRow(
                label: platform.platformName,
                detail: strings.deliveriesCount(platform.deliveries),
                value: currency(platform.income),
                factor: (platform.income / maxIncome).clamp(0.04, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostBreakdownCard extends StatelessWidget {
  const _CostBreakdownCard({required this.items, required this.currency});

  final List<ExpenseBreakdownItem> items;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final total = items
        .fold<double>(0, (sum, item) => sum + item.amount)
        .clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pick(
                pt: 'Mapa de custos',
                en: 'Cost map',
                es: 'Mapa de costos',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                strings.pick(
                  pt: 'Nenhum custo agregado no periodo selecionado.',
                  en: 'No costs in the selected period.',
                  es: 'No hay costos en el periodo seleccionado.',
                ),
              ),
            ...items.map(
              (item) => _ProgressRow(
                label: item.label,
                detail: strings.pick(
                  pt: '${((item.amount / total) * 100).toStringAsFixed(0)}% dos custos',
                  en: '${((item.amount / total) * 100).toStringAsFixed(0)}% of costs',
                  es: '${((item.amount / total) * 100).toStringAsFixed(0)}% de los costos',
                ),
                value: currency(item.amount),
                factor: (item.amount / total).clamp(0.04, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.factor,
  });

  final String label;
  final String detail;
  final String value;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
