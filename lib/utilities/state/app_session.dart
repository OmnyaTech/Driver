import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../models/app_profile.dart';
import '../../models/driver_reserve_preference.dart';
import '../../models/oauth_provider_option.dart';
import '../../models/plan_type.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/referral_service.dart';

class AppSession extends ChangeNotifier {
  AppSession({
    AuthService? authService,
    ReferralService? referralService,
    DeepLinkService? deepLinkService,
    PushNotificationService? pushNotificationService,
  }) : _authService = authService ?? const AuthService(),
       _referralService = referralService ?? ReferralService(),
       _deepLinkService = deepLinkService ?? DeepLinkService(),
       _pushNotificationService =
           pushNotificationService ?? PushNotificationService() {
    _initialize();
  }

  final AuthService _authService;
  final ReferralService _referralService;
  final DeepLinkService _deepLinkService;
  final PushNotificationService _pushNotificationService;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _authenticated = false;
  bool _isReady = false;
  bool _isBusy = false;
  String? _errorMessage;
  AppProfile? _profile;

  ThemeMode get themeMode => _themeMode;
  Locale get locale {
    return switch (_profile?.languageCode) {
      'en-US' => const Locale('en', 'US'),
      'es-ES' => const Locale('es', 'ES'),
      _ => const Locale('pt', 'BR'),
    };
  }

  bool get isAuthenticated => _authenticated;
  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  AppProfile? get profile => _profile;
  bool get supabaseConfigured => SupabaseRuntimeConfig.isConfigured;

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _authService.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
      await _refreshFromSession();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel entrar agora.';
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String captchaToken,
  }) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        captchaToken: captchaToken,
      );
      await _refreshFromSession();
      return response;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Nao foi possivel criar a conta agora.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signInWithOAuth(
    OauthProviderOption provider, {
    required String verificationToken,
  }) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      final verified = await _authService.verifyTurnstileForOAuth(
        token: verificationToken,
        provider: provider,
      );
      if (!verified) {
        _errorMessage = 'Nao foi possivel validar a verificacao de seguranca.';
        return false;
      }

      await _authService.signInWithOAuth(provider);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Nao foi possivel iniciar o login social.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
      _profile = null;
      _authenticated = false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _initialize() async {
    await _referralService.captureInitialReferral();
    await _deepLinkService.start(
      onReferralCaptured: () async {
        await _referralService.redeemPendingReferral();
        await refreshProfile();
      },
    );

    if (!_authService.isAvailable) {
      _isReady = true;
      notifyListeners();
      return;
    }

    _authService.authStateChanges.listen((_) async {
      await _refreshFromSession();
    });

    await _refreshFromSession();
    _isReady = true;
    notifyListeners();
  }

  Future<void> _refreshFromSession() async {
    final session = _authService.currentSession;
    _authenticated = session != null;

    if (session == null) {
      _profile = null;
      notifyListeners();
      return;
    }

    try {
      await _authService.ensureDriverProfile();
      await _referralService.redeemPendingReferral();
      final data = await _authService.fetchProfile();
      _profile = data == null
          ? _fallbackProfile(session.user)
          : _mapProfile(data);
      await _pushNotificationService.registerDeviceIfPossible();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Falha ao carregar o perfil do motorista.';
      _profile = _fallbackProfile(session.user);
    }

    notifyListeners();
  }

  AppProfile _mapProfile(Map<String, dynamic> data) {
    return AppProfile(
      id: data['id'].toString(),
      email: (data['email'] ?? '').toString(),
      displayName: (data['display_name'] ?? data['full_name'] ?? 'Motorista')
          .toString(),
      avatarUrl: data['avatar_url'] as String?,
      fullName: data['full_name'] as String?,
      phone: data['phone'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      role: _parseRole((data['role'] ?? 'user').toString()),
      planType: _parsePlanType((data['plan_type'] ?? 'free').toString()),
      onboardingCompletedAt: _parseDate(data['onboarding_completed_at']),
      languageCode: (data['language_code'] ?? 'pt-BR').toString(),
      currencyCode: (data['currency_code'] ?? 'BRL').toString(),
      biometricLockEnabled: data['biometric_lock_enabled'] as bool? ?? false,
      inactivityLockMinutes: _parseInt(
        data['inactivity_lock_minutes'],
        fallback: 15,
      ),
      reauthOnResume: data['reauth_on_resume'] as bool? ?? true,
      totpMfaEnabled: data['totp_mfa_enabled'] as bool? ?? false,
      reservePreference: DriverReservePreference(
        mode: _parseReserveMode(
          (data['reserve_mode'] ?? 'daily_percent').toString(),
        ),
        dailyPercentage: _parseDouble(data['reserve_percentage'], fallback: 30),
        amountPerDelivery: _parseDouble(
          data['reserve_amount_per_delivery'],
          fallback: 0,
        ),
      ),
    );
  }

  UserRole _parseRole(String raw) {
    return raw == 'developer' ? UserRole.developer : UserRole.user;
  }

  PlanType _parsePlanType(String raw) {
    return switch (raw) {
      'premium' => PlanType.premium,
      'gift' => PlanType.gift,
      'lifetime' => PlanType.lifetime,
      'developer' => PlanType.developer,
      _ => PlanType.free,
    };
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<void> refreshProfile() async {
    await _refreshFromSession();
  }

  AppProfile _fallbackProfile(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? metadata['name'])?.toString();
    final displayName = fullName?.trim().isNotEmpty == true
        ? fullName!.trim().split(' ').first
        : (user.email?.split('@').first ?? 'Motorista');

    return AppProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      avatarUrl: metadata['avatar_url']?.toString(),
      fullName: fullName,
      phone: metadata['phone']?.toString(),
      city: null,
      state: null,
      country: 'Brasil',
      role: UserRole.user,
      planType: PlanType.free,
      onboardingCompletedAt: null,
      languageCode: 'pt-BR',
      currencyCode: 'BRL',
      biometricLockEnabled: false,
      inactivityLockMinutes: 15,
      reauthOnResume: true,
      totpMfaEnabled: false,
      reservePreference: const DriverReservePreference(
        mode: DriverReserveMode.dailyPercent,
        dailyPercentage: 30,
        amountPerDelivery: 0,
      ),
    );
  }

  DriverReserveMode _parseReserveMode(String raw) {
    return switch (raw) {
      'none' => DriverReserveMode.none,
      'per_delivery_fixed' => DriverReserveMode.perDeliveryFixed,
      _ => DriverReserveMode.dailyPercent,
    };
  }

  double _parseDouble(Object? value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _parseInt(Object? value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
