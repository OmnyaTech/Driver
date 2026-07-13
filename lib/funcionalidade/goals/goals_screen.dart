import 'package:flutter/material.dart';

import '../../models/app_goal.dart';
import '../../services/goal_service.dart';
import '../../services/journey_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/omnya_visuals.dart';
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
  List<AppGoalSuggestion> _suggestions = const [];
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
        final goals = results[0] as List<AppGoal>;
        final summary = results[2] as GoalBalanceSummary;
        _goals = goals;
        _suggestions = _goalService.buildAutomaticSuggestions(
          goals: goals,
          summary: summary,
        );
        _transactions = results[1] as List<AppGoalTransaction>;
        _summary = summary;
        _journeyOptions = results[3] as List<JourneyOption>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Nao foi possivel carregar os objetivos agora. Tente novamente.',
          en: 'We could not load your goals right now. Please try again.',
          es: 'No pudimos cargar tus metas ahora. Intentalo de nuevo.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return OmnyaSubPageScaffold(title: strings.goals, body: loading);
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
                    strings.pick(
                      pt: 'Objetivos financeiros',
                      en: 'Money goals',
                      es: 'Metas financieras',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.showCreateButton)
                  FilledButton.icon(
                    onPressed: _openCreateGoalDialog,
                    icon: const Icon(Icons.add),
                    label: Text(strings.newItem),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          OmnyaHeroCard(
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        strings.pick(
                          pt: 'Seu cofre da rotina',
                          en: 'Your routine vault',
                          es: 'Tu caja de rutina',
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _GoalSummaryTile(
                      title: strings.pick(
                        pt: 'Sobrou',
                        en: 'Left over',
                        es: 'Sobro',
                      ),
                      value: _currency(summary.netOperationalResult),
                      emphasized: true,
                    ),
                    _GoalSummaryTile(
                      title: strings.pick(
                        pt: 'Guardado',
                        en: 'Saved',
                        es: 'Guardado',
                      ),
                      value: _currency(summary.allocatedToGoals),
                    ),
                    _GoalSummaryTile(
                      title: strings.pick(pt: 'Livre', en: 'Free', es: 'Libre'),
                      value: _currency(summary.availableBalance),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  strings.pick(
                    pt: 'Separe dinheiro para oleo, pneu, revisao e emergencias sem perder o controle do que ainda esta livre.',
                    en: 'Set money aside for oil, tires, repairs and emergencies without losing track of what is still free.',
                    es: 'Separa dinero para aceite, llantas, revision y emergencias sin perder de vista lo que sigue libre.',
                  ),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.84)),
                ),
              ],
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
          if (_suggestions.isNotEmpty) ...[
            _GoalSuggestionsCard(
              suggestions: _suggestions,
              currency: _currency,
              onAccept: _acceptSuggestion,
            ),
            const SizedBox(height: 16),
          ],
          if (_goals.isEmpty)
            OmnyaEmptyState(
              icon: Icons.flag_circle_rounded,
              title: strings.pick(
                pt: 'Nenhum objetivo ainda',
                en: 'No goals yet',
                es: 'Aun no hay metas',
              ),
              message: strings.pick(
                pt: 'Crie seu primeiro cofre para separar parte do que sobrou.',
                en: 'Create your first vault to set aside part of what is left.',
                es: 'Crea tu primera caja para separar parte de lo que sobro.',
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
                                strings.pick(
                                  pt: '${_currency(goal.currentAmount)} de ${_currency(goal.targetAmount)}',
                                  en: '${_currency(goal.currentAmount)} of ${_currency(goal.targetAmount)}',
                                  es: '${_currency(goal.currentAmount)} de ${_currency(goal.targetAmount)}',
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: goal.progress),
                              const SizedBox(height: 8),
                              Text(
                                strings.pick(
                                  pt: 'Faltam ${_currency(goal.remainingAmount)}${goal.deadline == null ? '' : ' ate ${_formatDate(goal.deadline!)}'}',
                                  en: '${_currency(goal.remainingAmount)} left${goal.deadline == null ? '' : ' until ${_formatDate(goal.deadline!)}'}',
                                  es: 'Faltan ${_currency(goal.remainingAmount)}${goal.deadline == null ? '' : ' hasta ${_formatDate(goal.deadline!)}'}',
                                ),
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
                          label: Text(
                            strings.pick(
                              pt: 'Aportar',
                              en: 'Save',
                              es: 'Guardar',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: goal.currentAmount <= 0
                              ? null
                              : () => _openTransactionDialog(
                                  goal: goal,
                                  mode: GoalTransactionMode.withdrawal,
                                ),
                          icon: const Icon(Icons.outbox_outlined),
                          label: Text(
                            strings.pick(
                              pt: 'Retirar',
                              en: 'Withdraw',
                              es: 'Retirar',
                            ),
                          ),
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
                    strings.pick(
                      pt: 'Historico de movimentacoes',
                      en: 'Movement history',
                      es: 'Historial de movimientos',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Text(
                      strings.pick(
                        pt: 'Nenhuma movimentacao registrada ainda.',
                        en: 'No movements recorded yet.',
                        es: 'Aun no hay movimientos.',
                      ),
                    ),
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
      title: strings.goals,
      heroTagPrefix: 'goals',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newGoal,
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

  Future<void> _acceptSuggestion(AppGoalSuggestion suggestion) async {
    try {
      await _goalService.createGoal(
        title: suggestion.title,
        targetAmount: suggestion.targetAmount.toStringAsFixed(2),
        icon: suggestion.icon,
        deadline: suggestion.deadline,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: '${suggestion.title} entrou nos objetivos.',
              en: '${suggestion.title} was added to your goals.',
              es: '${suggestion.title} fue agregada a tus metas.',
            ),
          ),
        ),
      );
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: 'Nao consegui criar essa sugestao: $error',
              en: 'Could not create this suggestion: $error',
              es: 'No pude crear esta sugerencia: $error',
            ),
          ),
        ),
      );
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
        title: Text(
          AppStrings.of(context).pick(
            pt: 'Excluir objetivo',
            en: 'Delete goal',
            es: 'Eliminar meta',
          ),
        ),
        content: Text(
          AppStrings.of(context).pick(
            pt: 'Deseja excluir "${goal.title}"?${goal.currentAmount > 0 ? ' O valor atual voltara a ficar disponivel no saldo.' : ''}',
            en: 'Delete "${goal.title}"?${goal.currentAmount > 0 ? ' The saved amount will return to your available balance.' : ''}',
            es: 'Eliminar "${goal.title}"?${goal.currentAmount > 0 ? ' El valor guardado volvera al saldo disponible.' : ''}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.of(
                context,
              ).pick(pt: 'Cancelar', en: 'Cancel', es: 'Cancelar'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.of(
                context,
              ).pick(pt: 'Excluir', en: 'Delete', es: 'Eliminar'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _goalService.deleteGoal(goal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(context).pick(
            pt: 'Objetivo removido com sucesso.',
            en: 'Goal removed.',
            es: 'Meta eliminada.',
          ),
        ),
      ),
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

  String _currency(double value) => AppFormat.of(context).currency(value);

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
  const _GoalSummaryTile({
    required this.title,
    required this.value,
    this.emphasized = false,
  });

  final String title;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: emphasized ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSuggestionsCard extends StatelessWidget {
  const _GoalSuggestionsCard({
    required this.suggestions,
    required this.currency,
    required this.onAccept,
  });

  final List<AppGoalSuggestion> suggestions;
  final String Function(double value) currency;
  final Future<void> Function(AppGoalSuggestion suggestion) onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.pick(
                      pt: 'Sugestoes para se organizar',
                      en: 'Ideas to stay organized',
                      es: 'Ideas para organizarte',
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.pick(
                pt: 'Ideias rapidas baseadas no que costuma pesar na rotina de quem entrega.',
                en: 'Quick ideas based on the costs that usually show up in a delivery routine.',
                es: 'Ideas rapidas basadas en los costos comunes de quien reparte.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final cards = suggestions.map((suggestion) {
                  return _GoalSuggestionTile(
                    suggestion: suggestion,
                    currency: currency,
                    onAccept: () => onAccept(suggestion),
                  );
                }).toList();

                if (compact) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        if (card != cards.last) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Wrap(spacing: 12, runSpacing: 12, children: cards);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSuggestionTile extends StatelessWidget {
  const _GoalSuggestionTile({
    required this.suggestion,
    required this.currency,
    required this.onAccept,
  });

  final AppGoalSuggestion suggestion;
  final String Function(double value) currency;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor),
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  _iconFor(suggestion.icon),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      currency(suggestion.targetAmount),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(suggestion.description),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onAccept,
              icon: const Icon(Icons.add),
              label: Text(
                strings.pick(pt: 'Adicionar', en: 'Add', es: 'Agregar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String value) {
    return switch (value) {
      'shield' => Icons.health_and_safety_outlined,
      'oil' => Icons.oil_barrel_outlined,
      'tire' => Icons.album_outlined,
      'wrench' => Icons.build_outlined,
      'calendar' => Icons.calendar_month_outlined,
      'document' => Icons.description_outlined,
      'lock' => Icons.lock_outline,
      _ => Icons.flag_outlined,
    };
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
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(
        widget.initialGoal == null
            ? strings.newGoal
            : strings.pick(
                pt: 'Editar objetivo',
                en: 'Edit goal',
                es: 'Editar meta',
              ),
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
                  decoration: InputDecoration(
                    labelText: strings.pick(
                      pt: 'Titulo',
                      en: 'Title',
                      es: 'Titulo',
                    ),
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _targetAmountController,
                  decoration: InputDecoration(
                    labelText: strings.pick(
                      pt: 'Valor alvo',
                      en: 'Target amount',
                      es: 'Valor objetivo',
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _iconController,
                  decoration: InputDecoration(
                    labelText: strings.pick(
                      pt: 'Icone ou emoji (opcional)',
                      en: 'Icon or emoji (optional)',
                      es: 'Icono o emoji (opcional)',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    strings.pick(pt: 'Prazo', en: 'Deadline', es: 'Plazo'),
                  ),
                  subtitle: Text(
                    _deadline == null
                        ? strings.pick(
                            pt: 'Sem prazo definido',
                            en: 'No deadline set',
                            es: 'Sin plazo definido',
                          )
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
                      ? 'Saldo disponivel: ${AppFormat.of(context).currency(widget.availableBalance)}'
                      : 'Saldo atual do objetivo: ${AppFormat.of(context).currency(widget.goal.currentAmount)}',
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
