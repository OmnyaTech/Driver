import 'package:url_launcher/url_launcher.dart';

import '../models/app_billing_checkout.dart';
import 'auth_service.dart';

class BillingService {
  BillingService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<AppBillingCheckout> createCheckout({
    required String planType,
    required String billingCycle,
  }) async {
    final client = _authService.requireClient();
    final response = await client.functions.invoke(
      'driver-create-asaas-checkout',
      body: {'planType': planType, 'billingCycle': billingCycle},
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return AppBillingCheckout(
      url: data['url'].toString(),
      provider: data['provider']?.toString() ?? 'asaas',
      planType: data['planType']?.toString() ?? planType,
      billingCycle: data['billingCycle']?.toString() ?? billingCycle,
      externalReference: data['externalReference']?.toString() ?? '',
    );
  }

  Future<bool> openCheckout(AppBillingCheckout checkout) async {
    final uri = Uri.parse(checkout.url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<List<BillingEventItem>> listBillingEvents() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('billing_events')
        .select('id, event_type, status, created_at, external_reference')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return rows
        .map(
          (row) => BillingEventItem(
            id: row['id'].toString(),
            eventType: row['event_type'].toString(),
            status: row['status']?.toString(),
            externalReference: row['external_reference']?.toString(),
            createdAt: DateTime.parse(row['created_at'].toString()),
          ),
        )
        .toList();
  }
}

class BillingEventItem {
  const BillingEventItem({
    required this.id,
    required this.eventType,
    required this.status,
    required this.externalReference,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String? status;
  final String? externalReference;
  final DateTime createdAt;
}
