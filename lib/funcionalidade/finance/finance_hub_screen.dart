import 'package:flutter/material.dart';

import '../../utilities/localization/app_strings.dart';
import '../../utilities/ui/omnya_visuals.dart';
import '../../utilities/ui/screen_action_controller.dart';
import '../expenses/trip_expenses_screen.dart';
import '../fuelings/fuelings_screen.dart';
import '../maintenances/maintenances_screen.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({
    super.key,
    required this.expenseController,
    required this.fuelingController,
    required this.maintenanceController,
  });

  final ScreenActionController expenseController;
  final ScreenActionController fuelingController;
  final ScreenActionController maintenanceController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          OmnyaAnimatedEntrance(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: OmnyaGlassCard(
                padding: const EdgeInsets.all(5),
                borderRadius: 28,
                highlight: true,
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.receipt_long_rounded),
                      text: strings.pick(
                        pt: 'Despesas',
                        en: 'Expenses',
                        es: 'Gastos',
                      ),
                    ),
                    Tab(
                      icon: const Icon(Icons.local_gas_station_rounded),
                      text: strings.pick(
                        pt: 'Abastecer',
                        en: 'Fuel',
                        es: 'Combustible',
                      ),
                    ),
                    Tab(
                      icon: const Icon(Icons.build_circle_rounded),
                      text: strings.pick(
                        pt: 'Manutencao',
                        en: 'Maintenance',
                        es: 'Mantenimiento',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                TripExpensesScreen(
                  showCreateButton: false,
                  actionController: expenseController,
                  embedded: true,
                ),
                FuelingsScreen(
                  showCreateButton: false,
                  actionController: fuelingController,
                  embedded: true,
                ),
                MaintenancesScreen(
                  showCreateButton: false,
                  actionController: maintenanceController,
                  embedded: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
