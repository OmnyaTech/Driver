import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'funcionalidade/onboarding/onboarding_screen.dart';
import 'login/login_screen.dart';
import 'settings/settings_screen.dart';
import 'utilities/state/app_session.dart';

class OmnyaDriverApp extends StatelessWidget {
  const OmnyaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSession(),
      child: Consumer<AppSession>(
        builder: (context, session, _) {
          return MaterialApp(
            title: 'Omnya Driver',
            debugShowCheckedModeBanner: false,
            themeMode: session.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routes: {'/settings': (_) => const SettingsScreen()},
            home: _resolveHome(session),
          );
        },
      ),
    );
  }

  Widget _resolveHome(AppSession session) {
    if (!session.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!session.isAuthenticated) {
      return const LoginScreen();
    }

    if (session.profile?.needsOnboarding ?? true) {
      return const OnboardingScreen();
    }

    return const DashboardScreen();
  }
}
