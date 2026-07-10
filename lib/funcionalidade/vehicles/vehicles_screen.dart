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
    await _openVehicleDialog();
  }

  Future<void> _openEditDialog(AppVehicle vehicle) async {
    await _openVehicleDialog(initialVehicle: vehicle);
  }

  Future<void> _openVehicleDialog({AppVehicle? initialVehicle}) async {
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activeVehicles = _vehicles.where((item) => item.active).length;
    final editingActiveVehicle = initialVehicle?.active == true ? 1 : 0;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultipleVehicles(profile.planType)
        : false;

    if (initialVehicle == null && activeVehicles >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O plano free permite apenas um veiculo ativo. Use presente, premium ou developer para expandir.',
          ),
        ),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _VehicleFormDialog(
        initialVehicle: initialVehicle,
        canEditActiveState: canUseMultiple || activeVehicles <= editingActiveVehicle,
        onSubmit:
            ({
              required brand,
              required model,
              required year,
              required plate,
              required fuelType,
              required averageConsumption,
              required active,
            }) async {
              if (active && !canUseMultiple) {
                final wouldHaveActive =
                    _vehicles.where((item) => item.active).length -
                    editingActiveVehicle +
                    1;
                if (wouldHaveActive > 1) {
                  throw StateError(
                    'O plano atual permite apenas um veiculo ativo.',
                  );
                }
              }

              if (initialVehicle == null) {
                await _vehicleService.createVehicle(
                  brand: brand,
                  model: model,
                  year: year,
                  plate: plate,
                  fuelType: fuelType,
                  averageConsumption: averageConsumption,
                );
                return;
              }

              await _vehicleService.updateVehicle(
                id: initialVehicle.id,
                brand: brand,
                model: model,
                year: year,
                plate: plate,
                fuelType: fuelType,
                averageConsumption: averageConsumption,
                active: active,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadVehicles();
    }
  }

  Future<void> _archiveVehicle(AppVehicle vehicle) async {
    await _vehicleService.archiveVehicle(vehicle.id);
    await _loadVehicles();
  }

  Future<void> _deleteVehicle(AppVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir veiculo'),
        content: Text(
          'Deseja excluir "${vehicle.brand} ${vehicle.model}"? Abastecimentos e manutencoes vinculados a este veiculo tambem serao removidos.',
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

    await _vehicleService.deleteVehicle(vehicle.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veiculo removido com sucesso.')),
    );
    await _loadVehicles();
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
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _openEditDialog(vehicle);
                        return;
                      }
                      if (value == 'archive') {
                        await _archiveVehicle(vehicle);
                        return;
                      }
                      if (value == 'delete') {
                        await _deleteVehicle(vehicle);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      if (vehicle.active)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Arquivar'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
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
  const _VehicleFormDialog({
    this.initialVehicle,
    required this.canEditActiveState,
    required this.onSubmit,
  });

  final AppVehicle? initialVehicle;
  final bool canEditActiveState;
  final Future<void> Function({
    required String brand,
    required String model,
    required String year,
    required String plate,
    required String fuelType,
    required String averageConsumption,
    required bool active,
  })
  onSubmit;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _fuelTypeController;
  late final TextEditingController _consumptionController;
  late bool _active;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialVehicle = widget.initialVehicle;
    _brandController = TextEditingController(text: initialVehicle?.brand ?? '');
    _modelController = TextEditingController(text: initialVehicle?.model ?? '');
    _yearController = TextEditingController(
      text: initialVehicle?.modelYear?.toString() ?? '',
    );
    _plateController = TextEditingController(text: initialVehicle?.plate ?? '');
    _fuelTypeController = TextEditingController(
      text: initialVehicle?.fuelType ?? '',
    );
    _consumptionController = TextEditingController(
      text: initialVehicle?.averageConsumption?.toStringAsFixed(2) ?? '',
    );
    _active = initialVehicle?.active ?? true;
  }

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
      title: Text(
        widget.initialVehicle == null ? 'Novo veiculo' : 'Editar veiculo',
      ),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Veiculo ativo'),
                subtitle: Text(
                  widget.canEditActiveState
                      ? 'Quando desligado, o veiculo fica arquivado.'
                      : 'O plano atual nao permite ativar mais veiculos.',
                ),
                value: _active,
                onChanged: (_saving || (!widget.canEditActiveState && !_active))
                    ? null
                    : (value) => setState(() => _active = value),
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
                      brand: _brandController.text,
                      model: _modelController.text,
                      year: _yearController.text,
                      plate: _plateController.text,
                      fuelType: _fuelTypeController.text,
                      averageConsumption: _consumptionController.text,
                      active: _active,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() => _submitError = error.toString());
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
}
