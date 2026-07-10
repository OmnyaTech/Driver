import 'package:flutter/material.dart';

import '../../models/app_journey.dart';
import '../../models/app_platform.dart';
import '../../models/app_vehicle.dart';
import '../../services/journey_service.dart';
import '../../services/platform_service.dart';
import '../../services/vehicle_service.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({super.key});

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> {
  final JourneyService _journeyService = JourneyService();
  bool _loading = true;
  List<AppJourney> _journeys = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final journeys = await _journeyService.listJourneys();
      if (!mounted) return;
      setState(() {
        _journeys = journeys;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar as jornadas agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final vehicles = await VehicleService().listVehicles();
    final platforms = await PlatformService().listPlatforms();
    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _JourneyFormDialog(
        vehicles: vehicles.where((item) => item.active).toList(),
        platforms: platforms.where((item) => item.active).toList(),
        onSubmit:
            ({
              required mode,
              required startedAt,
              required endedAt,
              required vehicleId,
              required odometerStart,
              required odometerEnd,
              required notes,
              required platforms,
            }) async {
              await _journeyService.createJourney(
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                vehicleId: vehicleId,
                odometerStart: odometerStart,
                odometerEnd: odometerEnd,
                notes: notes,
                platforms: platforms,
              );
            },
      ),
    );

    if (created == true) {
      await _loadJourneys();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadJourneys,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jornadas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova'),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            if (_journeys.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma jornada registrada ainda. Crie a primeira para iniciar o controle operacional.',
                  ),
                ),
              ),
            ..._journeys.map(
              (journey) => Card(
                child: ExpansionTile(
                  title: Text(_formatJourneyTitle(journey)),
                  subtitle: Text(
                    [
                      _formatDate(journey.startedAt),
                      if (journey.vehicleLabel != null) journey.vehicleLabel!,
                      '${journey.totalDeliveries} entregas',
                      'R\$ ${journey.totalIncome.toStringAsFixed(2)}',
                      journey.isFinished ? 'Finalizada' : 'Em aberto',
                    ].join(' - '),
                  ),
                  children: [
                    if (journey.distanceKm != null ||
                        (journey.notes?.trim().isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (journey.distanceKm != null)
                              Text(
                                'Distancia: ${journey.distanceKm!.toStringAsFixed(1)} km',
                              ),
                            if (journey.notes?.trim().isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(journey.notes!.trim()),
                              ),
                          ],
                        ),
                      ),
                    if (journey.platformBreakdown.isNotEmpty)
                      ...journey.platformBreakdown.map(
                        (platform) => ListTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(platform.platformName),
                          subtitle: Text(
                            '${platform.deliveries} entregas',
                          ),
                          trailing: Text(
                            'R\$ ${platform.income.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJourneyTitle(AppJourney journey) {
    final end = journey.endedAt;
    final start = journey.startedAt.toLocal();
    final startLabel =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return '$startLabel em andamento';
    final localEnd = end.toLocal();
    final endLabel =
        '${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}';
    return '$startLabel ate $endLabel';
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _JourneyFormDialog extends StatefulWidget {
  const _JourneyFormDialog({
    required this.vehicles,
    required this.platforms,
    required this.onSubmit,
  });

  final List<AppVehicle> vehicles;
  final List<AppPlatform> platforms;
  final Future<void> Function({
    required String mode,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String? vehicleId,
    required String odometerStart,
    required String odometerEnd,
    required String notes,
    required List<JourneyPlatformDraft> platforms,
  })
  onSubmit;

  @override
  State<_JourneyFormDialog> createState() => _JourneyFormDialogState();
}

class _JourneyFormDialogState extends State<_JourneyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _odometerStartController = TextEditingController();
  final _odometerEndController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_PlatformIncomeEntry> _platformEntries = [_PlatformIncomeEntry()];
  String _mode = 'manual';
  String? _vehicleId;
  DateTime _startedAt = DateTime.now();
  DateTime? _endedAt;
  bool _saving = false;
  String? _submitError;

  @override
  void dispose() {
    _odometerStartController.dispose();
    _odometerEndController.dispose();
    _notesController.dispose();
    for (final entry in _platformEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova jornada'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: const InputDecoration(labelText: 'Modo'),
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual')),
                    DropdownMenuItem(value: 'quick', child: Text('Rapida')),
                    DropdownMenuItem(
                      value: 'automatic',
                      child: Text('Automatica'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _mode = value ?? 'manual'),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _vehicleId,
                  decoration: const InputDecoration(labelText: 'Veiculo'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem vincular'),
                    ),
                    ...widget.vehicles.map(
                      (vehicle) => DropdownMenuItem<String?>(
                        value: vehicle.id,
                        child: Text('${vehicle.brand} ${vehicle.model}'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _vehicleId = value),
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  label: 'Inicio',
                  value: _startedAt,
                  onChanged: (value) => setState(() => _startedAt = value),
                ),
                _DateTimeTile(
                  label: 'Fim',
                  value: _endedAt,
                  emptyLabel: 'Em aberto',
                  onChanged: (value) => setState(() => _endedAt = value),
                ),
                TextFormField(
                  controller: _odometerStartController,
                  decoration: const InputDecoration(labelText: 'Km inicial'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateDistanceField,
                ),
                TextFormField(
                  controller: _odometerEndController,
                  decoration: const InputDecoration(labelText: 'Km final'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateDistanceField,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Receita por plataforma',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(
                          () => _platformEntries.add(_PlatformIncomeEntry()),
                        );
                      },
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                ..._platformEntries.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: entry.value.platformId,
                            decoration: const InputDecoration(
                              labelText: 'Plataforma',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Selecionar'),
                              ),
                              ...widget.platforms.map(
                                (platform) => DropdownMenuItem(
                                  value: platform.id,
                                  child: Text(platform.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              entry.value.platformId = value ?? '';
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: entry.value.incomeController,
                            decoration: const InputDecoration(
                              labelText: 'Ganho',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: entry.value.deliveriesController,
                            decoration: const InputDecoration(
                              labelText: 'Entregas',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        if (_platformEntries.length > 1)
                          IconButton(
                            onPressed: () {
                              final removed = _platformEntries.removeAt(
                                entry.key,
                              );
                              removed.dispose();
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_submitError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _submitError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_endedAt != null && _endedAt!.isBefore(_startedAt)) {
                    setState(() {
                      _submitError =
                          'O horario de fim nao pode ser anterior ao inicio.';
                    });
                    return;
                  }

                  final navigator = Navigator.of(context);
                  setState(() {
                    _saving = true;
                    _submitError = null;
                  });
                  try {
                    await widget.onSubmit(
                      mode: _mode,
                      startedAt: _startedAt,
                      endedAt: _endedAt,
                      vehicleId: _vehicleId,
                      odometerStart: _odometerStartController.text,
                      odometerEnd: _odometerEndController.text,
                      notes: _notesController.text,
                      platforms: _platformEntries
                          .map(
                            (entry) => JourneyPlatformDraft(
                              platformId: entry.platformId,
                              income: entry.incomeController.text,
                              deliveries: entry.deliveriesController.text,
                            ),
                          )
                          .toList(),
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _submitError =
                          'Nao foi possivel salvar a jornada agora. ${error.toString()}';
                    });
                  } finally {
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  }
                },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _validateDistanceField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return 'Informe um numero valido.';
    }
    return null;
  }
}

class _PlatformIncomeEntry {
  _PlatformIncomeEntry();

  String platformId = '';
  final incomeController = TextEditingController();
  final deliveriesController = TextEditingController();

  void dispose() {
    incomeController.dispose();
    deliveriesController.dispose();
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.emptyLabel,
  });

  final String label;
  final DateTime? value;
  final String? emptyLabel;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null
            ? (emptyLabel ?? 'Nao definido')
            : _format(value!.toLocal()),
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final now = value ?? DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        );
        if (time == null) return;
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
    );
  }

  String _format(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
