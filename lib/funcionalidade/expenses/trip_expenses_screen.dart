import 'package:flutter/material.dart';

import '../../models/app_trip_expense.dart';
import '../finance/widgets/financial_filter_toolbar.dart';
import '../../services/journey_service.dart';
import '../../services/trip_expense_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/omnya_visuals.dart';
import '../../utilities/ui/screen_action_controller.dart';

class TripExpensesScreen extends StatefulWidget {
  const TripExpensesScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<TripExpensesScreen> createState() => _TripExpensesScreenState();
}

class _TripExpensesScreenState extends State<TripExpensesScreen> {
  final TripExpenseService _expenseService = TripExpenseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppTripExpense> _expenses = const [];
  String? _errorMessage;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    _range = _currentMonthRange();
    widget.actionController?.bindCreate(_openCreateDialog);
    _searchController.addListener(_handleFilterChange);
    _loadExpenses();
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

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final expenses = await _expenseService.listExpenses();
      if (!mounted) return;
      setState(() => _expenses = expenses);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar as despesas agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateDialog() async {
    await _openExpenseDialog();
  }

  Future<void> _openEditDialog(AppTripExpense expense) async {
    await _openExpenseDialog(initialExpense: expense);
  }

  Future<void> _openExpenseDialog({AppTripExpense? initialExpense}) async {
    final journeys = await JourneyService().listJourneyOptions();
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TripExpenseFormDialog(
        initialExpense: initialExpense,
        journeys: journeys,
        onSubmit:
            ({
              required type,
              required amount,
              required occurredAt,
              required description,
              required journeyId,
            }) async {
              if (initialExpense == null) {
                await _expenseService.createExpense(
                  type: type,
                  amount: amount,
                  occurredAt: occurredAt,
                  description: description,
                  journeyId: journeyId,
                );
                return;
              }

              await _expenseService.updateExpense(
                id: initialExpense.id,
                type: type,
                amount: amount,
                occurredAt: occurredAt,
                description: description,
                journeyId: journeyId,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadExpenses();
    }
  }

  Future<void> _deleteExpense(AppTripExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir despesa'),
        content: Text(
          'Deseja excluir a despesa de ${_expenseLabel(expense.type)} no valor de ${AppFormat.of(context).currency(expense.amount)}?',
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

    await _expenseService.deleteExpense(expense.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Despesa removida com sucesso.')),
    );
    await _loadExpenses();
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
        title: strings.pick(pt: 'Despesas', en: 'Expenses', es: 'Gastos'),
        body: loading,
      );
    }

    final content = RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.pick(
                      pt: 'Despesas de percurso',
                      en: 'Trip expenses',
                      es: 'Gastos del recorrido',
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
              pt: 'Buscar tipo, jornada ou descricao',
              en: 'Search type, shift or description',
              es: 'Buscar tipo, jornada o descripcion',
            ),
            onPickRange: _pickRange,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          if (_filteredExpenses.isNotEmpty)
            OmnyaGlassCard(
              highlight: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: OmnyaVisualTokens.expense.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.receipt_long_rounded),
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
                            pt: '${_filteredExpenses.length} despesas encontradas',
                            en: '${_filteredExpenses.length} expenses found',
                            es: '${_filteredExpenses.length} gastos encontrados',
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
          if (_filteredExpenses.isNotEmpty) const SizedBox(height: 12),
          if (_errorMessage != null)
            OmnyaGlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_expenses.isEmpty)
            OmnyaEmptyState(
              icon: Icons.receipt_long_rounded,
              title: strings.pick(
                pt: 'Nenhuma despesa ainda',
                en: 'No expenses yet',
                es: 'Aun no hay gastos',
              ),
              message: strings.pick(
                pt: 'Cadastre pedagio, estacionamento e outros custos de percurso quando aparecerem.',
                en: 'Add tolls, parking and other trip costs when they show up.',
                es: 'Agrega peajes, estacionamiento y otros costos cuando aparezcan.',
              ),
            ),
          if (_expenses.isNotEmpty && _filteredExpenses.isEmpty)
            OmnyaEmptyState(
              icon: Icons.search_off_rounded,
              title: strings.pick(
                pt: 'Nada nesse filtro',
                en: 'Nothing in this filter',
                es: 'Nada en este filtro',
              ),
              message: strings.pick(
                pt: 'Ajuste a busca ou o periodo para encontrar despesas antigas.',
                en: 'Adjust search or period to find older expenses.',
                es: 'Ajusta la busqueda o el periodo para encontrar gastos antiguos.',
              ),
            ),
          ..._groupedExpenses.map(
            (monthGroup) => _ExpenseMonthSection(
              title: monthGroup.label,
              days: monthGroup.days,
              format: format,
              strings: strings,
              onEdit: _openEditDialog,
              onDelete: _deleteExpense,
              expenseLabel: _expenseLabel,
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
      title: strings.pick(pt: 'Despesas', en: 'Expenses', es: 'Gastos'),
      heroTagPrefix: 'expenses',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newExpense,
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

  String _expenseLabel(String type) {
    final strings = AppStrings.of(context);
    return switch (type) {
      'toll' => strings.pick(pt: 'Pedagio', en: 'Toll', es: 'Peaje'),
      'parking' => strings.pick(
        pt: 'Estacionamento',
        en: 'Parking',
        es: 'Estacionamiento',
      ),
      'fuel' => strings.pick(pt: 'Combustivel', en: 'Fuel', es: 'Combustible'),
      'maintenance' => strings.pick(
        pt: 'Manutencao',
        en: 'Maintenance',
        es: 'Mantenimiento',
      ),
      _ => strings.pick(pt: 'Outro', en: 'Other', es: 'Otro'),
    };
  }

  double get _totalAmount =>
      _filteredExpenses.fold<double>(0, (sum, item) => sum + item.amount);

  List<AppTripExpense> get _filteredExpenses {
    final query = _searchController.text.trim().toLowerCase();
    final items = _expenses.where((expense) {
      if (!_isWithinRange(expense.occurredAt)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        _expenseLabel(expense.type),
        expense.description,
        expense.journeyLabel,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return items;
  }

  List<_ExpenseMonthGroup> get _groupedExpenses {
    final monthGroups = <_ExpenseMonthGroup>[];

    for (final expense in _filteredExpenses) {
      final local = expense.occurredAt.toLocal();
      final monthLabel = _formatMonth(local);
      final dayKey = DateTime(local.year, local.month, local.day);
      final dayLabel =
          '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';

      _ExpenseMonthGroup? monthGroup;
      for (final group in monthGroups) {
        if (group.label == monthLabel) {
          monthGroup = group;
          break;
        }
      }
      if (monthGroup == null) {
        monthGroup = _ExpenseMonthGroup(label: monthLabel, days: []);
        monthGroups.add(monthGroup);
      }

      _ExpenseDayGroup? dayGroup;
      for (final group in monthGroup.days) {
        if (group.dayKey == dayKey) {
          dayGroup = group;
          break;
        }
      }
      if (dayGroup == null) {
        dayGroup = _ExpenseDayGroup(
          dayKey: dayKey,
          label: dayLabel,
          expenses: [],
        );
        monthGroup.days.add(dayGroup);
      }

      dayGroup.expenses.add(expense);
    }

    return monthGroups;
  }

  String _formatMonth(DateTime value) {
    const months = [
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
    return '${months[value.month - 1]}/${value.year}';
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

class _ExpenseMonthGroup {
  _ExpenseMonthGroup({required this.label, required this.days});

  final String label;
  final List<_ExpenseDayGroup> days;
}

class _ExpenseDayGroup {
  _ExpenseDayGroup({
    required this.dayKey,
    required this.label,
    required this.expenses,
  });

  final DateTime dayKey;
  final String label;
  final List<AppTripExpense> expenses;

  double get amount =>
      expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
}

class _ExpenseMonthSection extends StatelessWidget {
  const _ExpenseMonthSection({
    required this.title,
    required this.days,
    required this.format,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
    required this.expenseLabel,
    required this.formatTime,
  });

  final String title;
  final List<_ExpenseDayGroup> days;
  final AppFormat format;
  final AppStrings strings;
  final ValueChanged<AppTripExpense> onEdit;
  final ValueChanged<AppTripExpense> onDelete;
  final String Function(String type) expenseLabel;
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
                    '${day.label} - ${day.expenses.length} '
                    '${day.expenses.length == 1 ? strings.pick(pt: 'despesa', en: 'expense', es: 'gasto') : strings.pick(pt: 'despesas', en: 'expenses', es: 'gastos')} | '
                    '${format.currency(day.amount)}',
                    style: textTheme.titleSmall,
                  ),
                ),
                Icon(
                  Icons.receipt_long_rounded,
                  color: OmnyaVisualTokens.expense.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final expense in day.expenses) ...[
            OmnyaGlassCard(
              padding: const EdgeInsets.all(14),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${expenseLabel(expense.type)} | ${format.currency(expense.amount)}',
                ),
                subtitle: Text(
                  [
                    formatTime(expense.occurredAt),
                    if (expense.journeyLabel != null) expense.journeyLabel!,
                    if (expense.description != null &&
                        expense.description!.trim().isNotEmpty)
                      expense.description!,
                  ].join(' | '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit(expense);
                    if (value == 'delete') onDelete(expense);
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
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _TripExpenseFormDialog extends StatefulWidget {
  const _TripExpenseFormDialog({
    this.initialExpense,
    required this.journeys,
    required this.onSubmit,
  });

  final AppTripExpense? initialExpense;
  final List<JourneyOption> journeys;
  final Future<void> Function({
    required String type,
    required String amount,
    required DateTime occurredAt,
    required String description,
    required String? journeyId,
  })
  onSubmit;

  @override
  State<_TripExpenseFormDialog> createState() => _TripExpenseFormDialogState();
}

class _TripExpenseFormDialogState extends State<_TripExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _type;
  String? _journeyId;
  late DateTime _occurredAt;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialExpense == null
          ? ''
          : widget.initialExpense!.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.initialExpense?.description ?? '',
    );
    _type = widget.initialExpense?.type ?? 'other';
    _journeyId = widget.initialExpense?.journeyId;
    _occurredAt = widget.initialExpense?.occurredAt.toLocal() ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialExpense == null ? 'Nova despesa' : 'Editar despesa',
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
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'toll', child: Text('Pedagio')),
                    DropdownMenuItem(
                      value: 'parking',
                      child: Text('Estacionamento'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Outro')),
                  ],
                  onChanged: (value) =>
                      setState(() => _type = value ?? 'other'),
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
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Valor'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o valor.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                const SizedBox(height: 12),
                _ExpenseDateTile(
                  value: _occurredAt,
                  onChanged: (value) => setState(() => _occurredAt = value),
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
                      type: _type,
                      amount: _amountController.text,
                      occurredAt: _occurredAt,
                      description: _descriptionController.text,
                      journeyId: _journeyId,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _submitError =
                          'Nao foi possivel salvar a despesa agora. ${error.toString()}';
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
}

class _ExpenseDateTile extends StatelessWidget {
  const _ExpenseDateTile({required this.value, required this.onChanged});

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
