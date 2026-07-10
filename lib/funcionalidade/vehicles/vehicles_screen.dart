import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_vehicle.dart';
import '../../services/plan_access_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/state/app_session.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final VehicleService _vehicleService = VehicleService();
  final PlanAccessService _planAccessService = const PlanAccessService();
  bool _loading = true;
  List<AppVehicle> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    final vehicles = await _vehicleService.listVehicles();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _loading = false;
    });
  }

  Future<void> _openCreateDialog() async {
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activeVehicles = _vehicles.where((item) => item.active).length;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultipleVehicles(profile.planType)
        : false;

    if (activeVehicles >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O plano free permite apenas um veiculo ativo. Use presente, premium ou developer para expandir.',
          ),
        ),
      );
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _VehicleFormDialog(
        onSubmit:
            ({
              required brand,
              required model,
              required year,
              required plate,
              required fuelType,
              required averageConsumption,
            }) async {
              await _vehicleService.createVehicle(
                brand: brand,
                model: model,
                year: year,
                plate: plate,
                fuelType: fuelType,
                averageConsumption: averageConsumption,
              );
            },
      ),
    );

    if (created == true) {
      await _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final activeVehicles = _vehicles.where((item) => item.active).length;
    final canUseMultiple = session.profile == null
        ? false
        : _planAccessService.canUseMultipleVehicles(session.profile!.planType);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Veiculos',
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
            if (!canUseMultiple && activeVehicles >= 1)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Plano free: somente um veiculo ativo por conta. Assinatura, presente ou papel developer liberam multiplos veiculos.',
                  ),
                ),
              ),
            if (_vehicles.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhum veiculo cadastrado ainda. Adicione o primeiro para iniciar o controle.',
                  ),
                ),
              ),
            ..._vehicles.map(
              (vehicle) => Card(
                child: ListTile(
                  title: Text('${vehicle.brand} ${vehicle.model}'),
                  subtitle: Text(
                    [
                      if (vehicle.modelYear != null) 'Ano ${vehicle.modelYear}',
                      if (vehicle.fuelType != null) vehicle.fuelType,
                      if (vehicle.plate != null) vehicle.plate,
                      vehicle.active ? 'Ativo' : 'Arquivado',
                    ].join(' • '),
                  ),
                  trailing: vehicle.active
                      ? IconButton(
                          onPressed: () async {
                            await _vehicleService.archiveVehicle(vehicle.id);
                            await _loadVehicles();
                          },
                          icon: const Icon(Icons.archive_outlined),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  const _VehicleFormDialog({required this.onSubmit});

  final Future<void> Function({
    required String brand,
    required String model,
    required String year,
    required String plate,
    required String fuelType,
    required String averageConsumption,
  })
  onSubmit;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _consumptionController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _fuelTypeController.dispose();
    _consumptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo veiculo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: _required,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: _required,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
              TextFormField(
                controller: _fuelTypeController,
                decoration: const InputDecoration(labelText: 'Combustivel'),
              ),
              TextFormField(
                controller: _consumptionController,
                decoration: const InputDecoration(
                  labelText: 'Consumo medio (km/l)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
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
                  setState(() => _saving = true);
                  await widget.onSubmit(
                    brand: _brandController.text,
                    model: _modelController.text,
                    year: _yearController.text,
                    plate: _plateController.text,
                    fuelType: _fuelTypeController.text,
                    averageConsumption: _consumptionController.text,
                  );
                  if (!mounted) return;
                  navigator.pop(true);
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
}
