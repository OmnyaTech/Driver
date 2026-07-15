import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'funcionalidade/onboarding/onboarding_screen.dart';
import 'landing/driver_landing_screen.dart';
import 'login/login_screen.dart';
import 'settings/settings_screen.dart';
import 'utilities/platform/android_permission_bootstrap.dart';
import 'utilities/security/app_security_gate.dart';
import 'utilities/state/app_session.dart';
import 'utilities/version/app_version_gate.dart';

class OmnyaDriverApp extends StatelessWidget {
  const OmnyaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSession(),
      child: Consumer<AppSession>(
        builder: (context, session, _) {
          return MaterialApp(
            title: 'Driver',
            debugShowCheckedModeBanner: false,
            locale: session.locale,
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: session.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routes: {'/settings': (_) => const SettingsStandaloneScreen()},
            home: AndroidPermissionBootstrap(
              child: AppVersionGate(child: _resolveHome(session)),
            ),
          );
        },
      ),
    );
  }

  Widget _resolveHome(AppSession session) {
    if (shouldShowPublicLanding()) {
      final inviteSlug = inviteSlugFromCurrentUri();
      if (Uri.base.path == '/download' || Uri.base.path == '/cadastro') {
        return DriverDownloadGateScreen(inviteSlug: inviteSlug);
      }
      return DriverLandingScreen(inviteSlug: inviteSlug);
    }

    if (!session.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!session.isAuthenticated) {
      return const LoginScreen();
    }

    if (session.profile?.needsOnboarding ?? true) {
      return const OnboardingScreen();
    }

    return const AppSecurityGate(child: DashboardScreen());
  }
}
