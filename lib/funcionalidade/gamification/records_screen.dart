import 'package:flutter/material.dart';

import '../../models/app_gamification.dart';
import '../../services/gamification_service.dart';
import '../../utilities/ui/omnya_shell.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final GamificationService _service = GamificationService();
  bool _loading = true;
  AppDriverRecords? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await _service.loadSummary();
    if (!mounted) return;
    setState(() {
      _records = summary.records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Recordes',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final records =
        _records ??
        const AppDriverRecords(
          bestFridayDate: null,
          highestRevenueDayDate: null,
          highestProfitPerHourStartedAt: null,
          highestDeliveriesDayDate: null,
          highestDeliveriesCount: 0,
        );

    return OmnyaSubPageScaffold(
      title: 'Recordes',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _RecordCard(
            title: 'Melhor sexta-feira',
            value: _format(records.bestFridayDate),
            detail:
                'Dia em que sua sexta apareceu com melhor destaque operacional.',
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Maior faturamento diario',
            value: _format(records.highestRevenueDayDate),
            detail: 'Recorde de receita em um unico dia registrado.',
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Melhor lucro por hora',
            value: _formatDateTime(records.highestProfitPerHourStartedAt),
            detail: 'Jornada mais eficiente por hora dentro do historico.',
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Maior volume de entregas',
            value: records.highestDeliveriesCount == 0
                ? 'Sem registro'
                : '${records.highestDeliveriesCount} entregas',
            detail: records.highestDeliveriesDayDate == null
                ? 'Ainda sem historico suficiente.'
                : 'Aconteceu em ${_format(records.highestDeliveriesDayDate)}.',
          ),
        ],
      ),
    );
  }

  String _format(DateTime? value) {
    if (value == null) return 'Sem registro';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Sem registro';
    final local = value.toLocal();
    return '${_format(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
