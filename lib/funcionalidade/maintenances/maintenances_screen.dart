import 'package:flutter/material.dart';

import '../../models/app_maintenance.dart';
import '../../models/app_vehicle.dart';
import '../finance/widgets/financial_filter_toolbar.dart';
import '../../services/maintenance_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/screen_action_controller.dart';

class MaintenancesScreen extends StatefulWidget {
  const MaintenancesScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<MaintenancesScreen> createState() => _MaintenancesScreenState();
}

class _MaintenancesScreenState extends State<MaintenancesScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppMaintenance> _maintenances = const [];
  String? _errorMessage;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    _range = _currentMonthRange();
    widget.actionController?.bindCreate(_openCreateDialog);
    _searchController.addListener(_handleFilterChange);
    _loadMaintenances();
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
    await _openMaintenanceDialog();
  }

  Future<void> _openEditDialog(AppMaintenance maintenance) async {
    await _openMaintenanceDialog(initialMaintenance: maintenance);
  }

  Future<void> _openMaintenanceDialog({
    AppMaintenance? initialMaintenance,
  }) async {
    final vehicles = await VehicleService().listVehicles();
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MaintenanceFormDialog(
        initialMaintenance: initialMaintenance,
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
              if (initialMaintenance == null) {
                await _maintenanceService.createMaintenance(
                  vehicleId: vehicleId,
                  maintenanceDate: maintenanceDate,
                  totalAmount: totalAmount,
                  workshop: workshop,
                  reason: reason,
                  description: description,
                  items: items,
                );
                return;
              }

              await _maintenanceService.updateMaintenance(
                id: initialMaintenance.id,
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

    if (saved == true) {
      await _loadMaintenances();
    }
  }

  Future<void> _deleteMaintenance(AppMaintenance maintenance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir manutencao'),
        content: Text(
          'Deseja excluir esta manutencao de ${AppFormat.of(context).currency(maintenance.totalAmount)}?',
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

    await _maintenanceService.deleteMaintenance(maintenance.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manutencao removida com sucesso.')),
    );
    await _loadMaintenances();
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
        title: strings.pick(
          pt: 'Manutencoes',
          en: 'Maintenance',
          es: 'Mantenimientos',
        ),
        body: loading,
      );
    }

    final content = RefreshIndicator(
      onRefresh: _loadMaintenances,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.pick(
                      pt: 'Manutencoes',
                      en: 'Maintenance',
                      es: 'Mantenimientos',
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
              pt: 'Buscar veiculo, oficina, motivo ou item',
              en: 'Search vehicle, shop, reason or item',
              es: 'Buscar vehiculo, taller, motivo o item',
            ),
            onPickRange: _pickRange,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          if (_filteredMaintenances.isNotEmpty)
            Card(
              child: ListTile(
                title: Text(
                  strings.pick(pt: 'Resumo', en: 'Summary', es: 'Resumen'),
                ),
                subtitle: Text(
                  strings.pick(
                    pt: '${_filteredMaintenances.length} manutencoes no filtro atual',
                    en: '${_filteredMaintenances.length} maintenance records in the current filter',
                    es: '${_filteredMaintenances.length} mantenimientos en el filtro actual',
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
          if (_maintenances.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhuma manutencao ainda. Cadastre oficina, motivo e valor para cuidar melhor do veiculo.',
                    en: 'No maintenance yet. Add shop, reason and amount to take better care of your vehicle.',
                    es: 'Aun no hay mantenimiento. Agrega taller, motivo y valor para cuidar mejor el vehiculo.',
                  ),
                ),
              ),
            ),
          if (_maintenances.isNotEmpty && _filteredMaintenances.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhuma manutencao encontrada para os filtros informados.',
                    en: 'No maintenance found for these filters.',
                    es: 'No se encontro mantenimiento para estos filtros.',
                  ),
                ),
              ),
            ),
          ..._filteredMaintenances.map(
            (maintenance) => Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        maintenance.vehicleLabel ??
                            strings.pick(
                              pt: 'Veiculo',
                              en: 'Vehicle',
                              es: 'Vehiculo',
                            ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditDialog(maintenance);
                          return;
                        }
                        if (value == 'delete') {
                          await _deleteMaintenance(maintenance);
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
                subtitle: Text(
                  [
                    _formatDate(maintenance.maintenanceDate),
                    if (maintenance.workshop != null) maintenance.workshop!,
                    if (maintenance.reason != null) maintenance.reason!,
                    format.currency(maintenance.totalAmount),
                  ].join(' - '),
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
                      trailing: Text(format.currency(item.amount)),
                    ),
                  ),
                ],
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
      title: strings.pick(
        pt: 'Manutencoes',
        en: 'Maintenance',
        es: 'Mantenimientos',
      ),
      heroTagPrefix: 'maintenances',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newMaintenance,
          icon: Icons.add,
          onTap: _openCreateDialog,
        ),
      ],
      body: content,
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double get _totalAmount => _filteredMaintenances.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );

  List<AppMaintenance> get _filteredMaintenances {
    final query = _searchController.text.trim().toLowerCase();
    return _maintenances.where((maintenance) {
      if (!_isWithinRange(maintenance.maintenanceDate)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        maintenance.vehicleLabel,
        maintenance.workshop,
        maintenance.reason,
        maintenance.description,
        ...maintenance.items.map((item) => item.description),
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

class _MaintenanceFormDialog extends StatefulWidget {
  const _MaintenanceFormDialog({
    this.initialMaintenance,
    required this.vehicles,
    required this.onSubmit,
  });

  final AppMaintenance? initialMaintenance;
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
  late final TextEditingController _workshopController;
  late final TextEditingController _reasonController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalController;
  late final List<_MaintenanceItemEntry> _items;
  String? _vehicleId;
  late DateTime _maintenanceDate;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialMaintenance = widget.initialMaintenance;
    _workshopController = TextEditingController(
      text: initialMaintenance?.workshop ?? '',
    );
    _reasonController = TextEditingController(
      text: initialMaintenance?.reason ?? '',
    );
    _descriptionController = TextEditingController(
      text: initialMaintenance?.description ?? '',
    );
    _totalController = TextEditingController(
      text: initialMaintenance == null
          ? ''
          : initialMaintenance.totalAmount.toStringAsFixed(2),
    );
    _items = initialMaintenance == null
        ? [_MaintenanceItemEntry()]
        : (initialMaintenance.items.isEmpty
              ? [_MaintenanceItemEntry()]
              : initialMaintenance.items
                    .map(
                      (item) => _MaintenanceItemEntry.fromValues(
                        description: item.description,
                        amount: item.amount == 0
                            ? ''
                            : item.amount.toStringAsFixed(2),
                      ),
                    )
                    .toList());
    _vehicleId = initialMaintenance?.vehicleId;
    _maintenanceDate =
        initialMaintenance?.maintenanceDate.toLocal() ?? DateTime.now();
  }

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
      title: Text(
        widget.initialMaintenance == null
            ? 'Nova manutencao'
            : 'Editar manutencao',
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
                        'Soma dos itens: ${AppFormat.of(context).currency(itemsTotal)}',
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
  _MaintenanceItemEntry({String description = '', String amount = ''})
    : descriptionController = TextEditingController(text: description),
      amountController = TextEditingController(text: amount);

  factory _MaintenanceItemEntry.fromValues({
    required String description,
    required String amount,
  }) {
    return _MaintenanceItemEntry(description: description, amount: amount);
  }

  final TextEditingController descriptionController;
  final TextEditingController amountController;

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
