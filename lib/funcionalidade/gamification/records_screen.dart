import 'package:flutter/material.dart';

import '../../models/app_gamification.dart';
import '../../services/gamification_service.dart';
import '../../utilities/localization/app_strings.dart';
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
    final strings = AppStrings.of(context);
    if (_loading) {
      return OmnyaSubPageScaffold(
        title: strings.records,
        body: const Center(child: CircularProgressIndicator()),
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
      title: strings.records,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _RecordCard(
            title: strings.pick(
              pt: 'Melhor sexta-feira',
              en: 'Best Friday',
              es: 'Mejor viernes',
            ),
            value: _format(context, records.bestFridayDate),
            detail: strings.pick(
              pt: 'Sua sexta que mais brilhou ate agora.',
              en: 'Your strongest Friday so far.',
              es: 'Tu viernes mas fuerte hasta ahora.',
            ),
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: strings.pick(
              pt: 'Maior dia de ganho',
              en: 'Best earning day',
              es: 'Mejor dia de ganancia',
            ),
            value: _format(context, records.highestRevenueDayDate),
            detail: strings.pick(
              pt: 'O dia em que entrou mais dinheiro no app.',
              en: 'The day with the highest income in the app.',
              es: 'El dia con mas dinero registrado en la app.',
            ),
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: strings.pick(
              pt: 'Melhor lucro por hora',
              en: 'Best profit per hour',
              es: 'Mejor ganancia por hora',
            ),
            value: _formatDateTime(
              context,
              records.highestProfitPerHourStartedAt,
            ),
            detail: strings.pick(
              pt: 'Seu turno que rendeu melhor por hora.',
              en: 'Your shift with the best hourly return.',
              es: 'Tu turno con mejor rendimiento por hora.',
            ),
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: strings.pick(
              pt: 'Mais entregas no dia',
              en: 'Most deliveries in a day',
              es: 'Mas entregas en un dia',
            ),
            value: records.highestDeliveriesCount == 0
                ? strings.pick(
                    pt: 'Sem registro',
                    en: 'No record',
                    es: 'Sin registro',
                  )
                : strings.deliveriesCount(records.highestDeliveriesCount),
            detail: records.highestDeliveriesDayDate == null
                ? strings.pick(
                    pt: 'Ainda falta um pouco de historico.',
                    en: 'A bit more history is needed.',
                    es: 'Aun falta un poco de historial.',
                  )
                : strings.pick(
                    pt: 'Aconteceu em ${_format(context, records.highestDeliveriesDayDate)}.',
                    en: 'It happened on ${_format(context, records.highestDeliveriesDayDate)}.',
                    es: 'Paso el ${_format(context, records.highestDeliveriesDayDate)}.',
                  ),
          ),
        ],
      ),
    );
  }

  String _format(BuildContext context, DateTime? value) {
    final strings = AppStrings.of(context);
    if (value == null) {
      return strings.pick(
        pt: 'Sem registro',
        en: 'No record',
        es: 'Sin registro',
      );
    }
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatDateTime(BuildContext context, DateTime? value) {
    final strings = AppStrings.of(context);
    if (value == null) {
      return strings.pick(
        pt: 'Sem registro',
        en: 'No record',
        es: 'Sin registro',
      );
    }
    final local = value.toLocal();
    return '${_format(context, local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
