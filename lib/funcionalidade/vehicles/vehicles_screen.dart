import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_vehicle.dart';
import '../../services/plan_access_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/forms/driver_form_catalogs.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/screen_action_controller.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

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
    widget.actionController?.bindCreate(_openCreateDialog);
    _loadVehicles();
  }

  @override
  void dispose() {
    widget.actionController?.clear();
    super.dispose();
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
    final strings = AppStrings.of(context);
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activeVehicles = _vehicles.where((item) => item.active).length;
    final editingActiveVehicle = initialVehicle?.active == true ? 1 : 0;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultipleVehicles(profile.planType)
        : false;

    if (initialVehicle == null && activeVehicles >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'No plano free, voce usa um veiculo ativo por vez. O premium libera mais veiculos.',
              en: 'On the free plan, you can use one active vehicle at a time. Premium unlocks more vehicles.',
              es: 'En el plan gratis, usas un vehiculo activo por vez. Premium libera mas vehiculos.',
            ),
          ),
        ),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _VehicleFormDialog(
        initialVehicle: initialVehicle,
        canEditActiveState:
            canUseMultiple || activeVehicles <= editingActiveVehicle,
        onSubmit:
            ({
              required brand,
              required model,
              required type,
              required year,
              required plate,
              required fuelTypes,
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
                    strings.pick(
                      pt: 'Seu plano atual permite apenas um veiculo ativo.',
                      en: 'Your current plan allows only one active vehicle.',
                      es: 'Tu plan actual permite solo un vehiculo activo.',
                    ),
                  );
                }
              }

              if (initialVehicle == null) {
                await _vehicleService.createVehicle(
                  brand: brand,
                  model: model,
                  type: type,
                  year: year,
                  plate: plate,
                  fuelTypes: fuelTypes,
                  averageConsumption: averageConsumption,
                );
                return;
              }

              await _vehicleService.updateVehicle(
                id: initialVehicle.id,
                brand: brand,
                model: model,
                type: type,
                year: year,
                plate: plate,
                fuelTypes: fuelTypes,
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
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          strings.pick(
            pt: 'Excluir veiculo',
            en: 'Delete vehicle',
            es: 'Eliminar vehiculo',
          ),
        ),
        content: Text(
          strings.pick(
            pt: 'Quer excluir "${vehicle.brand} ${vehicle.model}"? Abastecimentos e manutencoes ligados a ele tambem saem.',
            en: 'Delete "${vehicle.brand} ${vehicle.model}"? Linked fuelings and maintenance records will also be removed.',
            es: 'Quieres eliminar "${vehicle.brand} ${vehicle.model}"? Tambien se quitaran cargas y mantenimientos vinculados.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.pick(pt: 'Excluir', en: 'Delete', es: 'Eliminar'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _vehicleService.deleteVehicle(vehicle.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.pick(
            pt: 'Veiculo removido.',
            en: 'Vehicle removed.',
            es: 'Vehiculo eliminado.',
          ),
        ),
      ),
    );
    await _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = context.watch<AppSession>();
    final activeVehicles = _vehicles.where((item) => item.active).length;
    final canUseMultiple = session.profile == null
        ? false
        : _planAccessService.canUseMultipleVehicles(session.profile!.planType);

    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return OmnyaSubPageScaffold(title: strings.vehicles, body: loading);
    }

    final content = RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.vehicles,
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
          if (!canUseMultiple && activeVehicles >= 1)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.pick(
                    pt: 'Plano free: um veiculo ativo por vez. Premium, presente ou developer liberam mais veiculos.',
                    en: 'Free plan: one active vehicle at a time. Premium, gift or developer access unlocks more vehicles.',
                    es: 'Plan gratis: un vehiculo activo por vez. Premium, regalo o developer liberan mas vehiculos.',
                  ),
                ),
              ),
            ),
          if (_vehicles.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhum veiculo cadastrado ainda. Adicione o primeiro para acompanhar sua rotina.',
                    en: 'No vehicles yet. Add the first one to follow your routine.',
                    es: 'Aun no hay vehiculos. Agrega el primero para seguir tu rutina.',
                  ),
                ),
              ),
            ),
          ..._vehicles.map(
            (vehicle) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(_vehicleIcon(vehicle))),
                title: Text(
                  '${strings.pick(pt: 'Veiculo', en: 'Vehicle', es: 'Vehiculo')} - ${vehicle.brand} ${vehicle.model}',
                ),
                subtitle: Text(
                  [
                    if (vehicle.modelYear != null)
                      '${strings.pick(pt: 'Ano', en: 'Year', es: 'Ano')} ${vehicle.modelYear}',
                    if (vehicle.type != null) vehicle.type,
                    if (vehicle.effectiveFuelTypes.isNotEmpty)
                      vehicle.effectiveFuelTypes.join(', '),
                    vehicle.active
                        ? strings.pick(pt: 'Ativo', en: 'Active', es: 'Activo')
                        : strings.pick(
                            pt: 'Arquivado',
                            en: 'Archived',
                            es: 'Archivado',
                          ),
                  ].join(' / '),
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
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        strings.pick(pt: 'Editar', en: 'Edit', es: 'Editar'),
                      ),
                    ),
                    if (vehicle.active)
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(
                          strings.pick(
                            pt: 'Arquivar',
                            en: 'Archive',
                            es: 'Archivar',
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
      title: strings.vehicles,
      heroTagPrefix: 'vehicles',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newVehicle,
          icon: Icons.add,
          onTap: _openCreateDialog,
        ),
      ],
      body: content,
    );
  }

  IconData _vehicleIcon(AppVehicle vehicle) {
    final label = '${vehicle.brand} ${vehicle.model}'.toLowerCase();
    final type = vehicle.type?.toLowerCase();
    if (type == 'bicicleta') return Icons.pedal_bike_outlined;
    if (type == 'patinete') return Icons.electric_scooter_outlined;
    if (type == 'van') return Icons.airport_shuttle_outlined;
    if (type == 'carro') return Icons.directions_car_outlined;
    if (type == 'moto') return Icons.two_wheeler_outlined;
    if (label.contains('van')) return Icons.airport_shuttle_outlined;
    if (label.contains('car') ||
        label.contains('auto') ||
        label.contains('civic') ||
        label.contains('gol') ||
        label.contains('uno')) {
      return Icons.directions_car_outlined;
    }
    return Icons.two_wheeler_outlined;
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
    required String type,
    required String year,
    required String plate,
    required List<String> fuelTypes,
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
  late final TextEditingController _consumptionController;
  late String _vehicleType;
  late List<String> _fuelTypes;
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
    _consumptionController = TextEditingController(
      text: initialVehicle?.averageConsumption?.toStringAsFixed(2) ?? '',
    );
    _vehicleType = initialVehicle?.type ?? vehicleTypes.first;
    _fuelTypes = initialVehicle?.effectiveFuelTypes.toList() ?? const [];
    _active = initialVehicle?.active ?? true;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
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
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: vehicleTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  final nextType = value ?? vehicleTypes.first;
                  final brands = vehicleBrandsForType(nextType);
                  setState(() {
                    _vehicleType = nextType;
                    if (!brands.any(
                      (brand) =>
                          brand.toLowerCase() ==
                          _brandController.text.trim().toLowerCase(),
                    )) {
                      _brandController.clear();
                      _modelController.clear();
                    }
                  });
                },
              ),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _brandController.text),
                optionsBuilder: (value) {
                  final brands = vehicleBrandsForType(_vehicleType);
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return brands;
                  return brands.where(
                    (brand) => brand.toLowerCase().contains(query),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != _brandController.text) {
                        controller.text = _brandController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Marca'),
                        onChanged: (value) {
                          _brandController.text = value;
                          setState(() => _modelController.clear());
                        },
                        validator: _required,
                      );
                    },
                onSelected: (value) {
                  _brandController.text = value;
                  setState(() => _modelController.clear());
                },
              ),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _modelController.text),
                optionsBuilder: (value) {
                  final models = vehicleModelsFor(
                    type: _vehicleType,
                    brand: _brandController.text.trim(),
                  );
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return models;
                  return models.where(
                    (model) => model.toLowerCase().contains(query),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != _modelController.text) {
                        controller.text = _modelController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                        onChanged: (value) => _modelController.text = value,
                        validator: _required,
                      );
                    },
                onSelected: (value) => _modelController.text = value,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    'Combustivel',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fuelOptions
                    .map(
                      (fuel) => FilterChip(
                        label: Text(fuel),
                        selected: _fuelTypes.contains(fuel),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _fuelTypes = {..._fuelTypes, fuel}.toList();
                            } else {
                              _fuelTypes = _fuelTypes
                                  .where((item) => item != fuel)
                                  .toList();
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
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
                      type: _vehicleType,
                      year: _yearController.text,
                      plate: _plateController.text,
                      fuelTypes: _fuelTypes,
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
