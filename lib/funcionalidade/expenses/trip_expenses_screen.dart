import 'package:flutter/material.dart';

import '../../models/app_trip_expense.dart';
import '../../services/journey_service.dart';
import '../../services/trip_expense_service.dart';

class TripExpensesScreen extends StatefulWidget {
  const TripExpensesScreen({super.key});

  @override
  State<TripExpensesScreen> createState() => _TripExpensesScreenState();
}

class _TripExpensesScreenState extends State<TripExpensesScreen> {
  final TripExpenseService _expenseService = TripExpenseService();
  bool _loading = true;
  List<AppTripExpense> _expenses = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
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
    final journeys = await JourneyService().listJourneyOptions();
    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _TripExpenseFormDialog(
        journeys: journeys,
        onSubmit:
            ({
              required type,
              required amount,
              required occurredAt,
              required description,
              required journeyId,
            }) async {
              await _expenseService.createExpense(
                type: type,
                amount: amount,
                occurredAt: occurredAt,
                description: description,
                journeyId: journeyId,
              );
            },
      ),
    );

    if (created == true) {
      await _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Despesas de percurso',
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
            if (_expenses.isNotEmpty)
              Card(
                child: ListTile(
                  title: const Text('Resumo'),
                  subtitle: Text('${_expenses.length} despesas registradas'),
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
            if (_expenses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma despesa registrada ainda. Cadastre pedagio, estacionamento e outros custos de percurso.',
                  ),
                ),
              ),
            ..._expenses.map(
              (expense) => Card(
                child: ListTile(
                  title: Text(_expenseLabel(expense.type)),
                  subtitle: Text(
                    [
                      _formatDate(expense.occurredAt),
                      if (expense.journeyLabel != null) expense.journeyLabel!,
                      if (expense.description != null &&
                          expense.description!.trim().isNotEmpty)
                        expense.description!,
                    ].join(' - '),
                  ),
                  trailing: Text('R\$ ${expense.amount.toStringAsFixed(2)}'),
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

  String _expenseLabel(String type) {
    return switch (type) {
      'toll' => 'Pedagio',
      'parking' => 'Estacionamento',
      'fuel' => 'Combustivel',
      'maintenance' => 'Manutencao',
      _ => 'Outro',
    };
  }

  double get _totalAmount => _expenses.fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );
}

class _TripExpenseFormDialog extends StatefulWidget {
  const _TripExpenseFormDialog({
    required this.journeys,
    required this.onSubmit,
  });

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
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'other';
  String? _journeyId;
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;
  String? _submitError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova despesa'),
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
