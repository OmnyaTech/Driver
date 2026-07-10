import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/finance/finance_hub_screen.dart';
import '../funcionalidade/goals/goals_screen.dart';
import '../funcionalidade/journeys/journeys_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/reports/reports_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../models/app_dashboard_metrics.dart';
import '../services/dashboard_metrics_service.dart';
import '../settings/settings_screen.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_shell.dart';
import '../utilities/ui/screen_action_controller.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon.png';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final ScreenActionController _journeyController = ScreenActionController();
  final ScreenActionController _goalController = ScreenActionController();
  final ScreenActionController _expenseController = ScreenActionController();
  final ScreenActionController _fuelingController = ScreenActionController();
  final ScreenActionController _maintenanceController =
      ScreenActionController();

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
    final compactNavigation = MediaQuery.sizeOf(context).width < 720;

    final tabs = [
      _DashboardTab(
        title: 'Visao geral',
        page: _OverviewTab(session: session),
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: compactNavigation ? 'Home' : 'Home',
      ),
      _DashboardTab(
        title: 'Jornadas',
        page: JourneysScreen(
          showCreateButton: false,
          actionController: _journeyController,
          embedded: true,
        ),
        icon: Icons.route_outlined,
        selectedIcon: Icons.route,
        label: compactNavigation ? 'Jorn.' : 'Jornadas',
      ),
      _DashboardTab(
        title: 'Objetivos',
        page: GoalsScreen(
          showCreateButton: false,
          actionController: _goalController,
          embedded: true,
        ),
        icon: Icons.savings_outlined,
        selectedIcon: Icons.savings,
        label: compactNavigation ? 'Metas' : 'Objetivos',
      ),
      _DashboardTab(
        title: 'Financeiro',
        page: FinanceHubScreen(
          expenseController: _expenseController,
          fuelingController: _fuelingController,
          maintenanceController: _maintenanceController,
        ),
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: compactNavigation ? 'Fin.' : 'Financeiro',
      ),
      _DashboardTab(
        title: 'Relatorios',
        page: const ReportsScreen(),
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        label: compactNavigation ? 'Dados' : 'Relatorios',
      ),
      _DashboardTab(
        title: 'Configuracoes',
        page: const SettingsScreen(),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: compactNavigation ? 'Config.' : 'Config.',
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
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Sair',
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
    switch (_currentIndex) {
      case 0:
        return [
          OmnyaFabAction(
            label: 'Nova jornada',
            icon: Icons.route,
            onTap: _journeyController.openCreate,
          ),
          OmnyaFabAction(
            label: 'Novo objetivo',
            icon: Icons.savings,
            onTap: _goalController.openCreate,
          ),
          OmnyaFabAction(
            label: 'Nova despesa',
            icon: Icons.receipt_long,
            onTap: _expenseController.openCreate,
          ),
        ];
      case 1:
        return [
          OmnyaFabAction(
            label: 'Nova jornada',
            icon: Icons.route,
            onTap: _journeyController.openCreate,
          ),
        ];
      case 2:
        return [
          OmnyaFabAction(
            label: 'Novo objetivo',
            icon: Icons.savings,
            onTap: _goalController.openCreate,
          ),
        ];
      case 3:
        return [
          OmnyaFabAction(
            label: 'Nova despesa',
            icon: Icons.receipt_long,
            onTap: _expenseController.openCreate,
          ),
          OmnyaFabAction(
            label: 'Novo abastecimento',
            icon: Icons.local_gas_station,
            onTap: _fuelingController.openCreate,
          ),
          OmnyaFabAction(
            label: 'Nova manutencao',
            icon: Icons.build,
            onTap: _maintenanceController.openCreate,
          ),
        ];
      case 5:
        return [
          OmnyaFabAction(
            label: 'Novo veiculo',
            icon: Icons.two_wheeler,
            onTap: () => _pushManagedCreate(
              (controller) => VehiclesScreen(
                actionController: controller,
                showCreateButton: false,
              ),
            ),
          ),
          OmnyaFabAction(
            label: 'Nova plataforma',
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
  const _OverviewTab({required this.session});

  final AppSession session;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final DashboardMetricsService _metricsService = DashboardMetricsService();
  bool _loading = true;
  AppDashboardMetrics? _metrics;
  String? _errorMessage;
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
      final metrics = await _metricsService.loadMetrics(
        startAt: _range?.start,
        endAt: _range?.end,
      );
      if (!mounted) return;
      setState(() => _metrics = metrics);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao foi possivel consolidar as metricas agora. Tente novamente.';
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics =
        _metrics ??
        const AppDashboardMetrics(
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
                  'Painel OmnyaTech',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_rangeLabel),
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
                        'Visao consolidada',
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
                    _HeroInfoPill(label: profile?.displayName ?? 'Motorista'),
                    _HeroInfoPill(
                      label: 'Plano ${profile?.planType.name ?? 'free'}',
                    ),
                    _HeroInfoPill(label: '${metrics.totalJourneys} jornadas'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Conta: ${profile?.email ?? 'usuario'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liquido atual: ${_currency(metrics.netResult)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricCard(
                title: 'Receita total',
                value: _currency(metrics.totalIncome),
                detail: '${metrics.totalDeliveries} entregas registradas',
              ),
              _MetricCard(
                title: 'Custos operacionais',
                value: _currency(metrics.totalOperationalCosts),
                detail:
                    '${metrics.totalTripExpenses} despesas, ${metrics.totalFuelings} abastecimentos, ${metrics.totalMaintenances} manutencoes',
              ),
              _MetricCard(
                title: 'Resultado liquido',
                value: _currency(metrics.netResult),
                detail: '${metrics.totalJourneys} jornadas no historico',
              ),
              _MetricCard(
                title: 'Saldo disponivel',
                value: _currency(metrics.availableBalance),
                detail:
                    'Reservado em objetivos: ${_currency(metrics.allocatedToGoals)}',
              ),
              _MetricCard(
                title: 'Distancia medida',
                value: '${metrics.totalDistanceKm.toStringAsFixed(1)} km',
                detail: 'Custo por km: ${_currency(metrics.costPerKm)}',
              ),
              _MetricCard(
                title: 'Ticket medio',
                value: _currency(metrics.incomePerDelivery),
                detail: 'por entrega registrada',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leituras rapidas do negocio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('- Jornadas em aberto: ${metrics.openJourneys}'),
                  Text('- Veiculos ativos: ${metrics.activeVehicles}'),
                  Text('- Plataformas ativas: ${metrics.activePlatforms}'),
                  Text(
                    '- Receita media por jornada: ${_currency(metrics.averageIncomePerJourney)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

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

  String get _rangeLabel {
    if (_range == null) return 'Periodo';
    return '${_formatDate(_range!.start)} - ${_formatDate(_range!.end)}';
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(detail),
            ],
          ),
        ),
      ),
    );
  }
}
