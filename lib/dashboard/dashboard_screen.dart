import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/community/community_hub_screen.dart';
import '../funcionalidade/finance/finance_hub_screen.dart';
import '../funcionalidade/goals/goals_screen.dart';
import '../funcionalidade/journeys/journeys_screen.dart';
import '../funcionalidade/notifications/notifications_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../models/app_dashboard_metrics.dart';
import '../models/app_operational_intelligence.dart';
import '../models/app_operational_report.dart';
import '../services/engagement_notification_service.dart';
import '../services/operational_intelligence_service.dart';
import '../services/reporting_service.dart';
import '../settings/settings_screen.dart';
import '../utilities/localization/app_format.dart';
import '../utilities/localization/app_strings.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_shell.dart';
import '../utilities/ui/omnya_visuals.dart';
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (keyboardOpen) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, compact ? 8 : 10),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF070A12).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: compact ? 34 : 44,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      OmnyaVisualTokens.cyan,
                      OmnyaVisualTokens.electricBlue,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OmnyaVisualTokens.electricBlue.withValues(
                        alpha: 0.45,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final selected = currentIndex == index;
                  final activeColor = isDark
                      ? const Color(0xFF9DA6FF)
                      : OmnyaVisualTokens.omnyaPrimary;
                  final inactiveColor = theme.colorScheme.onSurfaceVariant;

                  return Expanded(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.04 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 11 : 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? const LinearGradient(
                                          colors: [
                                            OmnyaVisualTokens.omnyaPrimaryDark,
                                            OmnyaVisualTokens.electricBlue,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: selected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: OmnyaVisualTokens
                                                .electricBlue
                                                .withValues(alpha: 0.28),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  selected ? tab.selectedIcon : tab.icon,
                                  size: compact ? 18 : 20,
                                  color: selected
                                      ? Colors.white
                                      : inactiveColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                      fontSize: compact ? 9.5 : 10.5,
                                      color: selected
                                          ? activeColor
                                          : inactiveColor,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      letterSpacing: selected ? 0.05 : 0,
                                    ) ??
                                    TextStyle(
                                      fontSize: compact ? 9.5 : 10.5,
                                      color: selected
                                          ? activeColor
                                          : inactiveColor,
                                    ),
                                child: Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
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
  final ReportingService _reportingService = ReportingService();
  bool _loading = true;
  AppOperationalIntelligence? _intelligence;
  AppOperationalReport? _report;
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
      AppOperationalReport? report;
      try {
        report = await _reportingService.loadOperationalReport(
          startAt: intelligence.periodStart,
          endAt: intelligence.periodEnd,
        );
      } catch (_) {
        report = null;
      }
      if (!mounted) return;
      setState(() {
        _intelligence = intelligence;
        _report = report;
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
            workedMinutes: 0,
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
            workedMinutes: 0,
            activeVehicles: 0,
            activePlatforms: 0,
            totalFuelings: 0,
            totalMaintenances: 0,
            totalTripExpenses: 0,
          ),
          trend: const [],
          insights: const [],
          suggestedReserve: 0,
          suggestedReserveLabel: '',
        );
    final metrics = intelligence.currentMetrics;
    final report = _report;

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 520 ? 16 : 22,
          20,
          MediaQuery.sizeOf(context).width < 520 ? 16 : 22,
          120,
        ),
        children: [
          _DashboardSectionHeader(
            title: strings.yourDayInApp,
            action: _preset == OperationalRangePreset.custom
                ? OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_rangeLabel),
                  )
                : null,
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
          OmnyaAnimatedEntrance(
            child: _OperationalHero(
              logoAsset: _driverLogoAsset,
              title: strings.periodSummary(_periodDisplayLabel),
              driverName: profile?.displayName ?? strings.driverFallback,
              planLabel: strings.planLabel(profile?.planType.name ?? 'free'),
              journeyLabel: strings.journeysCount(metrics.totalJourneys),
              accountLabel:
                  '${strings.account}: ${profile?.email ?? strings.userFallback}',
              netLabel: strings.currentNet,
              netValue: _currency(metrics.netResult),
              deltaLabel: strings.incomeDelta(
                _formatDelta(intelligence.incomeDeltaPct()),
              ),
              stats: [
                _HeroStat(
                  label: strings.income,
                  value: _currency(metrics.totalIncome),
                  icon: Icons.trending_up,
                ),
                _HeroStat(
                  label: strings.costs,
                  value: _currency(metrics.totalOperationalCosts),
                  icon: Icons.trending_down,
                ),
                _HeroStat(
                  label: strings.deliveries,
                  value: '${metrics.totalDeliveries}',
                  icon: Icons.inventory_2_outlined,
                ),
                _HeroStat(
                  label: strings.distance,
                  value: '${metrics.totalDistanceKm.toStringAsFixed(1)} km',
                  icon: Icons.speed_outlined,
                ),
                _HeroStat(
                  label: strings.pick(pt: 'Tempo', en: 'Time', es: 'Tiempo'),
                  value: _formatWorkedTime(metrics.workedMinutes),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            OmnyaGlassCard(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 18),
          OmnyaAnimatedEntrance(
            delay: const Duration(milliseconds: 80),
            child: OmnyaGlassCard(
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
                      Tooltip(
                        message:
                            'Mostra a receita por dia no periodo selecionado. A legenda indica datas resumidas para caber melhor no celular.',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _periodDisplayLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ChartLegendDot(
                        color: const Color(0xFF4E63FF),
                        label: strings.pick(
                          pt: 'Receita por dia',
                          en: 'Daily income',
                          es: 'Ingresos por dia',
                        ),
                      ),
                      Text(
                        strings.pick(
                          pt: 'Periodo: $_periodDisplayLabel',
                          en: 'Period: $_periodDisplayLabel',
                          es: 'Periodo: $_periodDisplayLabel',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 132,
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
          if (report != null) ...[
            _HomeReportCards(report: report, currency: _currency),
            const SizedBox(height: 18),
          ],
          _MetricGrid(
            metrics: [
              _MetricData(
                title: strings.income,
                value: _currency(metrics.totalIncome),
                detail: _deltaLabel(
                  intelligence.incomeDeltaPct(),
                  strings.deliveriesCount(metrics.totalDeliveries),
                ),
                icon: Icons.payments_outlined,
              ),
              _MetricData(
                title: strings.pick(
                  pt: 'Reservado',
                  en: 'Reserved',
                  es: 'Reservado',
                ),
                value: _currency(intelligence.suggestedReserve),
                detail: intelligence.suggestedReserveLabel.isEmpty
                    ? strings.pick(
                        pt: 'conforme sua regra',
                        en: 'by your rule',
                        es: 'segun tu regla',
                      )
                    : intelligence.suggestedReserveLabel,
                icon: Icons.savings_outlined,
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
                icon: Icons.local_shipping_outlined,
              ),
              _MetricData(
                title: strings.leftOver,
                value: _currency(metrics.netResult),
                detail: _deltaLabel(
                  intelligence.netDeltaPct(),
                  strings.journeysCount(metrics.totalJourneys),
                ),
                icon: Icons.account_balance_wallet_outlined,
              ),
              _MetricData(
                title: strings.costs,
                value: _currency(metrics.totalOperationalCosts),
                detail: strings.launchesCount(
                  metrics.totalTripExpenses +
                      metrics.totalFuelings +
                      metrics.totalMaintenances,
                ),
                icon: Icons.receipt_long_outlined,
              ),
              _MetricData(
                title: strings.distance,
                value: '${metrics.totalDistanceKm.toStringAsFixed(1)} km',
                detail: '${strings.costPerKm} ${_currency(metrics.costPerKm)}',
                icon: Icons.route_outlined,
              ),
              _MetricData(
                title: strings.pick(
                  pt: 'Tempo trabalhado',
                  en: 'Time worked',
                  es: 'Tiempo trabajado',
                ),
                value: _formatWorkedTime(metrics.workedMinutes),
                detail: strings.pick(
                  pt: 'somado no periodo',
                  en: 'total in period',
                  es: 'total del periodo',
                ),
                icon: Icons.timer_outlined,
              ),
              _MetricData(
                title: strings.pick(
                  pt: 'Valor/hora',
                  en: 'Hourly value',
                  es: 'Valor/hora',
                ),
                value: _currency(metrics.incomePerHour),
                detail: strings.pick(
                  pt: 'media do periodo',
                  en: 'period average',
                  es: 'promedio del periodo',
                ),
                icon: Icons.speed_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InsightBoard(intelligence: intelligence),
        ],
      ),
    );
  }

  String _currency(double value) => AppFormat.of(context).currency(value);

  String _formatWorkedTime(int minutes) {
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final hours = safeMinutes ~/ 60;
    final remaining = safeMinutes % 60;
    if (hours <= 0) return '${remaining}min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
  }

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

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}

class _HeroStat {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _OperationalHero extends StatelessWidget {
  const _OperationalHero({
    required this.logoAsset,
    required this.title,
    required this.driverName,
    required this.planLabel,
    required this.journeyLabel,
    required this.accountLabel,
    required this.netLabel,
    required this.netValue,
    required this.deltaLabel,
    required this.stats,
  });

  final String logoAsset;
  final String title;
  final String driverName;
  final String planLabel;
  final String journeyLabel;
  final String accountLabel;
  final String netLabel;
  final String netValue;
  final String deltaLabel;
  final List<_HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OmnyaHeroCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(logoAsset, width: 42, height: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroInfoPill(label: driverName),
                  _HeroInfoPill(label: planLabel),
                  _HeroInfoPill(label: journeyLabel),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                accountLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$netLabel: $netValue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deltaLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          );
          final statGrid = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats
                .map(
                  (stat) => SizedBox(
                    width: compact ? (constraints.maxWidth - 10) / 2 : 148,
                    child: _HeroStatTile(stat: stat),
                  ),
                )
                .toList(),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 20), statGrid],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: summary),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: statGrid),
            ],
          );
        },
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.stat});

  final _HeroStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: OmnyaVisualTokens.cyan, size: 18),
          const SizedBox(height: 18),
          Text(
            stat.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.detail,
    this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData? icon;
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
    return OmnyaMetricTile(
      title: metric.title,
      value: metric.value,
      detail: metric.detail,
      icon: metric.icon,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLabels = constraints.maxWidth < 420 ? 5 : 8;
        final step = (points.length / maxLabels).ceil().clamp(1, points.length);
        return CustomPaint(
          painter: _SparklinePainter(
            values: points.map((item) => item.value).toList(),
            color: const Color(0xFF4E63FF),
            gridColor: Theme.of(context).dividerColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final showLabel =
                  index == 0 || index == points.length - 1 || index % step == 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 98),
                  child: Text(
                    showLabel ? _compactTrendLabel(point.label) : '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _compactTrendLabel(String label) {
    final parts = label.split('/');
    if (parts.length >= 2) return '${parts[0]}/${parts[1]}';
    return label.length > 5 ? label.substring(0, 5) : label;
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
        previousLabel: format.currency(previous.totalIncome),
        noMovementLabel: strings.noMovement,
        newMovementLabel: strings.newMovement,
      ),
      _ComparisonItem(
        label: strings.deliveries,
        current: current.totalDeliveries.toDouble(),
        previous: previous.totalDeliveries.toDouble(),
        valueLabel: '${current.totalDeliveries}',
        previousLabel: '${previous.totalDeliveries}',
        noMovementLabel: strings.noMovement,
        newMovementLabel: strings.newMovement,
      ),
    ];

    return OmnyaGlassCard(
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
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HomeReportCards extends StatelessWidget {
  const _HomeReportCards({required this.report, required this.currency});

  final AppOperationalReport report;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FinancialPulseCard(report: report, currency: currency),
        const SizedBox(height: 18),
        _PlatformRankingCard(items: report.topPlatforms, currency: currency),
        const SizedBox(height: 18),
        _CostMapCard(items: report.expenseBreakdown, currency: currency),
      ],
    );
  }
}

class _FinancialPulseCard extends StatelessWidget {
  const _FinancialPulseCard({required this.report, required this.currency});

  final AppOperationalReport report;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final maxValue = [
      report.totalIncome.abs(),
      report.totalOperationalCosts.abs(),
      1.0,
    ].reduce(math.max);
    final items = [
      _DashboardBarData(
        strings.income,
        report.totalIncome,
        const Color(0xFF39E58C),
      ),
      _DashboardBarData(
        strings.costs,
        report.totalOperationalCosts,
        const Color(0xFFFF6F6F),
      ),
    ];

    return OmnyaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.pick(
              pt: 'Pulso financeiro',
              en: 'Financial pulse',
              es: 'Pulso financiero',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            strings.pick(
              pt: 'Receita e despesas gerais do periodo para acompanhar a evolucao anual.',
              en: 'Income and expenses for the period to follow yearly movement.',
              es: 'Ingresos y gastos del periodo para seguir el movimiento anual.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              currency(item.value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: (item.value.abs() / maxValue).clamp(
                                      0.08,
                                      1.0,
                                    ),
                                  ),
                                  duration: const Duration(milliseconds: 650),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, heightFactor, child) {
                                    return FractionallySizedBox(
                                      heightFactor: heightFactor,
                                      child: child,
                                    );
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          item.color.withValues(alpha: 0.35),
                                          item.color,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: const SizedBox(width: 44),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(item.label),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRankingCard extends StatelessWidget {
  const _PlatformRankingCard({required this.items, required this.currency});

  final List<PlatformPerformance> items;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final maxIncome = items.isEmpty
        ? 1.0
        : items
              .map((item) => item.income)
              .reduce(math.max)
              .clamp(1.0, double.infinity);

    return OmnyaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plataformas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            strings.pick(
              pt: 'Ranking por valor recebido e quantidade de entregas no periodo.',
              en: 'Ranking by amount received and deliveries in the period.',
              es: 'Ranking por valor recibido y entregas en el periodo.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              strings.pick(
                pt: 'Nenhuma plataforma com movimento neste periodo.',
                en: 'No platform movement in this period.',
                es: 'Sin movimiento de plataformas en este periodo.',
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            return _DashboardProgressRow(
              label: '#${entry.key + 1} ${item.platformName}',
              detail: strings.deliveriesCount(item.deliveries),
              value: currency(item.income),
              factor: (item.income / maxIncome).clamp(0.04, 1.0),
            );
          }),
        ],
      ),
    );
  }
}

class _CostMapCard extends StatelessWidget {
  const _CostMapCard({required this.items, required this.currency});

  final List<ExpenseBreakdownItem> items;
  final String Function(double value) currency;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final total = items
        .fold<double>(0, (sum, item) => sum + item.amount)
        .clamp(1.0, double.infinity);

    return OmnyaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa de custos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            strings.pick(
              pt: 'Compare onde o dinheiro saiu: despesas de jornada, abastecimento ou manutencao.',
              en: 'Compare where money went: trip expenses, fuel or maintenance.',
              es: 'Compara donde salio el dinero: gastos, combustible o mantenimiento.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              strings.pick(
                pt: 'Nenhum custo registrado neste periodo.',
                en: 'No costs recorded in this period.',
                es: 'Sin costos registrados en este periodo.',
              ),
            ),
          ...items.map((item) {
            final pct = ((item.amount / total) * 100).toStringAsFixed(0);
            return _DashboardProgressRow(
              label: item.label,
              detail: '$pct% dos custos',
              value: currency(item.amount),
              factor: (item.amount / total).clamp(0.04, 1.0),
            );
          }),
        ],
      ),
    );
  }
}

class _DashboardBarData {
  const _DashboardBarData(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _DashboardProgressRow extends StatelessWidget {
  const _DashboardProgressRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.factor,
  });

  final String label;
  final String detail;
  final String value;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.28),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
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
    required this.previousLabel,
    required this.noMovementLabel,
    required this.newMovementLabel,
  });

  final String label;
  final double current;
  final double previous;
  final String valueLabel;
  final String previousLabel;
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
                  '${strings.before}: ${item.previousLabel}',
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
    final strings = AppStrings.of(context);
    final insights = intelligence.insights.isNotEmpty
        ? intelligence.insights
        : [
            OperationalInsight(
              title: strings.pick(
                pt: 'Sem base suficiente',
                en: 'Not enough data yet',
                es: 'Sin datos suficientes',
              ),
              value: strings.pick(
                pt: 'Comece hoje',
                en: 'Start today',
                es: 'Empieza hoy',
              ),
              description: strings.pick(
                pt: 'Registre jornadas e fontes de receita para liberar dicas reais da sua rotina.',
                en: 'Log shifts and income sources to unlock real tips from your routine.',
                es: 'Registra turnos e ingresos para desbloquear consejos reales de tu rutina.',
              ),
            ),
            OperationalInsight(
              title: strings.pick(
                pt: 'Melhor horario',
                en: 'Best hour',
                es: 'Mejor horario',
              ),
              value: strings.pick(
                pt: 'Em analise',
                en: 'In review',
                es: 'En analisis',
              ),
              description: strings.pick(
                pt: 'Com alguns dias de uso, o app mostra onde seu tempo rende mais.',
                en: 'After a few days, the app shows where your time pays better.',
                es: 'Con unos dias de uso, la app muestra donde tu tiempo rinde mas.',
              ),
            ),
            OperationalInsight(
              title: strings.pick(
                pt: 'Plataforma forte',
                en: 'Strong platform',
                es: 'Plataforma fuerte',
              ),
              value: strings.pick(
                pt: 'Aguardando',
                en: 'Waiting',
                es: 'Esperando',
              ),
              description: strings.pick(
                pt: 'Compare apps, lojas e fontes para decidir onde vale ficar online.',
                en: 'Compare apps, stores and sources to decide where to stay online.',
                es: 'Compara apps, tiendas y fuentes para decidir donde conectarte.',
              ),
            ),
          ];

    return OmnyaGlassCard(
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
              final columns = constraints.maxWidth < 520
                  ? 1
                  : constraints.maxWidth < 900
                  ? 2
                  : 4;
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: insights
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
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final OperationalInsight insight;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      padding: const EdgeInsets.all(16),
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
