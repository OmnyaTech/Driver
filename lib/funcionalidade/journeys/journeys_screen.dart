import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_journey.dart';
import '../../models/app_platform.dart';
import '../../models/app_vehicle.dart';
import '../finance/widgets/financial_filter_toolbar.dart';
import '../../services/active_journey_storage_service.dart';
import '../../services/active_journey_notification_service.dart';
import '../../services/journey_service.dart';
import '../../services/platform_service.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/omnya_visuals.dart';
import '../../utilities/ui/screen_action_controller.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> {
  final JourneyService _journeyService = JourneyService();
  final ActiveJourneyStorageService _activeJourneyStorage =
      ActiveJourneyStorageService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppJourney> _journeys = const [];
  ActiveJourneyDraft? _activeJourney;
  String? _errorMessage;
  late DateTimeRange _range;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _range = _currentMonthRange();
    _now = DateTime.now();
    widget.actionController?.bindCreate(_openCreateDialog);
    _searchController.addListener(_handleFilterChange);
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_activeJourney != null || _journeys.any((item) => !item.isFinished)) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadJourneys();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleFilterChange)
      ..dispose();
    _clockTimer?.cancel();
    widget.actionController?.clear();
    super.dispose();
  }

  void _handleFilterChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadJourneys() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final journeys = await _journeyService.listJourneys();
      var activeJourney = await _activeJourneyStorage.load();
      final openJourney = _latestOpenAutomaticJourney(journeys);
      if (openJourney != null &&
          (activeJourney == null ||
              activeJourney.journeyId == null ||
              activeJourney.journeyId == openJourney.id)) {
        activeJourney = _draftFromOpenJourney(openJourney);
        await _activeJourneyStorage.save(activeJourney);
      } else if (openJourney == null && activeJourney != null) {
        await _activeJourneyStorage.clear();
        activeJourney = null;
      }
      if (!mounted) return;
      setState(() {
        _journeys = journeys;
        _activeJourney = activeJourney;
        _now = DateTime.now();
      });
      await _syncActiveJourneyNotification(activeJourney);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel carregar as jornadas agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _syncActiveJourneyNotification(
    ActiveJourneyDraft? activeJourney,
  ) async {
    try {
      if (activeJourney == null) {
        await ActiveJourneyNotificationService.instance.cancelActiveJourney();
        return;
      }

      await ActiveJourneyNotificationService.instance.showActiveJourney(
        activeJourney,
      );
      final shouldFinishFromNotification =
          await ActiveJourneyNotificationService.instance
              .consumeFinishRequest();
      if (shouldFinishFromNotification && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeJourney != null) {
            _finishAutomaticJourney();
          }
        });
      }
    } catch (_) {
      // Local notification failures should not mark loaded journeys as failed.
    }
  }

  Future<void> _startAutomaticJourney() async {
    if (_activeJourney != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voce ja tem uma jornada em andamento.')),
      );
      return;
    }

    final vehicles = await VehicleService().listVehicles();
    if (!mounted) return;

    final draft = await showDialog<ActiveJourneyDraft>(
      context: context,
      builder: (_) => _StartAutomaticJourneyDialog(
        vehicles: vehicles.where((item) => item.active).toList(),
      ),
    );

    if (draft == null) return;
    final journeyId = await _journeyService.createJourney(
      mode: 'automatic',
      startedAt: draft.startedAt,
      endedAt: null,
      vehicleId: draft.vehicleId,
      odometerStart: draft.odometerStart,
      odometerEnd: null,
      notes: null,
      platforms: const [],
    );
    final persistedDraft = draft.copyWith(journeyId: journeyId);
    await _activeJourneyStorage.save(persistedDraft);
    await _syncActiveJourneyNotification(persistedDraft);
    if (!mounted) return;
    setState(() => _activeJourney = persistedDraft);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jornada iniciada. Boa corrida!')),
    );
    await _loadJourneys();
  }

  Future<void> _finishAutomaticJourney() async {
    final activeJourney = _activeJourney;
    if (activeJourney == null) return;

    final platforms = await PlatformService().listPlatforms();
    if (!mounted) return;

    final finished = await showDialog<bool>(
      context: context,
      builder: (_) => _FinishAutomaticJourneyDialog(
        activeJourney: activeJourney,
        platforms: platforms.where((item) => item.active).toList(),
        onSubmit:
            ({required odometerEnd, required notes, required platforms}) async {
              final journeyId = activeJourney.journeyId;
              if (journeyId == null || journeyId.trim().isEmpty) {
                await _journeyService.createJourney(
                  mode: 'automatic',
                  startedAt: activeJourney.startedAt,
                  endedAt: DateTime.now(),
                  vehicleId: activeJourney.vehicleId,
                  odometerStart: activeJourney.odometerStart,
                  odometerEnd: odometerEnd,
                  notes: notes,
                  platforms: platforms,
                );
              } else {
                await _journeyService.updateJourney(
                  id: journeyId,
                  mode: 'automatic',
                  startedAt: activeJourney.startedAt,
                  endedAt: DateTime.now(),
                  vehicleId: activeJourney.vehicleId,
                  odometerStart: activeJourney.odometerStart,
                  odometerEnd: odometerEnd,
                  notes: notes,
                  platforms: platforms,
                );
              }
              await _activeJourneyStorage.clear();
              await ActiveJourneyNotificationService.instance
                  .cancelActiveJourney();
            },
      ),
    );

    if (finished == true) {
      if (!mounted) return;
      setState(() => _activeJourney = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jornada finalizada e salva.')),
      );
      await _loadJourneys();
    }
  }

  Future<void> _openCreateDialog() async {
    await _openJourneyDialog();
  }

  Future<void> _openEditDialog(AppJourney journey) async {
    await _openJourneyDialog(initialJourney: journey);
  }

  Future<void> _finishOpenJourney(AppJourney journey) async {
    final draft = _draftFromOpenJourney(journey);
    await _activeJourneyStorage.save(draft);
    if (!mounted) return;
    setState(() => _activeJourney = draft);
    await _finishAutomaticJourney();
  }

  Future<void> _openJourneyDialog({AppJourney? initialJourney}) async {
    final vehicles = await VehicleService().listVehicles();
    final platforms = await PlatformService().listPlatforms();
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _JourneyFormDialog(
        initialJourney: initialJourney,
        vehicles: vehicles.where((item) => item.active).toList(),
        platforms: platforms.where((item) => item.active).toList(),
        onSubmit:
            ({
              required mode,
              required startedAt,
              required endedAt,
              required vehicleId,
              required odometerStart,
              required odometerEnd,
              required notes,
              required platforms,
            }) async {
              if (initialJourney == null) {
                await _journeyService.createJourney(
                  mode: mode,
                  startedAt: startedAt,
                  endedAt: endedAt,
                  vehicleId: vehicleId,
                  odometerStart: odometerStart,
                  odometerEnd: odometerEnd,
                  notes: notes,
                  platforms: platforms,
                );
                return;
              }

              await _journeyService.updateJourney(
                id: initialJourney.id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                vehicleId: vehicleId,
                odometerStart: odometerStart,
                odometerEnd: odometerEnd,
                notes: notes,
                platforms: platforms,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadJourneys();
    }
  }

  Future<void> _deleteJourney(AppJourney journey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir jornada'),
        content: Text(
          'Deseja excluir a jornada "${_formatJourneyTitle(journey)}"?',
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

    await _journeyService.deleteJourney(journey.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jornada removida com sucesso.')),
    );
    await _loadJourneys();
  }

  AppJourney? _latestOpenAutomaticJourney(List<AppJourney> journeys) {
    final open =
        journeys
            .where((item) => item.mode == 'automatic' && !item.isFinished)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return open.isEmpty ? null : open.first;
  }

  ActiveJourneyDraft _draftFromOpenJourney(AppJourney journey) {
    return ActiveJourneyDraft(
      journeyId: journey.id,
      startedAt: journey.startedAt,
      vehicleId: journey.vehicleId,
      vehicleLabel: journey.vehicleLabel,
      odometerStart: journey.odometerStart?.toStringAsFixed(1) ?? '',
    );
  }

  Duration _workedDurationFor(AppJourney journey) {
    final end = journey.endedAt ?? _now;
    if (end.isBefore(journey.startedAt)) return Duration.zero;
    return end.difference(journey.startedAt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return OmnyaSubPageScaffold(
        title: AppStrings.of(context).journeys,
        body: loading,
      );
    }
    final format = AppFormat.of(context);
    final strings = AppStrings.of(context);

    final content = RefreshIndicator(
      onRefresh: _loadJourneys,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.journeys,
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
              pt: 'Buscar veiculo, plataforma, status ou anotacao',
              en: 'Search vehicle, platform, status or note',
              es: 'Buscar vehiculo, plataforma, estado o nota',
            ),
            onPickRange: _pickRange,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          if (_activeJourney != null) ...[
            _ActiveJourneyCard(
              draft: _activeJourney!,
              onFinish: _finishAutomaticJourney,
              onDiscard: _discardActiveJourney,
            ),
            const SizedBox(height: 16),
          ],
          if (_filteredJourneys.isNotEmpty)
            OmnyaGlassCard(
              highlight: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: OmnyaVisualTokens.electricBlue.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.route_rounded),
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
                            pt: '${_filteredJourneys.length} jornadas encontradas',
                            en: '${_filteredJourneys.length} shifts found',
                            es: '${_filteredJourneys.length} jornadas encontradas',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    format.currency(_filteredIncome),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          if (_filteredJourneys.isNotEmpty) const SizedBox(height: 12),
          if (_errorMessage != null)
            OmnyaGlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_journeys.isEmpty)
            OmnyaEmptyState(
              icon: Icons.route_rounded,
              title: strings.pick(
                pt: 'Nenhuma jornada ainda',
                en: 'No shifts yet',
                es: 'Aun no hay jornadas',
              ),
              message: strings.pick(
                pt: 'Crie a primeira jornada para acompanhar ganhos, entregas e tempo de trabalho.',
                en: 'Create your first shift to track earnings, deliveries and working time.',
                es: 'Crea la primera jornada para acompanhar ganancias, entregas y tiempo de trabajo.',
              ),
            ),
          if (_journeys.isNotEmpty && _filteredJourneys.isEmpty)
            OmnyaEmptyState(
              icon: Icons.search_off_rounded,
              title: strings.pick(
                pt: 'Nada nesse filtro',
                en: 'Nothing in this filter',
                es: 'Nada en este filtro',
              ),
              message: strings.pick(
                pt: 'Ajuste a busca ou o periodo para encontrar jornadas antigas.',
                en: 'Adjust search or period to find older shifts.',
                es: 'Ajusta la busqueda o el periodo para encontrar jornadas antiguas.',
              ),
            ),
          ..._groupedJourneys.map(
            (monthGroup) => _JourneyMonthSection(
              title: monthGroup.label,
              days: monthGroup.days,
              format: format,
              strings: strings,
              onEdit: _openEditDialog,
              onFinish: _finishOpenJourney,
              onDelete: _deleteJourney,
              formatJourneyTitle: _formatJourneyTitle,
              formatDuration: _formatDuration,
              workedDurationFor: _workedDurationFor,
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return OmnyaSubPageScaffold(
      title: strings.journeys,
      heroTagPrefix: 'journeys',
      floatingActions: [
        if (_activeJourney == null)
          OmnyaFabAction(
            label: strings.pick(
              pt: 'Iniciar automatica',
              en: 'Start auto shift',
              es: 'Iniciar automatica',
            ),
            icon: Icons.play_arrow_rounded,
            onTap: _startAutomaticJourney,
          )
        else
          OmnyaFabAction(
            label: strings.pick(
              pt: 'Encerrar jornada',
              en: 'End shift',
              es: 'Cerrar jornada',
            ),
            icon: Icons.stop_rounded,
            onTap: _finishAutomaticJourney,
          ),
        OmnyaFabAction(
          label: strings.newJourney,
          icon: Icons.add,
          onTap: _openCreateDialog,
        ),
      ],
      body: content,
    );
  }

  Future<void> _discardActiveJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Descartar jornada?'),
        content: const Text(
          'Isso remove a jornada em andamento deste aparelho sem salvar no historico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final journeyId = _activeJourney?.journeyId;
    if (journeyId != null && journeyId.trim().isNotEmpty) {
      await _journeyService.deleteJourney(journeyId);
    }
    await _activeJourneyStorage.clear();
    await ActiveJourneyNotificationService.instance.cancelActiveJourney();
    if (!mounted) return;
    setState(() => _activeJourney = null);
    await _loadJourneys();
  }

  String _formatJourneyTitle(AppJourney journey) {
    final end = journey.endedAt;
    final start = journey.startedAt.toLocal();
    final startLabel =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final strings = AppStrings.of(context);
    if (end == null) {
      return strings.pick(
        pt: '$startLabel em andamento',
        en: '$startLabel in progress',
        es: '$startLabel en curso',
      );
    }
    final localEnd = end.toLocal();
    final endLabel =
        '${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}';
    return strings.pick(
      pt: '$startLabel ate $endLabel',
      en: '$startLabel to $endLabel',
      es: '$startLabel a $endLabel',
    );
  }

  List<AppJourney> get _filteredJourneys {
    final query = _searchController.text.trim().toLowerCase();
    return _journeys.where((journey) {
      if (!_isWithinRange(journey.startedAt)) return false;
      if (query.isEmpty) return true;
      final platforms = journey.platformBreakdown
          .map((item) => item.platformName)
          .join(' ');
      final haystack = [
        journey.vehicleLabel,
        journey.notes,
        platforms,
        journey.isFinished ? 'finalizada' : 'em aberto',
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  double get _filteredIncome =>
      _filteredJourneys.fold<double>(0, (sum, item) => sum + item.totalIncome);

  List<_JourneyMonthGroup> get _groupedJourneys {
    final sorted = [..._filteredJourneys]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final monthGroups = <_JourneyMonthGroup>[];

    for (final journey in sorted) {
      final local = journey.startedAt.toLocal();
      final monthLabel = _formatMonth(local);
      final dayKey = DateTime(local.year, local.month, local.day);
      final dayLabel =
          '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';

      _JourneyMonthGroup? monthGroup;
      for (final group in monthGroups) {
        if (group.label == monthLabel) {
          monthGroup = group;
          break;
        }
      }
      if (monthGroup == null) {
        monthGroup = _JourneyMonthGroup(label: monthLabel, days: []);
        monthGroups.add(monthGroup);
      }

      _JourneyDayGroup? dayGroup;
      for (final group in monthGroup.days) {
        if (group.dayKey == dayKey) {
          dayGroup = group;
          break;
        }
      }
      if (dayGroup == null) {
        dayGroup = _JourneyDayGroup(
          dayKey: dayKey,
          label: dayLabel,
          journeys: [],
        );
        monthGroup.days.add(dayGroup);
      }

      dayGroup.journeys.add(journey);
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours <= 0) return '${remaining}min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
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

class _JourneyMonthGroup {
  _JourneyMonthGroup({required this.label, required this.days});

  final String label;
  final List<_JourneyDayGroup> days;
}

class _JourneyDayGroup {
  _JourneyDayGroup({
    required this.dayKey,
    required this.label,
    required this.journeys,
  });

  final DateTime dayKey;
  final String label;
  final List<AppJourney> journeys;

  double get income =>
      journeys.fold<double>(0, (sum, journey) => sum + journey.totalIncome);

  int get deliveries =>
      journeys.fold<int>(0, (sum, journey) => sum + journey.totalDeliveries);

  int get workedMinutes => journeys.fold<int>(
    0,
    (sum, journey) => sum + journey.workedDuration.inMinutes,
  );
}

class _JourneyMonthSection extends StatelessWidget {
  const _JourneyMonthSection({
    required this.title,
    required this.days,
    required this.format,
    required this.strings,
    required this.onEdit,
    required this.onFinish,
    required this.onDelete,
    required this.formatJourneyTitle,
    required this.formatDuration,
    required this.workedDurationFor,
  });

  final String title;
  final List<_JourneyDayGroup> days;
  final AppFormat format;
  final AppStrings strings;
  final ValueChanged<AppJourney> onEdit;
  final ValueChanged<AppJourney> onFinish;
  final ValueChanged<AppJourney> onDelete;
  final String Function(AppJourney journey) formatJourneyTitle;
  final String Function(Duration duration) formatDuration;
  final Duration Function(AppJourney journey) workedDurationFor;

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
                    '${day.label} - ${strings.deliveriesCount(day.deliveries)} | '
                    '${day.journeys.length} ${day.journeys.length == 1 ? strings.pick(pt: 'jornada', en: 'shift', es: 'turno') : strings.journeys.toLowerCase()} | '
                    '${format.currency(day.income)}',
                    style: textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatDuration(Duration(minutes: day.workedMinutes)),
                  style: textTheme.labelLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final journey in day.journeys) ...[
            OmnyaGlassCard(
              padding: const EdgeInsets.all(14),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text(
                  '${day.label} | ${formatJourneyTitle(journey)} | '
                  '${formatDuration(workedDurationFor(journey))} | '
                  '${format.currency(journey.totalIncome)}',
                ),
                subtitle: Text(
                  '${strings.deliveriesCount(journey.totalDeliveries)} • '
                  '${journey.isFinished ? strings.pick(pt: 'Finalizada', en: 'Finished', es: 'Finalizada') : strings.pick(pt: 'Em aberto', en: 'Open', es: 'Abierta')}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'finish') onFinish(journey);
                    if (value == 'edit') onEdit(journey);
                    if (value == 'delete') onDelete(journey);
                  },
                  itemBuilder: (_) => [
                    if (journey.mode == 'automatic' && !journey.isFinished)
                      PopupMenuItem(
                        value: 'finish',
                        child: Text(
                          strings.pick(
                            pt: 'Encerrar jornada',
                            en: 'End shift',
                            es: 'Cerrar jornada',
                          ),
                        ),
                      ),
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
                  if (journey.vehicleLabel != null)
                    _JourneyDetailLine(
                      label: strings.vehicles,
                      value: journey.vehicleLabel!,
                    ),
                  if ((journey.distanceKm ?? 0) > 0)
                    _JourneyDetailLine(
                      label: strings.distance,
                      value:
                          '${(journey.distanceKm ?? 0).toStringAsFixed(1)} km',
                    ),
                  for (final platform in journey.platformBreakdown)
                    _JourneyDetailLine(
                      label: platform.platformName,
                      value:
                          '${format.currency(platform.income)} • ${strings.deliveriesCount(platform.deliveries)}',
                    ),
                  if (journey.notes != null && journey.notes!.trim().isNotEmpty)
                    _JourneyDetailLine(
                      label: strings.pick(
                        pt: 'Observacoes',
                        en: 'Notes',
                        es: 'Notas',
                      ),
                      value: journey.notes!,
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

class _JourneyDetailLine extends StatelessWidget {
  const _JourneyDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActiveJourneyCard extends StatelessWidget {
  const _ActiveJourneyCard({
    required this.draft,
    required this.onFinish,
    required this.onDiscard,
  });

  final ActiveJourneyDraft draft;
  final VoidCallback onFinish;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final startedAt = draft.startedAt.toLocal();
    final elapsed = DateTime.now().difference(draft.startedAt);
    final elapsedLabel = _formatElapsed(elapsed);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF27D17F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jornada em andamento',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onDiscard,
                  child: const Text('Descartar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Comecou hoje as ${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}',
            ),
            Text(
              'Tempo rodando: $elapsedLabel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (draft.vehicleLabel != null) Text(draft.vehicleLabel!),
            if (draft.odometerStart.trim().isNotEmpty)
              Text('Km inicial: ${draft.odometerStart}'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onFinish,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Encerrar e salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours <= 0) return '${remaining}min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
  }
}

class _StartAutomaticJourneyDialog extends StatefulWidget {
  const _StartAutomaticJourneyDialog({required this.vehicles});

  final List<AppVehicle> vehicles;

  @override
  State<_StartAutomaticJourneyDialog> createState() =>
      _StartAutomaticJourneyDialogState();
}

class _StartAutomaticJourneyDialogState
    extends State<_StartAutomaticJourneyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  String? _vehicleId;

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Iniciar jornada'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _vehicleId,
                decoration: const InputDecoration(labelText: 'Veiculo'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sem vincular'),
                  ),
                  ...widget.vehicles.map(
                    (vehicle) => DropdownMenuItem<String?>(
                      value: vehicle.id,
                      child: Text('${vehicle.brand} ${vehicle.model}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _vehicleId = value),
              ),
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(labelText: 'Km inicial'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateDistanceField,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            AppVehicle? vehicle;
            for (final item in widget.vehicles) {
              if (item.id == _vehicleId) {
                vehicle = item;
                break;
              }
            }
            Navigator.of(context).pop(
              ActiveJourneyDraft(
                startedAt: DateTime.now(),
                vehicleId: _vehicleId,
                vehicleLabel: vehicle == null
                    ? null
                    : '${vehicle.brand} ${vehicle.model}',
                odometerStart: _odometerController.text,
              ),
            );
          },
          child: const Text('Comecar'),
        ),
      ],
    );
  }

  String? _validateDistanceField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    if (double.tryParse(normalized) == null) return 'Informe um km valido.';
    return null;
  }
}

class _FinishAutomaticJourneyDialog extends StatefulWidget {
  const _FinishAutomaticJourneyDialog({
    required this.activeJourney,
    required this.platforms,
    required this.onSubmit,
  });

  final ActiveJourneyDraft activeJourney;
  final List<AppPlatform> platforms;
  final Future<void> Function({
    required String odometerEnd,
    required String notes,
    required List<JourneyPlatformDraft> platforms,
  })
  onSubmit;

  @override
  State<_FinishAutomaticJourneyDialog> createState() =>
      _FinishAutomaticJourneyDialogState();
}

class _FinishAutomaticJourneyDialogState
    extends State<_FinishAutomaticJourneyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _odometerEndController = TextEditingController();
  final _notesController = TextEditingController();
  late final List<_PlatformIncomeEntry> _platformEntries;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _platformEntries = widget.platforms.isEmpty
        ? [_PlatformIncomeEntry()]
        : widget.platforms
              .map(
                (platform) => _PlatformIncomeEntry.fromValues(
                  platformId: platform.id,
                  income: '',
                  deliveries: '',
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    _odometerEndController.dispose();
    _notesController.dispose();
    for (final entry in _platformEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 560 ? screenWidth - 32 : 520.0;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Encerrar jornada'),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _odometerEndController,
                  decoration: const InputDecoration(labelText: 'Km final'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateDistanceField,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quanto fez por plataforma?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(
                        () => _platformEntries.add(_PlatformIncomeEntry()),
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                ..._platformEntries.asMap().entries.map(
                  (entry) => _buildPlatformEntry(context, entry.key),
                ),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
                    _errorMessage = null;
                  });
                  try {
                    await widget.onSubmit(
                      odometerEnd: _odometerEndController.text,
                      notes: _notesController.text,
                      platforms: _platformEntries
                          .map(
                            (entry) => JourneyPlatformDraft(
                              platformId: entry.platformId,
                              income: entry.incomeController.text,
                              deliveries: entry.deliveriesController.text,
                            ),
                          )
                          .toList(),
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() {
                      _errorMessage =
                          'Nao consegui salvar agora. Tente de novo.';
                    });
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: const Text('Salvar jornada'),
        ),
      ],
    );
  }

  Widget _buildPlatformEntry(BuildContext context, int index) {
    final entry = _platformEntries[index];
    final platformName = _platformName(entry.platformId);
    final canRemove = _platformEntries.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: platformName == null
                    ? DropdownButtonFormField<String>(
                        initialValue: entry.platformId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Selecionar'),
                          ),
                          ...widget.platforms.map(
                            (platform) => DropdownMenuItem(
                              value: platform.id,
                              child: Text(
                                platform.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => entry.platformId = value ?? ''),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          platformName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () {
                    final removed = _platformEntries.removeAt(index);
                    removed.dispose();
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.incomeController,
                  decoration: const InputDecoration(labelText: 'Ganho'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: entry.deliveriesController,
                  decoration: const InputDecoration(labelText: 'Entregas'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _platformName(String platformId) {
    if (platformId.trim().isEmpty) return null;
    for (final platform in widget.platforms) {
      if (platform.id == platformId) return platform.name;
    }
    return null;
  }

  String? _validateDistanceField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    if (double.tryParse(normalized) == null) return 'Informe um km valido.';
    return null;
  }
}

class _JourneyFormDialog extends StatefulWidget {
  const _JourneyFormDialog({
    this.initialJourney,
    required this.vehicles,
    required this.platforms,
    required this.onSubmit,
  });

  final AppJourney? initialJourney;
  final List<AppVehicle> vehicles;
  final List<AppPlatform> platforms;
  final Future<void> Function({
    required String mode,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String? vehicleId,
    required String odometerStart,
    required String odometerEnd,
    required String notes,
    required List<JourneyPlatformDraft> platforms,
  })
  onSubmit;

  @override
  State<_JourneyFormDialog> createState() => _JourneyFormDialogState();
}

class _JourneyFormDialogState extends State<_JourneyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometerStartController;
  late final TextEditingController _odometerEndController;
  late final TextEditingController _notesController;
  late final List<_PlatformIncomeEntry> _platformEntries;
  late String _mode;
  String? _vehicleId;
  late DateTime _startedAt;
  DateTime? _endedAt;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialJourney = widget.initialJourney;
    _odometerStartController = TextEditingController(
      text: initialJourney?.odometerStart?.toStringAsFixed(1) ?? '',
    );
    _odometerEndController = TextEditingController(
      text: initialJourney?.odometerEnd?.toStringAsFixed(1) ?? '',
    );
    _notesController = TextEditingController(text: initialJourney?.notes ?? '');
    _platformEntries = initialJourney == null
        ? _defaultPlatformEntries()
        : (initialJourney.platformBreakdown.isEmpty
              ? _defaultPlatformEntries()
              : initialJourney.platformBreakdown
                    .map(
                      (item) => _PlatformIncomeEntry.fromValues(
                        platformId: item.platformId ?? '',
                        income: item.income == 0
                            ? ''
                            : item.income.toStringAsFixed(2),
                        deliveries: item.deliveries == 0
                            ? ''
                            : '${item.deliveries}',
                      ),
                    )
                    .toList());
    _mode = initialJourney?.mode == 'quick'
        ? 'manual'
        : (initialJourney?.mode ?? 'manual');
    _vehicleId = initialJourney?.vehicleId;
    _startedAt = initialJourney?.startedAt.toLocal() ?? DateTime.now();
    _endedAt = initialJourney?.endedAt?.toLocal();
  }

  @override
  void dispose() {
    _odometerStartController.dispose();
    _odometerEndController.dispose();
    _notesController.dispose();
    for (final entry in _platformEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewAutomatic =
        widget.initialJourney == null && _mode == 'automatic';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 560 ? screenWidth - 32 : 520.0;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        widget.initialJourney == null ? 'Nova jornada' : 'Editar jornada',
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: const InputDecoration(labelText: 'Modo'),
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual')),
                    DropdownMenuItem(
                      value: 'automatic',
                      child: Text('Automatica'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _mode = value ?? 'manual';
                      if (_mode == 'automatic' &&
                          widget.initialJourney == null) {
                        _endedAt = null;
                        for (final entry in _platformEntries.skip(1).toList()) {
                          entry.dispose();
                        }
                        _platformEntries
                          ..clear()
                          ..add(_PlatformIncomeEntry());
                      }
                      if (_mode == 'manual' &&
                          widget.initialJourney == null &&
                          _platformEntries.length == 1 &&
                          _platformEntries.first.platformId.isEmpty &&
                          widget.platforms.isNotEmpty) {
                        final staleEntries = List<_PlatformIncomeEntry>.from(
                          _platformEntries,
                        );
                        _platformEntries
                          ..clear()
                          ..addAll(_defaultPlatformEntries());
                        for (final entry in staleEntries) {
                          entry.dispose();
                        }
                      }
                    });
                  },
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _vehicleId,
                  decoration: const InputDecoration(labelText: 'Veiculo'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem vincular'),
                    ),
                    ...widget.vehicles.map(
                      (vehicle) => DropdownMenuItem<String?>(
                        value: vehicle.id,
                        child: Text('${vehicle.brand} ${vehicle.model}'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _vehicleId = value),
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  label: 'Inicio',
                  value: _startedAt,
                  onChanged: (value) => setState(() => _startedAt = value),
                ),
                if (!isNewAutomatic)
                  _DateTimeTile(
                    label: 'Fim',
                    value: _endedAt,
                    emptyLabel: 'Em aberto',
                    onChanged: (value) => setState(() => _endedAt = value),
                    onClear: _endedAt == null
                        ? null
                        : () => setState(() => _endedAt = null),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AutomaticJourneyNotice(),
                  ),
                TextFormField(
                  controller: _odometerStartController,
                  decoration: const InputDecoration(labelText: 'Km inicial'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateDistanceField,
                ),
                if (!isNewAutomatic)
                  TextFormField(
                    controller: _odometerEndController,
                    decoration: const InputDecoration(labelText: 'Km final'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateDistanceField,
                  ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (!isNewAutomatic) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Receita por plataforma',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(
                            () => _platformEntries.add(_PlatformIncomeEntry()),
                          );
                        },
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  ..._platformEntries.asMap().entries.map(
                    (entry) => _buildPlatformEntry(context, entry.key),
                  ),
                ],
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
                  if (!isNewAutomatic &&
                      _endedAt != null &&
                      _endedAt!.isBefore(_startedAt)) {
                    setState(() {
                      _submitError =
                          'O horario de fim nao pode ser anterior ao inicio.';
                    });
                    return;
                  }

                  final navigator = Navigator.of(context);
                  setState(() {
                    _saving = true;
                    _submitError = null;
                  });
                  try {
                    await widget.onSubmit(
                      mode: _mode,
                      startedAt: _startedAt,
                      endedAt: isNewAutomatic ? null : _endedAt,
                      vehicleId: _vehicleId,
                      odometerStart: _odometerStartController.text,
                      odometerEnd: isNewAutomatic
                          ? ''
                          : _odometerEndController.text,
                      notes: _notesController.text,
                      platforms: isNewAutomatic
                          ? const <JourneyPlatformDraft>[]
                          : _platformEntries
                                .map(
                                  (entry) => JourneyPlatformDraft(
                                    platformId: entry.platformId,
                                    income: entry.incomeController.text,
                                    deliveries: entry.deliveriesController.text,
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
                          'Nao foi possivel salvar a jornada agora. ${error.toString()}';
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

  List<_PlatformIncomeEntry> _defaultPlatformEntries() {
    if (widget.platforms.isEmpty) return [_PlatformIncomeEntry()];
    return widget.platforms
        .map(
          (platform) => _PlatformIncomeEntry.fromValues(
            platformId: platform.id,
            income: '',
            deliveries: '',
          ),
        )
        .toList();
  }

  String? _platformName(String platformId) {
    if (platformId.isEmpty) return null;
    for (final platform in widget.platforms) {
      if (platform.id == platformId) return platform.name;
    }
    return null;
  }

  Widget _buildPlatformEntry(BuildContext context, int index) {
    final entry = _platformEntries[index];
    final platformName = _platformName(entry.platformId);
    final canRemove = _platformEntries.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: platformName == null
                    ? DropdownButtonFormField<String>(
                        initialValue: entry.platformId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Selecionar'),
                          ),
                          ...widget.platforms.map(
                            (platform) => DropdownMenuItem(
                              value: platform.id,
                              child: Text(
                                platform.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => entry.platformId = value ?? ''),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          platformName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () {
                    final removed = _platformEntries.removeAt(index);
                    removed.dispose();
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.incomeController,
                  decoration: const InputDecoration(labelText: 'Ganho'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: entry.deliveriesController,
                  decoration: const InputDecoration(labelText: 'Entregas'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateDistanceField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return 'Informe um numero valido.';
    }
    return null;
  }
}

class _PlatformIncomeEntry {
  _PlatformIncomeEntry({
    this.platformId = '',
    String income = '',
    String deliveries = '',
  }) : incomeController = TextEditingController(text: income),
       deliveriesController = TextEditingController(text: deliveries);

  factory _PlatformIncomeEntry.fromValues({
    required String platformId,
    required String income,
    required String deliveries,
  }) {
    return _PlatformIncomeEntry(
      platformId: platformId,
      income: income,
      deliveries: deliveries,
    );
  }

  String platformId;
  final TextEditingController incomeController;
  final TextEditingController deliveriesController;

  void dispose() {
    incomeController.dispose();
    deliveriesController.dispose();
  }
}

class _AutomaticJourneyNotice extends StatelessWidget {
  const _AutomaticJourneyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'A jornada automatica fica aberta. Quando encerrar, voce informa km final, entregas e ganhos antes de salvar o fechamento.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.emptyLabel,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final String? emptyLabel;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null
            ? (emptyLabel ?? 'Nao definido')
            : _format(value!.toLocal()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
          const Icon(Icons.calendar_today_outlined),
        ],
      ),
      onTap: () async {
        final now = value ?? DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        );
        if (time == null) return;
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
    );
  }

  String _format(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
