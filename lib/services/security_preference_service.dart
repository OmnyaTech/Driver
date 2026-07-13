import 'auth_service.dart';

class SecurityPreferenceService {
  SecurityPreferenceService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<void> updateLockPreferences({
    required bool biometricLockEnabled,
    required int inactivityLockMinutes,
    required bool reauthOnResume,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client
        .schema('driver')
        .from('profiles')
        .update({
          'biometric_lock_enabled': biometricLockEnabled,
          'inactivity_lock_minutes': inactivityLockMinutes,
          'reauth_on_resume': reauthOnResume,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }
}
