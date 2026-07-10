import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/developer/developer_access_screen.dart';
import '../funcionalidade/expenses/trip_expenses_screen.dart';
import '../funcionalidade/fuelings/fuelings_screen.dart';
import '../funcionalidade/journeys/journeys_screen.dart';
import '../funcionalidade/maintenances/maintenances_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/reports/reports_screen.dart';
import '../funcionalidade/subscriptions/subscriptions_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../models/app_dashboard_metrics.dart';
import '../services/dashboard_metrics_service.dart';
import '../utilities/guards/developer_guard.dart';
import '../utilities/state/app_session.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DeveloperGuard _developerGuard = DeveloperGuard();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final canOpenDeveloper = session.profile != null
        ? _developerGuard.canOpen(session.profile!.role)
        : false;

    final tabs = [
      _DashboardTab(
        title: 'Visao geral',
        page: _OverviewTab(session: session),
        destination: const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
      ),
      _DashboardTab(
        title: 'Jornadas',
        page: const JourneysScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route),
          label: 'Jornadas',
        ),
      ),
      _DashboardTab(
        title: 'Despesas',
        page: const TripExpensesScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Despesas',
        ),
      ),
      _DashboardTab(
        title: 'Abastecimentos',
        page: const FuelingsScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.local_gas_station_outlined),
          selectedIcon: Icon(Icons.local_gas_station),
          label: 'Abastec.',
        ),
      ),
      _DashboardTab(
        title: 'Manutencoes',
        page: const MaintenancesScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build),
          label: 'Manut.',
        ),
      ),
      _DashboardTab(
        title: 'Veiculos',
        page: const VehiclesScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.two_wheeler_outlined),
          selectedIcon: Icon(Icons.two_wheeler),
          label: 'Veiculos',
        ),
      ),
      _DashboardTab(
        title: 'Plataformas',
        page: const PlatformsScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Plataformas',
        ),
      ),
      _DashboardTab(
        title: 'Relatorios',
        page: const ReportsScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Relatorios',
        ),
      ),
      _DashboardTab(
        title: 'Planos',
        page: const SubscriptionsScreen(),
        destination: const NavigationDestination(
          icon: Icon(Icons.workspace_premium_outlined),
          selectedIcon: Icon(Icons.workspace_premium),
          label: 'Planos',
        ),
      ),
      if (canOpenDeveloper)
        _DashboardTab(
          title: 'Developer',
          page: const DeveloperAccessScreen(),
          destination: const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Developer',
          ),
        ),
    ];

    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_currentIndex].title),
        actions: [
          IconButton(
            onPressed: session.isBusy ? null : session.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: tabs.map((tab) => tab.destination).toList(),
      ),
    );
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.title,
    required this.page,
    required this.destination,
  });

  final String title;
  final Widget page;
  final NavigationDestination destination;
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

    final metrics = _metrics ??
        const AppDashboardMetrics(
          totalIncome: 0,
          totalOperationalCosts: 0,
          netResult: 0,
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
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Visao consolidada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_rangeLabel),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _range == null
                    ? null
                    : () {
                        setState(() => _range = null);
                        _loadMetrics();
                      },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel operacional',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('Conta: ${profile?.email ?? 'usuario'}'),
                  Text('Nome: ${profile?.displayName ?? 'Motorista'}'),
                  Text('Plano: ${profile?.planType.name ?? 'free'}'),
                  Text('Papel: ${profile?.role.name ?? 'user'}'),
                  Text(
                    'Onboarding: ${profile?.needsOnboarding == false ? 'concluido' : 'pendente'}',
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
                title: 'Distancia medida',
                value: '${metrics.totalDistanceKm.toStringAsFixed(1)} km',
                detail:
                    'Custo por km: ${_currency(metrics.costPerKm)}',
              ),
              _MetricCard(
                title: 'Produtividade',
                value: metrics.averageDeliveriesPerJourney.toStringAsFixed(1),
                detail: 'entregas por jornada',
              ),
              _MetricCard(
                title: 'Ticket medio',
                value: _currency(metrics.incomePerDelivery),
                detail: 'por entrega registrada',
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
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
