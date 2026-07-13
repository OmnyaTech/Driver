import 'package:flutter/material.dart';

import '../../models/app_fueling.dart';
import '../../models/app_vehicle.dart';
import '../finance/widgets/financial_filter_toolbar.dart';
import '../../services/fueling_service.dart';
import '../../services/journey_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/screen_action_controller.dart';

class FuelingsScreen extends StatefulWidget {
  const FuelingsScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<FuelingsScreen> createState() => _FuelingsScreenState();
}

class _FuelingsScreenState extends State<FuelingsScreen> {
  final FuelingService _fuelingService = FuelingService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppFueling> _fuelings = const [];
  String? _errorMessage;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    _range = _currentMonthRange();
    widget.actionController?.bindCreate(_openCreateDialog);
    _searchController.addListener(_handleFilterChange);
    _loadFuelings();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleFilterChange)
      ..dispose();
    widget.actionController?.clear();
    super.dispose();
  }

  void _handleFilterChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFuelings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final fuelings = await _fuelingService.listFuelings();
      if (!mounted) return;
      setState(() => _fuelings = fuelings);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar os abastecimentos agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateDialog() async {
    await _openFuelingDialog();
  }

  Future<void> _openEditDialog(AppFueling fueling) async {
    await _openFuelingDialog(initialFueling: fueling);
  }

  Future<void> _openFuelingDialog({AppFueling? initialFueling}) async {
    final vehicles = await VehicleService().listVehicles();
    final journeys = await JourneyService().listJourneyOptions();
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _FuelingFormDialog(
        initialFueling: initialFueling,
        vehicles: vehicles.where((item) => item.active).toList(),
        journeys: journeys,
        onSubmit:
            ({
              required vehicleId,
              required fueledAt,
              required liters,
              required pricePerLiter,
              required totalAmount,
              required odometer,
              required journeyId,
              required stationName,
              required fuelType,
            }) async {
              if (initialFueling == null) {
                await _fuelingService.createFueling(
                  vehicleId: vehicleId,
                  fueledAt: fueledAt,
                  liters: liters,
                  pricePerLiter: pricePerLiter,
                  totalAmount: totalAmount,
                  odometer: odometer,
                  journeyId: journeyId,
                  stationName: stationName,
                  fuelType: fuelType,
                );
                return;
              }

              await _fuelingService.updateFueling(
                id: initialFueling.id,
                vehicleId: vehicleId,
                fueledAt: fueledAt,
                liters: liters,
                pricePerLiter: pricePerLiter,
                totalAmount: totalAmount,
                odometer: odometer,
                journeyId: journeyId,
                stationName: stationName,
                fuelType: fuelType,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadFuelings();
    }
  }

  Future<void> _deleteFueling(AppFueling fueling) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir abastecimento'),
        content: Text(
          'Deseja excluir este abastecimento de ${AppFormat.of(context).currency(fueling.totalAmount)}?',
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

    await _fuelingService.deleteFueling(fueling.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abastecimento removido com sucesso.')),
    );
    await _loadFuelings();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final format = AppFormat.of(context);
    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return OmnyaSubPageScaffold(
        title: strings.pick(pt: 'Abastecimentos', en: 'Fuelings', es: 'Cargas'),
        body: loading,
      );
    }

    final content = RefreshIndicator(
      onRefresh: _loadFuelings,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.pick(
                      pt: 'Abastecimentos',
                      en: 'Fuelings',
                      es: 'Cargas',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.showCreateButton)
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: Text(strings.newItem),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          FinancialFilterToolbar(
            searchController: _searchController,
            range: _range,
            hintText: strings.pick(
              pt: 'Buscar veiculo, posto ou combustivel',
              en: 'Search vehicle, station or fuel',
              es: 'Buscar vehiculo, estacion o combustible',
            ),
            onPickRange: _pickRange,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          if (_filteredFuelings.isNotEmpty)
            Card(
              child: ListTile(
                title: Text(
                  strings.pick(pt: 'Resumo', en: 'Summary', es: 'Resumen'),
                ),
                subtitle: Text(
                  strings.pick(
                    pt: '${_filteredFuelings.length} abastecimentos no filtro atual',
                    en: '${_filteredFuelings.length} fuelings in the current filter',
                    es: '${_filteredFuelings.length} cargas en el filtro actual',
                  ),
                ),
                trailing: Text(format.currency(_totalAmount)),
              ),
            ),
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
          if (_fuelings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhum abastecimento ainda. Cadastre litros, valor e veiculo para acompanhar seus custos.',
                    en: 'No fuelings yet. Add liters, amount and vehicle to track your costs.',
                    es: 'Aun no hay cargas. Agrega litros, valor y vehiculo para seguir tus costos.',
                  ),
                ),
              ),
            ),
          if (_fuelings.isNotEmpty && _filteredFuelings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhum abastecimento encontrado para os filtros informados.',
                    en: 'No fuelings found for these filters.',
                    es: 'No se encontraron cargas para estos filtros.',
                  ),
                ),
              ),
            ),
          ..._filteredFuelings.map(
            (fueling) => Card(
              child: ListTile(
                title: Text(
                  fueling.vehicleLabel ??
                      strings.pick(
                        pt: 'Veiculo',
                        en: 'Vehicle',
                        es: 'Vehiculo',
                      ),
                ),
                subtitle: Text(
                  [
                    _formatDate(fueling.fueledAt),
                    if (fueling.stationName != null) fueling.stationName!,
                    '${fueling.liters.toStringAsFixed(2)} L',
                    '${format.currency(fueling.pricePerLiter)}/L',
                  ].join(' - '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(format.currency(fueling.totalAmount)),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditDialog(fueling);
                          return;
                        }
                        if (value == 'delete') {
                          await _deleteFueling(fueling);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            strings.pick(
                              pt: 'Editar',
                              en: 'Edit',
                              es: 'Editar',
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            strings.pick(
                              pt: 'Excluir',
                              en: 'Delete',
                              es: 'Eliminar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return OmnyaSubPageScaffold(
      title: strings.pick(pt: 'Abastecimentos', en: 'Fuelings', es: 'Cargas'),
      heroTagPrefix: 'fuelings',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newFueling,
          icon: Icons.add,
          onTap: _openCreateDialog,
        ),
      ],
      body: content,
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double get _totalAmount =>
      _filteredFuelings.fold<double>(0, (sum, item) => sum + item.totalAmount);

  List<AppFueling> get _filteredFuelings {
    final query = _searchController.text.trim().toLowerCase();
    return _fuelings.where((fueling) {
      if (!_isWithinRange(fueling.fueledAt)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        fueling.vehicleLabel,
        fueling.stationName,
        fueling.fuelType,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  bool _isWithinRange(DateTime value) {
    final local = value.toLocal();
    final start = DateTime(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
    final end = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day,
      23,
      59,
      59,
    );
    return !local.isBefore(start) && !local.isAfter(end);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _range = _currentMonthRange();
    });
  }

  DateTimeRange _currentMonthRange() {
    final now = DateTime.now();
    return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }
}

class _FuelingFormDialog extends StatefulWidget {
  const _FuelingFormDialog({
    this.initialFueling,
    required this.vehicles,
    required this.journeys,
    required this.onSubmit,
  });

  final AppFueling? initialFueling;
  final List<AppVehicle> vehicles;
  final List<JourneyOption> journeys;
  final Future<void> Function({
    required String vehicleId,
    required DateTime fueledAt,
    required String liters,
    required String pricePerLiter,
    required String totalAmount,
    required String odometer,
    required String? journeyId,
    required String stationName,
    required String fuelType,
  })
  onSubmit;

  @override
  State<_FuelingFormDialog> createState() => _FuelingFormDialogState();
}

class _FuelingFormDialogState extends State<_FuelingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometerController;
  late final TextEditingController _stationController;
  late final TextEditingController _fuelTypeController;
  late final TextEditingController _litersController;
  late final TextEditingController _priceController;
  late final TextEditingController _totalController;
  String? _vehicleId;
  String? _journeyId;
  late DateTime _fueledAt;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialFueling = widget.initialFueling;
    _odometerController = TextEditingController(
      text: initialFueling?.odometer?.toStringAsFixed(1) ?? '',
    );
    _stationController = TextEditingController(
      text: initialFueling?.stationName ?? '',
    );
    _fuelTypeController = TextEditingController(
      text: initialFueling?.fuelType ?? '',
    );
    _litersController = TextEditingController(
      text: initialFueling == null
          ? ''
          : initialFueling.liters.toStringAsFixed(2),
    );
    _priceController = TextEditingController(
      text: initialFueling == null
          ? ''
          : initialFueling.pricePerLiter.toStringAsFixed(3),
    );
    _totalController = TextEditingController(
      text: initialFueling == null
          ? ''
          : initialFueling.totalAmount.toStringAsFixed(2),
    );
    _vehicleId = initialFueling?.vehicleId;
    _journeyId = initialFueling?.journeyId;
    _fueledAt = initialFueling?.fueledAt.toLocal() ?? DateTime.now();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _stationController.dispose();
    _fuelTypeController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatedTotal = _calculateTotal();

    return AlertDialog(
      title: Text(
        widget.initialFueling == null
            ? 'Novo abastecimento'
            : 'Editar abastecimento',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _vehicleId,
                  decoration: const InputDecoration(labelText: 'Veiculo'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Selecione o veiculo.'
                      : null,
                  items: widget.vehicles
                      .map(
                        (vehicle) => DropdownMenuItem(
                          value: vehicle.id,
                          child: Text('${vehicle.brand} ${vehicle.model}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _vehicleId = value),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _journeyId,
                  decoration: const InputDecoration(labelText: 'Jornada'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem vincular'),
                    ),
                    ...widget.journeys.map(
                      (journey) => DropdownMenuItem<String?>(
                        value: journey.id,
                        child: Text(journey.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _journeyId = value),
                ),
                TextFormField(
                  controller: _odometerController,
                  decoration: const InputDecoration(labelText: 'Km atual'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: _stationController,
                  decoration: const InputDecoration(labelText: 'Posto'),
                ),
                TextFormField(
                  controller: _fuelTypeController,
                  decoration: const InputDecoration(labelText: 'Combustivel'),
                ),
                TextFormField(
                  controller: _litersController,
                  decoration: const InputDecoration(labelText: 'Litros'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Valor por litro',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _totalController,
                  decoration: const InputDecoration(labelText: 'Valor total'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                if (calculatedTotal != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Calculo atual: ${AppFormat.of(context).currency(calculatedTotal)}',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _FuelingDateTile(
                  value: _fueledAt,
                  onChanged: (value) => setState(() => _fueledAt = value),
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
                  final navigator = Navigator.of(context);
                  setState(() {
                    _saving = true;
                    _submitError = null;
                  });
                  try {
                    await widget.onSubmit(
                      vehicleId: _vehicleId!,
                      fueledAt: _fueledAt,
                      liters: _litersController.text,
                      pricePerLiter: _priceController.text,
                      totalAmount: _totalController.text,
                      odometer: _odometerController.text,
                      journeyId: _journeyId,
                      stationName: _stationController.text,
                      fuelType: _fuelTypeController.text,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _submitError =
                          'Nao foi possivel salvar o abastecimento agora. ${error.toString()}';
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
  }

  double? _calculateTotal() {
    final liters = double.tryParse(
      _litersController.text.trim().replaceAll(',', '.'),
    );
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    if (liters == null || price == null) return null;
    return liters * price;
  }
}

class _FuelingDateTile extends StatelessWidget {
  const _FuelingDateTile({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Data e hora'),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
    );
  }
}
