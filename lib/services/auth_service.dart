import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/oauth_provider_option.dart';

class AuthService {
  const AuthService();

  bool get isAvailable => SupabaseRuntimeConfig.isConfigured;

  SupabaseClient? get client {
    if (!isAvailable) return null;

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession => client?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    final activeClient = _requireClient();
    final response = await activeClient.auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );
    await ensureDriverProfile();
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String captchaToken,
  }) async {
    final activeClient = _requireClient();
    return await activeClient.auth.signUp(
      email: email,
      password: password,
      captchaToken: captchaToken,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: _webEmailRedirectTo,
    );
  }

  Future<void> signInWithOAuth(OauthProviderOption provider) async {
    final activeClient = _requireClient();

    final oauthProvider = switch (provider) {
      OauthProviderOption.google => OAuthProvider.google,
      OauthProviderOption.microsoft => OAuthProvider.azure,
    };

    await activeClient.auth.signInWithOAuth(
      oauthProvider,
      redirectTo: _oauthRedirectTo,
      scopes: provider == OauthProviderOption.google
          ? 'email profile'
          : 'openid profile email',
    );
  }

  Future<void> signOut() async {
    await _requireClient().auth.signOut();
  }

  Future<bool> verifyTurnstileForOAuth({
    required String token,
    required OauthProviderOption provider,
  }) async {
    final activeClient = _requireClient();

    final response = await activeClient.functions.invoke(
      'driver-verify-turnstile',
      body: {
        'token': token,
        'action': 'oauth',
        'provider': provider == OauthProviderOption.google
            ? 'google'
            : 'microsoft',
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['success'] == true;
    }

    return false;
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final activeClient = _requireClient();
    final user = activeClient.auth.currentUser;
    if (user == null) return null;

    final rows = await activeClient
        .schema('driver')
        .from('profiles')
        .select()
        .eq('id', user.id)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> ensureDriverProfile() async {
    final activeClient = _requireClient();
    final user = activeClient.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    final displayName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : (user.email?.split('@').first ?? 'Motorista');
    final payload = {
      'id': user.id,
      'email': user.email,
      'full_name': fullName.isEmpty ? null : fullName,
      'display_name': displayName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final existing = await fetchProfile();

    final avatarUrl = (existing?['avatar_url'] ?? metadata['avatar_url'])
        ?.toString();
    payload['avatar_url'] = avatarUrl;

    if (existing == null) {
      await activeClient.schema('driver').from('profiles').insert(payload);
      return;
    }

    await activeClient
        .schema('driver')
        .from('profiles')
        .update(payload)
        .eq('id', user.id);
  }

  SupabaseClient _requireClient() {
    final activeClient = client;
    if (activeClient == null) {
      throw StateError('Supabase ainda nao esta configurado.');
    }
    return activeClient;
  }

  SupabaseClient requireClient() => _requireClient();

  String get _oauthRedirectTo {
    if (kIsWeb) {
      return Uri.base.resolve('/').toString();
    }

    return 'omnyadriver://auth/callback';
  }

  String get _webEmailRedirectTo {
    if (kIsWeb) {
      return Uri.base.resolve('/').toString();
    }

    return 'omnyadriver://auth/callback';
  }
}
