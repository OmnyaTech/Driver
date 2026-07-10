import 'package:flutter/material.dart';

import '../../models/app_maintenance.dart';
import '../../models/app_vehicle.dart';
import '../../services/maintenance_service.dart';
import '../../services/vehicle_service.dart';

class MaintenancesScreen extends StatefulWidget {
  const MaintenancesScreen({super.key});

  @override
  State<MaintenancesScreen> createState() => _MaintenancesScreenState();
}

class _MaintenancesScreenState extends State<MaintenancesScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  bool _loading = true;
  List<AppMaintenance> _maintenances = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
  }

  Future<void> _loadMaintenances() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final maintenances = await _maintenanceService.listMaintenances();
      if (!mounted) return;
      setState(() => _maintenances = maintenances);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar as manutencoes agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final vehicles = await VehicleService().listVehicles();
    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _MaintenanceFormDialog(
        vehicles: vehicles.where((item) => item.active).toList(),
        onSubmit:
            ({
              required vehicleId,
              required maintenanceDate,
              required totalAmount,
              required workshop,
              required reason,
              required description,
              required items,
            }) async {
              await _maintenanceService.createMaintenance(
                vehicleId: vehicleId,
                maintenanceDate: maintenanceDate,
                totalAmount: totalAmount,
                workshop: workshop,
                reason: reason,
                description: description,
                items: items,
              );
            },
      ),
    );

    if (created == true) {
      await _loadMaintenances();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMaintenances,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Manutencoes',
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
            if (_maintenances.isNotEmpty)
              Card(
                child: ListTile(
                  title: const Text('Resumo'),
                  subtitle: Text(
                    '${_maintenances.length} manutencoes registradas',
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
            if (_maintenances.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma manutencao registrada ainda. Cadastre oficina, motivo e valor para construir o historico do veiculo.',
                  ),
                ),
              ),
            ..._maintenances.map(
              (maintenance) => Card(
                child: ExpansionTile(
                  title: Text(maintenance.vehicleLabel ?? 'Veiculo'),
                  subtitle: Text(
                    [
                      _formatDate(maintenance.maintenanceDate),
                      if (maintenance.workshop != null) maintenance.workshop!,
                      if (maintenance.reason != null) maintenance.reason!,
                    ].join(' - '),
                  ),
                  trailing: Text(
                    'R\$ ${maintenance.totalAmount.toStringAsFixed(2)}',
                  ),
                  children: [
                    if (maintenance.description != null &&
                        maintenance.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(maintenance.description!),
                        ),
                      ),
                    ...maintenance.items.map(
                      (item) => ListTile(
                        title: Text(item.description),
                        trailing: Text('R\$ ${item.amount.toStringAsFixed(2)}'),
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

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double get _totalAmount => _maintenances.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );
}

class _MaintenanceFormDialog extends StatefulWidget {
  const _MaintenanceFormDialog({
    required this.vehicles,
    required this.onSubmit,
  });

  final List<AppVehicle> vehicles;
  final Future<void> Function({
    required String vehicleId,
    required DateTime maintenanceDate,
    required String totalAmount,
    required String workshop,
    required String reason,
    required String description,
    required List<MaintenanceItemDraft> items,
  })
  onSubmit;

  @override
  State<_MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<_MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _workshopController = TextEditingController();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalController = TextEditingController();
  final List<_MaintenanceItemEntry> _items = [_MaintenanceItemEntry()];
  String? _vehicleId;
  DateTime _maintenanceDate = DateTime.now();
  bool _saving = false;
  String? _submitError;

  @override
  void dispose() {
    _workshopController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsTotal = _items.fold<double>(0, (sum, item) {
      final amount = double.tryParse(
        item.amountController.text.trim().replaceAll(',', '.'),
      );
      return sum + (amount ?? 0);
    });

    return AlertDialog(
      title: const Text('Nova manutencao'),
      content: SizedBox(
        width: 520,
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
                TextFormField(
                  controller: _workshopController,
                  decoration: const InputDecoration(labelText: 'Oficina'),
                ),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _totalController,
                  decoration: const InputDecoration(labelText: 'Valor total'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                if (itemsTotal > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Soma dos itens: R\$ ${itemsTotal.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _MaintenanceDateTile(
                  value: _maintenanceDate,
                  onChanged: (value) =>
                      setState(() => _maintenanceDate = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Itens opcionais',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _items.add(_MaintenanceItemEntry())),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                ..._items.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value.descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descricao',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: entry.value.amountController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () {
                              final removed = _items.removeAt(entry.key);
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
                  final navigator = Navigator.of(context);
                  setState(() {
                    _saving = true;
                    _submitError = null;
                  });
                  try {
                    await widget.onSubmit(
                      vehicleId: _vehicleId!,
                      maintenanceDate: _maintenanceDate,
                      totalAmount: _totalController.text,
                      workshop: _workshopController.text,
                      reason: _reasonController.text,
                      description: _descriptionController.text,
                      items: _items
                          .map(
                            (item) => MaintenanceItemDraft(
                              description: item.descriptionController.text,
                              amount: item.amountController.text,
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
                          'Nao foi possivel salvar a manutencao agora. ${error.toString()}';
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
}

class _MaintenanceItemEntry {
  _MaintenanceItemEntry();

  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }
}

class _MaintenanceDateTile extends StatelessWidget {
  const _MaintenanceDateTile({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Data'),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
        );
        if (date == null) return;
        onChanged(DateTime(date.year, date.month, date.day));
      },
    );
  }
}
