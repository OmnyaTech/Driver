import '../services/auth_service.dart';

class ProfileService {
  ProfileService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<void> updateProfile({
    required String displayName,
    String? fullName,
    String? phone,
    String? city,
    String? state,
    String? country,
    bool completeOnboarding = false,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'display_name': displayName.trim(),
      'full_name': _normalizeString(fullName),
      'phone': _normalizeString(phone),
      if (completeOnboarding)
        'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (city != null) payload['city'] = _normalizeString(city);
    if (state != null) payload['state'] = _normalizeString(state);
    if (country != null) {
      payload['country'] = _normalizeString(country) ?? 'Brasil';
    }

    final existing = await client
        .schema('driver')
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .limit(1);

    if (existing.isEmpty) {
      await client.schema('driver').from('profiles').insert(payload);
      return;
    }

    await client
        .schema('driver')
        .from('profiles')
        .update(payload)
        .eq('id', user.id);
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }
}
