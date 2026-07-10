import 'package:flutter/material.dart';

import '../../models/app_fueling.dart';
import '../../models/app_vehicle.dart';
import '../../services/fueling_service.dart';
import '../../services/journey_service.dart';
import '../../services/vehicle_service.dart';

class FuelingsScreen extends StatefulWidget {
  const FuelingsScreen({super.key});

  @override
  State<FuelingsScreen> createState() => _FuelingsScreenState();
}

class _FuelingsScreenState extends State<FuelingsScreen> {
  final FuelingService _fuelingService = FuelingService();
  bool _loading = true;
  List<AppFueling> _fuelings = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFuelings();
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
    final vehicles = await VehicleService().listVehicles();
    final journeys = await JourneyService().listJourneyOptions();
    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _FuelingFormDialog(
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
            },
      ),
    );

    if (created == true) {
      await _loadFuelings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFuelings,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Abastecimentos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_fuelings.isNotEmpty)
              Card(
                child: ListTile(
                  title: const Text('Resumo'),
                  subtitle: Text(
                    '${_fuelings.length} abastecimentos registrados',
                  ),
                  trailing: Text(
                    'R\$ ${_totalAmount.toStringAsFixed(2)}',
                  ),
                ),
              ),
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
            if (_fuelings.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhum abastecimento registrado ainda. Cadastre litros, valor por litro e veiculo para iniciar o historico.',
                  ),
                ),
              ),
            ..._fuelings.map(
              (fueling) => Card(
                child: ListTile(
                  title: Text(fueling.vehicleLabel ?? 'Veiculo'),
                  subtitle: Text(
                    [
                      _formatDate(fueling.fueledAt),
                      if (fueling.stationName != null) fueling.stationName!,
                      '${fueling.liters.toStringAsFixed(2)} L',
                      'R\$ ${fueling.pricePerLiter.toStringAsFixed(3)}/L',
                    ].join(' - '),
                  ),
                  trailing: Text(
                    'R\$ ${fueling.totalAmount.toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double get _totalAmount => _fuelings.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );
}

class _FuelingFormDialog extends StatefulWidget {
  const _FuelingFormDialog({
    required this.vehicles,
    required this.journeys,
    required this.onSubmit,
  });

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
  final _odometerController = TextEditingController();
  final _stationController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalController = TextEditingController();
  String? _vehicleId;
  String? _journeyId;
  DateTime _fueledAt = DateTime.now();
  bool _saving = false;
  String? _submitError;

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
      title: const Text('Novo abastecimento'),
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
                        'Calculo atual: R\$ ${calculatedTotal.toStringAsFixed(2)}',
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
