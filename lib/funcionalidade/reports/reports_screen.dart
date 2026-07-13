import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/app_operational_report.dart';
import '../../services/reporting_service.dart';
import '../../utilities/localization/app_format.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportingService _reportingService = ReportingService();
  bool _loading = true;
  String? _errorMessage;
  DateTimeRange? _range;
  AppOperationalReport? _report;

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
      final report = await _reportingService.loadOperationalReport(
        startAt: _range?.start,
        endAt: _range?.end,
      );
      if (!mounted) return;
      setState(() => _report = report);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar os relatorios nesse momento.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Relatorios operacionais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_rangeLabel),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _range == null
                    ? null
                    : () {
                        setState(() => _range = null);
                        _loadReport();
                      },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                title: 'Receita',
                value: _currency(report.totalIncome),
              ),
              _ReportMetricData(
                title: 'Custos',
                value: _currency(report.totalOperationalCosts),
              ),
              _ReportMetricData(
                title: 'Liquido',
                value: _currency(report.netResult),
              ),
              _ReportMetricData(
                title: 'Jornadas',
                value: '${report.totalJourneys}',
              ),
              _ReportMetricData(
                title: 'Entregas',
                value: '${report.totalDeliveries}',
              ),
              _ReportMetricData(
                title: 'Distancia',
                value: '${report.totalDistanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
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
    setState(() => _range = picked);
    await _loadReport();
  }

  String get _rangeLabel {
    if (_range == null) return 'Periodo';
    return '${_formatDate(_range!.start)} - ${_formatDate(_range!.end)}';
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _currency(double value) => AppFormat.of(context).currency(value);
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
    final maxValue = [
      income.abs(),
      costs.abs(),
      net.abs(),
      1.0,
    ].reduce(math.max);
    final items = [
      _BarData('Receita', income, const Color(0xFF39E58C)),
      _BarData('Custos', costs, const Color(0xFFFF6F6F)),
      _BarData('Liquido', net, const Color(0xFF4E63FF)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulso financeiro',
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
              'Top plataformas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Nenhuma plataforma acumulada no periodo selecionado.',
              ),
            ...items.map(
              (platform) => _ProgressRow(
                label: platform.platformName,
                detail: '${platform.deliveries} entregas',
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
              'Mapa de custos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Nenhum custo agregado no periodo selecionado.'),
            ...items.map(
              (item) => _ProgressRow(
                label: item.label,
                detail:
                    '${((item.amount / total) * 100).toStringAsFixed(0)}% dos custos',
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
