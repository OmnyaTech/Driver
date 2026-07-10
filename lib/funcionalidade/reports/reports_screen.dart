import 'package:flutter/material.dart';

import '../../models/app_operational_report.dart';
import '../../services/reporting_service.dart';

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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ReportMetricCard(
                title: 'Receita',
                value: _currency(report.totalIncome),
              ),
              _ReportMetricCard(
                title: 'Custos',
                value: _currency(report.totalOperationalCosts),
              ),
              _ReportMetricCard(
                title: 'Liquido',
                value: _currency(report.netResult),
              ),
              _ReportMetricCard(
                title: 'Jornadas',
                value: '${report.totalJourneys}',
              ),
              _ReportMetricCard(
                title: 'Entregas',
                value: '${report.totalDeliveries}',
              ),
              _ReportMetricCard(
                title: 'Distancia',
                value: '${report.totalDistanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top plataformas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (report.topPlatforms.isEmpty)
                    const Text(
                      'Nenhuma plataforma acumulada no periodo selecionado.',
                    ),
                  ...report.topPlatforms.map(
                    (platform) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(platform.platformName),
                      subtitle: Text('${platform.deliveries} entregas'),
                      trailing: Text(_currency(platform.income)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quebra de custos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (report.expenseBreakdown.isEmpty)
                    const Text(
                      'Nenhum custo agregado no periodo selecionado.',
                    ),
                  ...report.expenseBreakdown.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.label),
                      trailing: Text(_currency(item.amount)),
                    ),
                  ),
                ],
              ),
            ),
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
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
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

  String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
