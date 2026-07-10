import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../models/app_profile.dart';
import '../../models/oauth_provider_option.dart';
import '../../models/plan_type.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';

class AppSession extends ChangeNotifier {
  AppSession({AuthService? authService})
    : _authService = authService ?? const AuthService() {
    _initialize();
  }

  final AuthService _authService;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _authenticated = false;
  bool _isReady = false;
  bool _isBusy = false;
  String? _errorMessage;
  AppProfile? _profile;

  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _authenticated;
  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  AppProfile? get profile => _profile;
  bool get supabaseConfigured => SupabaseRuntimeConfig.isConfigured;

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
      final data = await _authService.fetchProfile();
      _profile = data == null
          ? _fallbackProfile(session.user)
          : _mapProfile(data);
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
      fullName: data['full_name'] as String?,
      phone: data['phone'] as String?,
      role: _parseRole((data['role'] ?? 'user').toString()),
      planType: _parsePlanType((data['plan_type'] ?? 'free').toString()),
      onboardingCompletedAt: _parseDate(data['onboarding_completed_at']),
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
      fullName: fullName,
      phone: metadata['phone']?.toString(),
      role: UserRole.user,
      planType: PlanType.free,
      onboardingCompletedAt: null,
    );
  }
}
