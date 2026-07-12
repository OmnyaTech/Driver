import '../models/app_subscription.dart';
import 'auth_service.dart';

class SubscriptionService {
  SubscriptionService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppSubscription>> listCurrentUserSubscriptions() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => AppSubscription(
            id: row['id'].toString(),
            planType: row['plan_type'].toString(),
            status: row['status'].toString(),
            provider: row['provider'] as String?,
            startedAt: _parseDate(row['started_at']),
            expiresAt: _parseDate(row['expires_at']),
            cancelledAt: _parseDate(row['cancelled_at']),
            giftedBy: row['gifted_by']?.toString(),
            externalReference: row['external_reference']?.toString(),
          ),
        )
        .toList();
  }

  AppSubscription? currentSubscription(List<AppSubscription> subscriptions) {
    for (final subscription in subscriptions) {
      if (subscription.isCurrent && subscription.cancelledAt == null) {
        return subscription;
      }
    }
    return subscriptions.isEmpty ? null : subscriptions.first;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
