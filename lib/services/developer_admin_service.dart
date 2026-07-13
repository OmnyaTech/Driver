import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_admin_audit_log.dart';
import '../models/app_subscription.dart';
import 'auth_service.dart';

class DeveloperAdminService {
  DeveloperAdminService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<AdminAccessProfile?> lookupProfileByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('admin_lookup_profile', params: {'p_email': normalized});

    if (response is! List || response.isEmpty) return null;
    final row = Map<String, dynamic>.from(response.first as Map);
    return AdminAccessProfile(
      id: row['id'].toString(),
      email: row['email'].toString(),
      displayName: row['display_name'] as String?,
      fullName: row['full_name'] as String?,
      role: row['role'].toString(),
      planType: row['plan_type'].toString(),
      subscriptionStatus: row['subscription_status'].toString(),
      onboardingCompletedAt: _parseDate(row['onboarding_completed_at']),
    );
  }

  Future<String> grantAccess({
    required String email,
    required String planType,
    required String role,
    DateTime? expiresAt,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw PostgrestException(message: 'Informe um e-mail valido.');
    }

    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc(
          'admin_grant_access',
          params: {
            'p_email': normalized,
            'p_plan_type': planType,
            'p_role': role,
            'p_expires_at': expiresAt?.toUtc().toIso8601String(),
          },
        );

    if (response is Map<String, dynamic>) {
      return (response['message'] ?? 'Acesso atualizado com sucesso.')
          .toString();
    }

    return 'Acesso atualizado com sucesso.';
  }

  Future<List<AppAdminAuditLog>> listAuditLogs({int limit = 50}) async {
    final client = _authService.requireClient();
    final response = await client
        .schema('driver')
        .rpc('admin_list_audit_logs', params: {'p_limit': limit});

    if (response is! List) return const [];

    return response
        .map(
          (row) => AppAdminAuditLog(
            id: row['id'].toString(),
            action: row['action'].toString(),
            summary: row['summary'] as String?,
            actorEmail: row['actor_email'] as String?,
            targetEmail: row['target_email'] as String?,
            createdAt: DateTime.parse(row['created_at'].toString()),
            metadata: row['metadata'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(row['metadata'] as Map)
                : const <String, dynamic>{},
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> loadMetrics() async {
    final client = _authService.requireClient();
    final metricsResponse = await client
        .schema('driver')
        .rpc('get_developer_metrics');
    final metrics = Map<String, dynamic>.from(
      (metricsResponse as Map?) ?? const {},
    );

    try {
      final analyticsResponse = await client
          .schema('driver')
          .rpc('get_product_analytics_summary');
      metrics['product_events'] = Map<String, dynamic>.from(
        (analyticsResponse as Map?) ?? const {},
      );
    } catch (_) {
      metrics['product_events'] = const <String, dynamic>{};
    }

    return metrics;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
