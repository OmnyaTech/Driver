import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class ReferralService {
  ReferralService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  static const _pendingReferralKey = 'driver_pending_referral_slug';
  final AuthService _authService;

  Future<void> captureInitialReferral() async {
    final slug = extractReferralSlug(Uri.base);
    if (slug == null) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingReferralKey, slug);
  }

  Future<void> redeemPendingReferral() async {
    final client = _authService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final preferences = await SharedPreferences.getInstance();
    final slug = preferences.getString(_pendingReferralKey);
    if (slug == null || slug.isEmpty) return;

    try {
      await client
          .schema('driver')
          .rpc('accept_public_referral', params: {'p_referrer_slug': slug});
    } finally {
      await preferences.remove(_pendingReferralKey);
    }
  }

  static String? extractReferralSlug(Uri uri) {
    final fromQuery =
        uri.queryParameters['ref'] ??
        uri.queryParameters['invite'] ??
        uri.queryParameters['indicacao'];
    final querySlug = _cleanSlug(fromQuery);
    if (querySlug != null) return querySlug;

    if (uri.pathSegments.isEmpty) return null;
    final first = uri.pathSegments.first;
    if (first.startsWith('@')) return _cleanSlug(first);
    if (first == 'convite' && uri.pathSegments.length > 1) {
      return _cleanSlug(uri.pathSegments[1]);
    }
    return null;
  }

  static String? _cleanSlug(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
  }
}
