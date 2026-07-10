import 'package:flutter/material.dart';

import '../../models/app_goal.dart';
import '../../services/goal_service.dart';
import '../../services/journey_service.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/screen_action_controller.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();
  bool _loading = true;
  List<AppGoal> _goals = const [];
  List<AppGoalTransaction> _transactions = const [];
  GoalBalanceSummary? _summary;
  List<JourneyOption> _journeyOptions = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.actionController?.bindCreate(_openCreateGoalDialog);
    _loadData();
  }

  @override
  void dispose() {
    widget.actionController?.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _goalService.listGoals(),
        _goalService.listTransactions(),
        _goalService.loadBalanceSummary(),
        JourneyService().listJourneyOptions(),
      ]);
      if (!mounted) return;
      setState(() {
        _goals = results[0] as List<AppGoal>;
        _transactions = results[1] as List<AppGoalTransaction>;
        _summary = results[2] as GoalBalanceSummary;
        _journeyOptions = results[3] as List<JourneyOption>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar os objetivos agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return const OmnyaSubPageScaffold(title: 'Objetivos', body: loading);
    }

    final summary =
        _summary ??
        const GoalBalanceSummary(
          netOperationalResult: 0,
          allocatedToGoals: 0,
          availableBalance: 0,
        );

    final content = RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Objetivos financeiros',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.showCreateButton)
                  FilledButton.icon(
                    onPressed: _openCreateGoalDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo do motorista',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _GoalSummaryTile(
                        title: 'Resultado liquido',
                        value: _currency(summary.netOperationalResult),
                      ),
                      _GoalSummaryTile(
                        title: 'Ja destinado para objetivos',
                        value: _currency(summary.allocatedToGoals),
                      ),
                      _GoalSummaryTile(
                        title: 'Saldo disponivel',
                        value: _currency(summary.availableBalance),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'O saldo so deixa de ficar disponivel quando voce faz um aporte em um objetivo. Retiradas devolvem esse valor para o saldo disponivel.',
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_goals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Nenhum objetivo cadastrado ainda. Crie objetivos para destinar parte do lucro e acompanhar seu progresso.',
                ),
              ),
            ),
          ..._goals.map(
            (goal) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currency(goal.currentAmount)} de ${_currency(goal.targetAmount)}',
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: goal.progress),
                              const SizedBox(height: 8),
                              Text(
                                'Faltam ${_currency(goal.remainingAmount)}${goal.deadline == null ? '' : ' ate ${_formatDate(goal.deadline!)}'}',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await _openEditGoalDialog(goal);
                              case 'delete':
                                await _deleteGoal(goal);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openTransactionDialog(
                            goal: goal,
                            mode: GoalTransactionMode.contribution,
                          ),
                          icon: const Icon(Icons.savings_outlined),
                          label: const Text('Aportar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: goal.currentAmount <= 0
                              ? null
                              : () => _openTransactionDialog(
                                  goal: goal,
                                  mode: GoalTransactionMode.withdrawal,
                                ),
                          icon: const Icon(Icons.outbox_outlined),
                          label: const Text('Retirar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historico de movimentacoes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    const Text('Nenhuma movimentacao registrada ainda.'),
                  ..._transactions.map(
                    (transaction) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(transaction.goalTitle),
                      subtitle: Text(
                        [
                          transaction.isContribution ? 'Aporte' : 'Retirada',
                          _formatDateTime(transaction.createdAt),
                          if (transaction.journeyLabel != null)
                            transaction.journeyLabel!,
                        ].join(' - '),
                      ),
                      trailing: Text(
                        '${transaction.isContribution ? '+' : '-'} ${_currency(transaction.amount.abs())}',
                      ),
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
      title: 'Objetivos',
      heroTagPrefix: 'goals',
      floatingActions: [
        OmnyaFabAction(
          label: 'Novo objetivo',
          icon: Icons.add,
          onTap: _openCreateGoalDialog,
        ),
      ],
      body: content,
    );
  }

  Future<void> _openCreateGoalDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _GoalFormDialog(
        onSubmit:
            ({
              required title,
              required targetAmount,
              required icon,
              required deadline,
            }) async {
              await _goalService.createGoal(
                title: title,
                targetAmount: targetAmount,
                icon: icon,
                deadline: deadline,
              );
            },
      ),
    );

    if (created == true) {
      await _loadData();
    }
  }

  Future<void> _openEditGoalDialog(AppGoal goal) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _GoalFormDialog(
        initialGoal: goal,
        onSubmit:
            ({
              required title,
              required targetAmount,
              required icon,
              required deadline,
            }) async {
              await _goalService.updateGoal(
                id: goal.id,
                title: title,
                targetAmount: targetAmount,
                icon: icon,
                deadline: deadline,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadData();
    }
  }

  Future<void> _deleteGoal(AppGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir objetivo'),
        content: Text(
          'Deseja excluir "${goal.title}"?${goal.currentAmount > 0 ? ' O valor atual voltara a ficar disponivel no saldo.' : ''}',
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

    await _goalService.deleteGoal(goal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Objetivo removido com sucesso.')),
    );
    await _loadData();
  }

  Future<void> _openTransactionDialog({
    required AppGoal goal,
    required GoalTransactionMode mode,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _GoalTransactionDialog(
        goal: goal,
        mode: mode,
        journeyOptions: _journeyOptions,
        availableBalance: _summary?.availableBalance ?? 0,
        onSubmit: ({required amount, required journeyId}) async {
          await _goalService.applyTransaction(
            goalId: goal.id,
            amount: mode == GoalTransactionMode.withdrawal
                ? '-$amount'
                : amount,
            journeyId: journeyId,
          );
        },
      ),
    );

    if (saved == true) {
      await _loadData();
    }
  }

  String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${_formatDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _GoalSummaryTile extends StatelessWidget {
  const _GoalSummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _GoalFormDialog extends StatefulWidget {
  const _GoalFormDialog({required this.onSubmit, this.initialGoal});

  final AppGoal? initialGoal;
  final Future<void> Function({
    required String title,
    required String targetAmount,
    required String icon,
    required DateTime? deadline,
  })
  onSubmit;

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _iconController;
  DateTime? _deadline;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialGoal?.title ?? '',
    );
    _targetAmountController = TextEditingController(
      text: widget.initialGoal?.targetAmount.toStringAsFixed(2) ?? '',
    );
    _iconController = TextEditingController(
      text: widget.initialGoal?.icon ?? '',
    );
    _deadline = widget.initialGoal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialGoal == null ? 'Novo objetivo' : 'Editar objetivo',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                  validator: _required,
                ),
                TextFormField(
                  controller: _targetAmountController,
                  decoration: const InputDecoration(labelText: 'Valor alvo'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icone ou emoji (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prazo'),
                  subtitle: Text(
                    _deadline == null
                        ? 'Sem prazo definido'
                        : '${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_deadline != null)
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _deadline = null),
                          icon: const Icon(Icons.close),
                        ),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                  onTap: _saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deadline ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2040),
                          );
                          if (picked == null || !mounted) return;
                          setState(() => _deadline = picked);
                        },
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
                      title: _titleController.text,
                      targetAmount: _targetAmountController.text,
                      icon: _iconController.text,
                      deadline: _deadline,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _submitError =
                          'Nao foi possivel salvar o objetivo agora. ${error.toString()}';
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

enum GoalTransactionMode { contribution, withdrawal }

class _GoalTransactionDialog extends StatefulWidget {
  const _GoalTransactionDialog({
    required this.goal,
    required this.mode,
    required this.journeyOptions,
    required this.availableBalance,
    required this.onSubmit,
  });

  final AppGoal goal;
  final GoalTransactionMode mode;
  final List<JourneyOption> journeyOptions;
  final double availableBalance;
  final Future<void> Function({
    required String amount,
    required String? journeyId,
  })
  onSubmit;

  @override
  State<_GoalTransactionDialog> createState() => _GoalTransactionDialogState();
}

class _GoalTransactionDialogState extends State<_GoalTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _journeyId;
  bool _saving = false;
  String? _submitError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isContribution = widget.mode == GoalTransactionMode.contribution;
    return AlertDialog(
      title: Text(
        isContribution ? 'Aportar no objetivo' : 'Retirar do objetivo',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.goal.title),
                const SizedBox(height: 8),
                Text(
                  isContribution
                      ? 'Saldo disponivel: R\$ ${widget.availableBalance.toStringAsFixed(2)}'
                      : 'Saldo atual do objetivo: R\$ ${widget.goal.currentAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: isContribution
                        ? 'Valor do aporte'
                        : 'Valor da retirada',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o valor.';
                    }
                    final parsed = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Informe um valor valido.';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _journeyId,
                  decoration: const InputDecoration(
                    labelText: 'Jornada relacionada',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem vincular'),
                    ),
                    ...widget.journeyOptions.map(
                      (journey) => DropdownMenuItem<String?>(
                        value: journey.id,
                        child: Text(journey.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _journeyId = value),
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
                      amount: _amountController.text,
                      journeyId: _journeyId,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _submitError = error.toString();
                    });
                  } finally {
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  }
                },
          child: Text(isContribution ? 'Aportar' : 'Retirar'),
        ),
      ],
    );
  }
}
