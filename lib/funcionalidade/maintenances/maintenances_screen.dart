import 'package:flutter/material.dart';

import '../../models/app_maintenance.dart';
import '../../models/app_vehicle.dart';
import '../finance/widgets/financial_filter_toolbar.dart';
import '../finance/widgets/vehicle_filter_pill.dart';
import '../../services/maintenance_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/omnya_visuals.dart';
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
  final VehicleService _vehicleService = VehicleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppMaintenance> _maintenances = const [];
  List<AppVehicle> _vehicles = const [];
  String? _vehicleFilterId;
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
      final vehicles = await _vehicleService.listVehicles();
      if (!mounted) return;
      setState(() {
        _maintenances = maintenances;
        _vehicles = vehicles;
        if (_vehicleFilterId != null &&
            !_vehicles.any((vehicle) => vehicle.id == _vehicleFilterId)) {
          _vehicleFilterId = null;
        }
      });
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
              required paymentMethod,
              required currentOdometer,
              required nextMaintenanceOdometer,
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
                  paymentMethod: paymentMethod,
                  currentOdometer: currentOdometer,
                  nextMaintenanceOdometer: nextMaintenanceOdometer,
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
                paymentMethod: paymentMethod,
                currentOdometer: currentOdometer,
                nextMaintenanceOdometer: nextMaintenanceOdometer,
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
          if (_vehicles.isNotEmpty) ...[
            const SizedBox(height: 10),
            VehicleFilterPill(
              label: _selectedVehicleFilterLabel(context),
              active: _vehicleFilterId != null,
              onTap: _pickVehicleFilter,
              onClear: _vehicleFilterId == null
                  ? null
                  : () => setState(() => _vehicleFilterId = null),
            ),
          ],
          const SizedBox(height: 16),
          if (_filteredMaintenances.isNotEmpty)
            OmnyaGlassCard(
              highlight: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: OmnyaVisualTokens.neonBlue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.build_circle_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pick(
                            pt: 'Resumo do periodo',
                            en: 'Period summary',
                            es: 'Resumen del periodo',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.pick(
                            pt: '${_filteredMaintenances.length} manutencoes encontradas',
                            en: '${_filteredMaintenances.length} maintenance records found',
                            es: '${_filteredMaintenances.length} mantenimientos encontrados',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    format.currency(_totalAmount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          if (_filteredMaintenances.isNotEmpty) const SizedBox(height: 12),
          if (_errorMessage != null)
            OmnyaGlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_maintenances.isEmpty)
            OmnyaEmptyState(
              icon: Icons.build_circle_rounded,
              title: strings.pick(
                pt: 'Nenhuma manutencao ainda',
                en: 'No maintenance yet',
                es: 'Aun no hay mantenimiento',
              ),
              message: strings.pick(
                pt: 'Cadastre oficina, motivo, valor e itens para cuidar melhor do veiculo.',
                en: 'Add shop, reason, amount and items to take better care of your vehicle.',
                es: 'Agrega taller, motivo, valor e items para cuidar mejor el vehiculo.',
              ),
            ),
          if (_maintenances.isNotEmpty && _filteredMaintenances.isEmpty)
            OmnyaEmptyState(
              icon: Icons.search_off_rounded,
              title: strings.pick(
                pt: 'Nada nesse filtro',
                en: 'Nothing in this filter',
                es: 'Nada en este filtro',
              ),
              message: strings.pick(
                pt: 'Ajuste a busca ou o periodo para encontrar manutencoes antigas.',
                en: 'Adjust search or period to find older maintenance records.',
                es: 'Ajusta la busqueda o el periodo para encontrar mantenimientos antiguos.',
              ),
            ),
          ..._groupedMaintenances.map(
            (monthGroup) => _MaintenanceMonthSection(
              title: monthGroup.label,
              days: monthGroup.days,
              format: format,
              strings: strings,
              onEdit: _openEditDialog,
              onDelete: _deleteMaintenance,
              formatTime: _formatTime,
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

  String _formatTime(DateTime value) {
    final date = value.toLocal();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double get _totalAmount => _filteredMaintenances.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );

  List<AppMaintenance> get _filteredMaintenances {
    final query = _searchController.text.trim().toLowerCase();
    final items = _maintenances.where((maintenance) {
      if (!_isWithinRange(maintenance.maintenanceDate)) return false;
      if (_vehicleFilterId != null &&
          maintenance.vehicleId != _vehicleFilterId) {
        return false;
      }
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

    items.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
    return items;
  }

  List<_MaintenanceMonthGroup> get _groupedMaintenances {
    final monthGroups = <_MaintenanceMonthGroup>[];

    for (final maintenance in _filteredMaintenances) {
      final local = maintenance.maintenanceDate.toLocal();
      final monthLabel = _formatMonth(local);
      final dayKey = DateTime(local.year, local.month, local.day);
      final dayLabel =
          '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';

      _MaintenanceMonthGroup? monthGroup;
      for (final group in monthGroups) {
        if (group.label == monthLabel) {
          monthGroup = group;
          break;
        }
      }
      if (monthGroup == null) {
        monthGroup = _MaintenanceMonthGroup(label: monthLabel, days: []);
        monthGroups.add(monthGroup);
      }

      _MaintenanceDayGroup? dayGroup;
      for (final group in monthGroup.days) {
        if (group.dayKey == dayKey) {
          dayGroup = group;
          break;
        }
      }
      if (dayGroup == null) {
        dayGroup = _MaintenanceDayGroup(
          dayKey: dayKey,
          label: dayLabel,
          maintenances: [],
        );
        monthGroup.days.add(dayGroup);
      }

      dayGroup.maintenances.add(maintenance);
    }

    return monthGroups;
  }

  String _formatMonth(DateTime value) {
    const monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${monthNames[value.month - 1]}/${value.year}';
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

  Future<void> _pickVehicleFilter() async {
    final strings = AppStrings.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            ListTile(
              leading: const Icon(Icons.filter_alt_off_rounded),
              title: Text(
                strings.pick(
                  pt: 'Todos os veiculos',
                  en: 'All vehicles',
                  es: 'Todos los vehiculos',
                ),
              ),
              onTap: () => Navigator.of(context).pop(null),
            ),
            for (final vehicle in _vehicles)
              ListTile(
                leading: Icon(
                  vehicle.active
                      ? Icons.two_wheeler_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
                title: Text('${vehicle.brand} ${vehicle.model}'),
                subtitle: Text(
                  [
                    if (vehicle.modelYear != null) vehicle.modelYear.toString(),
                    if ((vehicle.fuelType ?? '').isNotEmpty) vehicle.fuelType!,
                    vehicle.active
                        ? strings.pick(pt: 'Ativo', en: 'Active', es: 'Activo')
                        : strings.pick(
                            pt: 'Inativo',
                            en: 'Inactive',
                            es: 'Inactivo',
                          ),
                  ].join(' • '),
                ),
                selected: vehicle.id == _vehicleFilterId,
                onTap: () => Navigator.of(context).pop(vehicle.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _vehicleFilterId = selected);
  }

  String _selectedVehicleFilterLabel(BuildContext context) {
    final strings = AppStrings.of(context);
    if (_vehicleFilterId == null) {
      return strings.pick(
        pt: 'Todos os veiculos',
        en: 'All vehicles',
        es: 'Todos los vehiculos',
      );
    }

    final vehicle = _vehicles.where((item) => item.id == _vehicleFilterId);
    if (vehicle.isEmpty) {
      return strings.pick(
        pt: 'Veiculo filtrado',
        en: 'Filtered vehicle',
        es: 'Vehiculo filtrado',
      );
    }
    final selected = vehicle.first;
    return '${selected.brand} ${selected.model}';
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _range = _currentMonthRange();
      _vehicleFilterId = null;
    });
  }

  DateTimeRange _currentMonthRange() {
    final now = DateTime.now();
    return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }
}

class _MaintenanceMonthGroup {
  _MaintenanceMonthGroup({required this.label, required this.days});

  final String label;
  final List<_MaintenanceDayGroup> days;
}

class _MaintenanceDayGroup {
  _MaintenanceDayGroup({
    required this.dayKey,
    required this.label,
    required this.maintenances,
  });

  final DateTime dayKey;
  final String label;
  final List<AppMaintenance> maintenances;

  double get amount =>
      maintenances.fold<double>(0, (sum, item) => sum + item.totalAmount);
}

class _MaintenanceMonthSection extends StatelessWidget {
  const _MaintenanceMonthSection({
    required this.title,
    required this.days,
    required this.format,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
    required this.formatTime,
  });

  final String title;
  final List<_MaintenanceDayGroup> days;
  final AppFormat format;
  final AppStrings strings;
  final ValueChanged<AppMaintenance> onEdit;
  final ValueChanged<AppMaintenance> onDelete;
  final String Function(DateTime value) formatTime;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4),
          child: Text(title, style: textTheme.titleMedium),
        ),
        for (final day in days) ...[
          OmnyaGlassCard(
            highlight: true,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${day.label} - ${day.maintenances.length} '
                    '${day.maintenances.length == 1 ? strings.pick(pt: 'manutencao', en: 'maintenance', es: 'mantenimiento') : strings.pick(pt: 'manutencoes', en: 'maintenance records', es: 'mantenimientos')} | '
                    '${format.currency(day.amount)}',
                    style: textTheme.titleSmall,
                  ),
                ),
                Icon(
                  Icons.build_circle_rounded,
                  color: OmnyaVisualTokens.neonBlue.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final maintenance in day.maintenances) ...[
            OmnyaGlassCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: OmnyaVisualTokens.neonBlue.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.build_circle_rounded),
                ),
                title: Text(
                  maintenance.vehicleLabel ??
                      strings.pick(
                        pt: 'Veiculo',
                        en: 'Vehicle',
                        es: 'Vehiculo',
                      ),
                ),
                subtitle: Text(
                  [
                    formatTime(maintenance.maintenanceDate),
                    if (maintenance.workshop != null &&
                        maintenance.workshop!.trim().isNotEmpty)
                      maintenance.workshop!,
                    if (maintenance.reason != null &&
                        maintenance.reason!.trim().isNotEmpty)
                      maintenance.reason!,
                    if (maintenance.paymentMethod != null &&
                        maintenance.paymentMethod!.trim().isNotEmpty)
                      maintenance.paymentMethod!,
                    format.currency(maintenance.totalAmount),
                  ].join(' | '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit(maintenance);
                    if (value == 'delete') onDelete(maintenance);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        strings.pick(pt: 'Editar', en: 'Edit', es: 'Editar'),
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
                children: [
                  if (maintenance.description != null &&
                      maintenance.description!.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(maintenance.description!),
                      ),
                    ),
                  for (final item in maintenance.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.description)),
                          Text(format.currency(item.amount)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
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
    required String paymentMethod,
    required String currentOdometer,
    required String nextMaintenanceOdometer,
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
  late final TextEditingController _currentOdometerController;
  late final TextEditingController _nextMaintenanceOdometerController;
  late final List<_MaintenanceItemEntry> _items;
  String? _vehicleId;
  String? _paymentMethod;
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
    _currentOdometerController = TextEditingController(
      text: initialMaintenance?.currentOdometer == null
          ? ''
          : initialMaintenance!.currentOdometer!.toStringAsFixed(0),
    );
    _nextMaintenanceOdometerController = TextEditingController(
      text: initialMaintenance?.nextMaintenanceOdometer == null
          ? ''
          : initialMaintenance!.nextMaintenanceOdometer!.toStringAsFixed(0),
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
    _paymentMethod = initialMaintenance?.paymentMethod;
    _maintenanceDate =
        initialMaintenance?.maintenanceDate.toLocal() ?? DateTime.now();
  }

  @override
  void dispose() {
    _workshopController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    _currentOdometerController.dispose();
    _nextMaintenanceOdometerController.dispose();
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pagamento',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                    DropdownMenuItem(
                      value: 'Dinheiro',
                      child: Text('Dinheiro'),
                    ),
                    DropdownMenuItem(
                      value: 'Cartao de credito',
                      child: Text('Cartao de credito'),
                    ),
                    DropdownMenuItem(
                      value: 'Cartao de debito',
                      child: Text('Cartao de debito'),
                    ),
                    DropdownMenuItem(value: 'Boleto', child: Text('Boleto')),
                    DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  ],
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentOdometerController,
                        decoration: const InputDecoration(
                          labelText: 'Km atual',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nextMaintenanceOdometerController,
                        decoration: const InputDecoration(
                          labelText: 'Km proxima manutencao',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
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
                      paymentMethod: _paymentMethod ?? '',
                      currentOdometer: _currentOdometerController.text,
                      nextMaintenanceOdometer:
                          _nextMaintenanceOdometerController.text,
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
      title: const Text('Data e horario'),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
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
        if (!context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        final selectedTime = time ?? TimeOfDay.fromDateTime(value);
        onChanged(
          DateTime(
            date.year,
            date.month,
            date.day,
            selectedTime.hour,
            selectedTime.minute,
          ),
        );
      },
    );
  }
}
