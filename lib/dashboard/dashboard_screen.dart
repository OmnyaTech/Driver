import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/community/community_hub_screen.dart';
import '../funcionalidade/finance/finance_hub_screen.dart';
import '../funcionalidade/gamification/gamification_screen.dart';
import '../funcionalidade/goals/goals_screen.dart';
import '../funcionalidade/journeys/journeys_screen.dart';
import '../funcionalidade/notifications/notifications_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../models/app_dashboard_metrics.dart';
import '../models/app_gamification.dart';
import '../models/app_operational_intelligence.dart';
import '../services/engagement_notification_service.dart';
import '../services/gamification_service.dart';
import '../services/operational_intelligence_service.dart';
import '../settings/settings_screen.dart';
import '../utilities/localization/app_format.dart';
import '../utilities/localization/app_strings.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_shell.dart';
import '../utilities/ui/screen_action_controller.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EngagementNotificationService _notificationService =
      EngagementNotificationService();
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  final ScreenActionController _journeyController = ScreenActionController();
  final ScreenActionController _goalController = ScreenActionController();
  final ScreenActionController _expenseController = ScreenActionController();
  final ScreenActionController _fuelingController = ScreenActionController();
  final ScreenActionController _maintenanceController =
      ScreenActionController();

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _journeyController.clear();
    _goalController.clear();
    _expenseController.clear();
    _fuelingController.clear();
    _maintenanceController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final strings = AppStrings.of(context);
    final compactNavigation = MediaQuery.sizeOf(context).width < 720;

    final tabs = [
      _DashboardTab(
        title: strings.overview,
        page: _OverviewTab(
          session: session,
          onNotificationsChanged: _loadUnreadNotifications,
        ),
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: strings.home,
      ),
      _DashboardTab(
        title: strings.journeys,
        page: JourneysScreen(
          showCreateButton: false,
          actionController: _journeyController,
          embedded: true,
        ),
        icon: Icons.route_outlined,
        selectedIcon: Icons.route,
        label: compactNavigation ? strings.journeysShort : strings.journeys,
      ),
      _DashboardTab(
        title: strings.goals,
        page: GoalsScreen(
          showCreateButton: false,
          actionController: _goalController,
          embedded: true,
        ),
        icon: Icons.savings_outlined,
        selectedIcon: Icons.savings,
        label: compactNavigation ? strings.goalsShort : strings.goals,
      ),
      _DashboardTab(
        title: strings.finance,
        page: FinanceHubScreen(
          expenseController: _expenseController,
          fuelingController: _fuelingController,
          maintenanceController: _maintenanceController,
        ),
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: compactNavigation ? strings.financeShort : strings.finance,
      ),
      _DashboardTab(
        title: strings.community,
        page: const CommunityHubScreen(),
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: compactNavigation ? 'Social' : strings.community,
      ),
      _DashboardTab(
        title: strings.settingsTitle,
        page: const SettingsScreen(),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: strings.settingsShort,
      ),
    ];

    final actions = _buildFabActions();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(_driverLogoAsset, width: 26, height: 26),
            const SizedBox(width: 10),
            Text(tabs[_currentIndex].title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.alertsTooltip,
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: strings.signOutTooltip,
              onPressed: session.isBusy ? null : session.signOut,
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: OmnyaPageBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs.map((tab) => tab.page).toList(),
        ),
      ),
      floatingActionButton: actions.isEmpty
          ? null
          : OmnyaFloatingActionMenu(
              actions: actions,
              heroTagPrefix: 'dashboard',
            ),
      bottomNavigationBar: _OmnyaBottomTabBar(
        currentIndex: _currentIndex,
        compact: compactNavigation,
        tabs: tabs,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  List<OmnyaFabAction> _buildFabActions() {
    final strings = AppStrings.of(context);
    switch (_currentIndex) {
      case 0:
        return [
          OmnyaFabAction(
            label: strings.newJourney,
            icon: Icons.route,
            onTap: _journeyController.openCreate,
          ),
          OmnyaFabAction(
            label: strings.newGoal,
            icon: Icons.savings,
            onTap: _goalController.openCreate,
          ),
          OmnyaFabAction(
            label: strings.newExpense,
            icon: Icons.receipt_long,
            onTap: _expenseController.openCreate,
          ),
        ];
      case 1:
        return [
          OmnyaFabAction(
            label: strings.newJourney,
            icon: Icons.route,
            onTap: _journeyController.openCreate,
          ),
        ];
      case 2:
        return [
          OmnyaFabAction(
            label: strings.newGoal,
            icon: Icons.savings,
            onTap: _goalController.openCreate,
          ),
        ];
      case 3:
        return [
          OmnyaFabAction(
            label: strings.newExpense,
            icon: Icons.receipt_long,
            onTap: _expenseController.openCreate,
          ),
          OmnyaFabAction(
            label: strings.newFueling,
            icon: Icons.local_gas_station,
            onTap: _fuelingController.openCreate,
          ),
          OmnyaFabAction(
            label: strings.newMaintenance,
            icon: Icons.build,
            onTap: _maintenanceController.openCreate,
          ),
        ];
      case 5:
        return [
          OmnyaFabAction(
            label: strings.newVehicle,
            icon: Icons.two_wheeler,
            onTap: () => _pushManagedCreate(
              (controller) => VehiclesScreen(
                actionController: controller,
                showCreateButton: false,
              ),
            ),
          ),
          OmnyaFabAction(
            label: strings.newPlatform,
            icon: Icons.storefront,
            onTap: () => _pushManagedCreate(
              (controller) => PlatformsScreen(
                actionController: controller,
                showCreateButton: false,
              ),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  Future<void> _pushManagedCreate(
    Widget Function(ScreenActionController controller) builder,
  ) async {
    final controller = ScreenActionController();
    final future = Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => builder(controller)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openCreate();
    });
    await future;
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      await _notificationService.syncSmartNotifications();
      final unread = await _notificationService.unreadCount();
      if (!mounted) return;
      setState(() => _unreadNotifications = unread);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadNotifications = 0);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    await _loadUnreadNotifications();
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.title,
    required this.page,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String title;
  final Widget page;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _OmnyaBottomTabBar extends StatelessWidget {
  const _OmnyaBottomTabBar({
    required this.currentIndex,
    required this.compact,
    required this.tabs,
    required this.onSelected,
  });

  final int currentIndex;
  final bool compact;
  final List<_DashboardTab> tabs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, compact ? 8 : 10),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final selected = currentIndex == index;
              final activeColor = const Color(0xFF7582FF);
              final inactiveColor = theme.colorScheme.onSurfaceVariant;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(
                                    0xFF0000CD,
                                  ).withValues(alpha: isDark ? 0.32 : 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            selected ? tab.selectedIcon : tab.icon,
                            size: compact ? 19 : 21,
                            color: selected ? activeColor : inactiveColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: compact ? 10 : 11,
                            color: selected
                                ? theme.colorScheme.onSurface
                                : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({
    required this.session,
    required this.onNotificationsChanged,
  });

  final AppSession session;
  final Future<void> Function() onNotificationsChanged;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final OperationalIntelligenceService _intelligenceService =
      OperationalIntelligenceService();
  final GamificationService _gamificationService = GamificationService();
  bool _loading = true;
  AppOperationalIntelligence? _intelligence;
  AppGamificationSummary? _gamification;
  String? _errorMessage;
  OperationalRangePreset _preset = OperationalRangePreset.today;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final intelligence = await _intelligenceService.load(
        preset: _preset,
        customRange: _range,
      );
      final gamification = await _gamificationService.loadSummary();
      if (!mounted) return;
      setState(() {
        _intelligence = intelligence;
        _gamification = gamification;
      });
      await widget.onNotificationsChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao consegui atualizar seus numeros agora. Tente de novo em instantes.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile;
    final strings = AppStrings.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final intelligence =
        _intelligence ??
        AppOperationalIntelligence(
          periodLabel: strings.today,
          periodStart: DateTime.now(),
          periodEnd: DateTime.now(),
          currentMetrics: const AppDashboardMetrics(
            totalIncome: 0,
            totalOperationalCosts: 0,
            netResult: 0,
            allocatedToGoals: 0,
            availableBalance: 0,
            totalJourneys: 0,
            openJourneys: 0,
            totalDeliveries: 0,
            totalDistanceKm: 0,
            activeVehicles: 0,
            activePlatforms: 0,
            totalFuelings: 0,
            totalMaintenances: 0,
            totalTripExpenses: 0,
          ),
          previousMetrics: const AppDashboardMetrics(
            totalIncome: 0,
            totalOperationalCosts: 0,
            netResult: 0,
            allocatedToGoals: 0,
            availableBalance: 0,
            totalJourneys: 0,
            openJourneys: 0,
            totalDeliveries: 0,
            totalDistanceKm: 0,
            activeVehicles: 0,
            activePlatforms: 0,
            totalFuelings: 0,
            totalMaintenances: 0,
            totalTripExpenses: 0,
          ),
          trend: const [],
          insights: const [],
          suggestedReserve: 0,
          suggestedReserveLabel: strings.pick(
            pt: 'Sem reserva sugerida agora',
            en: 'No reserve suggestion right now',
            es: 'Sin sugerencia de reserva ahora',
          ),
        );
    final metrics = intelligence.currentMetrics;
    final gamification =
        _gamification ??
        const AppGamificationSummary(
          xp: 0,
          level: 1,
          levelTitle: 'Motorista iniciante',
          nextLevelXp: 250,
          currentStreakDays: 0,
          bestStreakDays: 0,
          medalsCount: 0,
          rankingOptIn: false,
          publicScore: 0,
          records: AppDriverRecords(
            bestFridayDate: null,
            highestRevenueDayDate: null,
            highestProfitPerHourStartedAt: null,
            highestDeliveriesDayDate: null,
            highestDeliveriesCount: 0,
          ),
          medals: [],
        );

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.yourDayInApp,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_preset == OperationalRangePreset.custom)
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(_rangeLabel),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RangeChip(
                label: strings.today,
                selected: _preset == OperationalRangePreset.today,
                onTap: () => _changePreset(OperationalRangePreset.today),
              ),
              _RangeChip(
                label: strings.week,
                selected: _preset == OperationalRangePreset.week,
                onTap: () => _changePreset(OperationalRangePreset.week),
              ),
              _RangeChip(
                label: strings.month,
                selected: _preset == OperationalRangePreset.month,
                onTap: () => _changePreset(OperationalRangePreset.month),
              ),
              _RangeChip(
                label: _preset == OperationalRangePreset.custom
                    ? _rangeLabel
                    : strings.custom,
                selected: _preset == OperationalRangePreset.custom,
                onTap: () async {
                  setState(() => _preset = OperationalRangePreset.custom);
                  await _pickRange();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0B0D16),
                  Color(0xFF111B35),
                  Color(0xFF0000CD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0000CD).withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(_driverLogoAsset, width: 40, height: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.periodSummary(_periodDisplayLabel),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroInfoPill(
                      label: profile?.displayName ?? strings.driverFallback,
                    ),
                    _HeroInfoPill(
                      label: strings.planLabel(
                        profile?.planType.name ?? 'free',
                      ),
                    ),
                    _HeroInfoPill(
                      label: strings.journeysCount(metrics.totalJourneys),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${strings.account}: ${profile?.email ?? strings.userFallback}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${strings.currentNet}: ${_currency(metrics.netResult)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.incomeDelta(
                    _formatDelta(intelligence.incomeDeltaPct()),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
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
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.moneyFlow,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _periodDisplayLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 96,
                    child: _SparklineChart(points: intelligence.trend),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ComparisonBoard(
            current: metrics,
            previous: intelligence.previousMetrics,
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricData(
                title: strings.income,
                value: _currency(metrics.totalIncome),
                detail: _deltaLabel(
                  intelligence.incomeDeltaPct(),
                  strings.deliveriesCount(metrics.totalDeliveries),
                ),
              ),
              _MetricData(
                title: strings.leftOver,
                value: _currency(metrics.netResult),
                detail: _deltaLabel(
                  intelligence.netDeltaPct(),
                  strings.journeysCount(metrics.totalJourneys),
                ),
              ),
              _MetricData(
                title: strings.deliveries,
                value: '${metrics.totalDeliveries}',
                detail: _deltaLabel(
                  intelligence.deliveryDeltaPct(),
                  strings.perJourney(
                    metrics.averageDeliveriesPerJourney.toStringAsFixed(1),
                  ),
                ),
              ),
              _MetricData(
                title: strings.freeBalance,
                value: _currency(metrics.availableBalance),
                detail:
                    '${strings.goalsDetail} ${_currency(metrics.allocatedToGoals)}',
              ),
              _MetricData(
                title: strings.costs,
                value: _currency(metrics.totalOperationalCosts),
                detail: strings.launchesCount(
                  metrics.totalTripExpenses +
                      metrics.totalFuelings +
                      metrics.totalMaintenances,
                ),
              ),
              _MetricData(
                title: strings.distance,
                value: '${metrics.totalDistanceKm.toStringAsFixed(1)} km',
                detail: '${strings.costPerKm} ${_currency(metrics.costPerKm)}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InsightBoard(intelligence: intelligence),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 840;
              final children = [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.saveForLater,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currency(intelligence.suggestedReserve),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(intelligence.suggestedReserveLabel),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!vertical)
                  const SizedBox(width: 12)
                else
                  const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.yourProgress,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            strings.level(gamification.level),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.xpAndAchievements(
                              gamification.xp,
                              gamification.medalsCount,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const GamificationScreen(),
                                  ),
                                ),
                                child: Text(strings.viewProgress),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CommunityHubScreen(),
                                  ),
                                ),
                                child: Text(strings.community),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];

              return vertical
                  ? Column(children: children)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    );
            },
          ),
        ],
      ),
    );
  }

  String _currency(double value) => AppFormat.of(context).currency(value);

  String get _periodDisplayLabel {
    final strings = AppStrings.of(context);
    return switch (_preset) {
      OperationalRangePreset.today => strings.today,
      OperationalRangePreset.week => strings.week,
      OperationalRangePreset.month => strings.month,
      OperationalRangePreset.custom => _rangeLabel,
    };
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange:
          _range ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _loadMetrics();
  }

  Future<void> _changePreset(OperationalRangePreset preset) async {
    setState(() => _preset = preset);
    await _loadMetrics();
  }

  String get _rangeLabel {
    if (_range == null) return AppStrings.of(context).period;
    return '${_formatDate(_range!.start)} - ${_formatDate(_range!.end)}';
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDelta(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(0)}%';
  }

  String _deltaLabel(double delta, String fallback) {
    return AppStrings.of(context).deltaLabel(delta, fallback);
  }
}

class _HeroInfoPill extends StatelessWidget {
  const _HeroInfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 460
            ? 2
            : width < 900
            ? 3
            : 6;
        final spacing = width < 460 ? 10.0 : 14.0;
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.title, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(metric.value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              Text(metric.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0000CD).withValues(alpha: 0.18)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF0000CD)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.points});

  final List<OperationalTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(child: Text(AppStrings.of(context).notEnoughHistory));
    }

    return CustomPaint(
      painter: _SparklinePainter(
        values: points.map((item) => item.value).toList(),
        color: const Color(0xFF4E63FF),
        gridColor: Theme.of(context).dividerColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points
            .map(
              (point) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 72),
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ComparisonBoard extends StatelessWidget {
  const _ComparisonBoard({required this.current, required this.previous});

  final AppDashboardMetrics current;
  final AppDashboardMetrics previous;

  @override
  Widget build(BuildContext context) {
    final format = AppFormat.of(context);
    final strings = AppStrings.of(context);
    final items = [
      _ComparisonItem(
        label: strings.income,
        current: current.totalIncome,
        previous: previous.totalIncome,
        valueLabel: format.currency(current.totalIncome),
        noMovementLabel: strings.noMovement,
        newMovementLabel: strings.newMovement,
      ),
      _ComparisonItem(
        label: strings.leftOver,
        current: current.netResult,
        previous: previous.netResult,
        valueLabel: format.currency(current.netResult),
        noMovementLabel: strings.noMovement,
        newMovementLabel: strings.newMovement,
      ),
      _ComparisonItem(
        label: strings.deliveries,
        current: current.totalDeliveries.toDouble(),
        previous: previous.totalDeliveries.toDouble(),
        valueLabel: '${current.totalDeliveries}',
        noMovementLabel: strings.noMovement,
        newMovementLabel: strings.newMovement,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.periodComparison,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ...items.map((item) => _ComparisonRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ComparisonItem {
  const _ComparisonItem({
    required this.label,
    required this.current,
    required this.previous,
    required this.valueLabel,
    required this.noMovementLabel,
    required this.newMovementLabel,
  });

  final String label;
  final double current;
  final double previous;
  final String valueLabel;
  final String noMovementLabel;
  final String newMovementLabel;

  double get ratio {
    final maxValue = [
      current.abs(),
      previous.abs(),
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    return (current.abs() / maxValue).clamp(0.06, 1);
  }

  String get deltaLabel {
    if (previous.abs() < 0.001) {
      return current.abs() < 0.001 ? noMovementLabel : newMovementLabel;
    }
    final delta = ((current - previous) / previous.abs()) * 100;
    final prefix = delta >= 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(0)}%';
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.item});

  final _ComparisonItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(item.label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.ratio,
                    minHeight: 9,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.32),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${strings.before}: ${item.previous.toStringAsFixed(item.label == strings.deliveries ? 0 : 2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.valueLabel, style: theme.textTheme.labelLarge),
                Text(item.deltaLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.35), color],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i <= 3; i++) {
      final y = (size.height - 26) * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length < 2) return;
    final max = values
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min).abs() < 0.001 ? 1.0 : (max - min);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (size.width / (values.length - 1)) * i;
      final normalized = (values[i] - min) / range;
      final y = ((size.height - 34) * (1 - normalized)) + 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor;
  }
}

class _InsightBoard extends StatelessWidget {
  const _InsightBoard({required this.intelligence});

  final AppOperationalIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.of(context).performanceTips,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 720 ? 2 : 4;
                final spacing = 12.0;
                final itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: intelligence.insights
                      .map(
                        (insight) => SizedBox(
                          width: itemWidth,
                          child: _InsightCard(insight: insight),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final OperationalInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Text(insight.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
