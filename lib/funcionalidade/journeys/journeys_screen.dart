import 'package:flutter/material.dart';

import '../../models/app_journey.dart';
import '../../models/app_platform.dart';
import '../../models/app_vehicle.dart';
import '../../services/journey_service.dart';
import '../../services/platform_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/ui/screen_action_controller.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;

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
    widget.actionController?.bindCreate(_openCreateDialog);
    _loadJourneys();
  }

  @override
  void dispose() {
    widget.actionController?.clear();
    super.dispose();
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
    await _openJourneyDialog();
  }

  Future<void> _openEditDialog(AppJourney journey) async {
    await _openJourneyDialog(initialJourney: journey);
  }

  Future<void> _openJourneyDialog({AppJourney? initialJourney}) async {
    final vehicles = await VehicleService().listVehicles();
    final platforms = await PlatformService().listPlatforms();
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _JourneyFormDialog(
        initialJourney: initialJourney,
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
              if (initialJourney == null) {
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
                return;
              }

              await _journeyService.updateJourney(
                id: initialJourney.id,
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

    if (saved == true) {
      await _loadJourneys();
    }
  }

  Future<void> _deleteJourney(AppJourney journey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir jornada'),
        content: Text(
          'Deseja excluir a jornada "${_formatJourneyTitle(journey)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _journeyService.deleteJourney(journey.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jornada removida com sucesso.')),
    );
    await _loadJourneys();
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
                if (widget.showCreateButton)
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
                  title: Row(
                    children: [
                      Expanded(child: Text(_formatJourneyTitle(journey))),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openEditDialog(journey);
                            return;
                          }
                          if (value == 'delete') {
                            await _deleteJourney(journey);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    this.initialJourney,
    required this.vehicles,
    required this.platforms,
    required this.onSubmit,
  });

  final AppJourney? initialJourney;
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
  late final TextEditingController _odometerStartController;
  late final TextEditingController _odometerEndController;
  late final TextEditingController _notesController;
  late final List<_PlatformIncomeEntry> _platformEntries;
  late String _mode;
  String? _vehicleId;
  late DateTime _startedAt;
  DateTime? _endedAt;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialJourney = widget.initialJourney;
    _odometerStartController = TextEditingController(
      text: initialJourney?.odometerStart?.toStringAsFixed(1) ?? '',
    );
    _odometerEndController = TextEditingController(
      text: initialJourney?.odometerEnd?.toStringAsFixed(1) ?? '',
    );
    _notesController = TextEditingController(
      text: initialJourney?.notes ?? '',
    );
    _platformEntries = initialJourney == null
        ? [_PlatformIncomeEntry()]
        : (initialJourney.platformBreakdown.isEmpty
              ? [_PlatformIncomeEntry()]
              : initialJourney.platformBreakdown
                    .map(
                      (item) => _PlatformIncomeEntry.fromValues(
                        platformId: item.platformId ?? '',
                        income: item.income == 0 ? '' : item.income.toStringAsFixed(2),
                        deliveries: item.deliveries == 0 ? '' : '${item.deliveries}',
                      ),
                    )
                    .toList());
    _mode = initialJourney?.mode ?? 'manual';
    _vehicleId = initialJourney?.vehicleId;
    _startedAt = initialJourney?.startedAt.toLocal() ?? DateTime.now();
    _endedAt = initialJourney?.endedAt?.toLocal();
  }

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
      title: Text(
        widget.initialJourney == null ? 'Nova jornada' : 'Editar jornada',
      ),
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
                  onClear: _endedAt == null
                      ? null
                      : () => setState(() => _endedAt = null),
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
  _PlatformIncomeEntry({
    this.platformId = '',
    String income = '',
    String deliveries = '',
  }) : incomeController = TextEditingController(text: income),
       deliveriesController = TextEditingController(text: deliveries);

  factory _PlatformIncomeEntry.fromValues({
    required String platformId,
    required String income,
    required String deliveries,
  }) {
    return _PlatformIncomeEntry(
      platformId: platformId,
      income: income,
      deliveries: deliveries,
    );
  }

  String platformId;
  final TextEditingController incomeController;
  final TextEditingController deliveriesController;

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
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final String? emptyLabel;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          const Icon(Icons.calendar_today_outlined),
        ],
      ),
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
