import 'dart:convert';

import 'auth_service.dart';

class DataPrivacyService {
  DataPrivacyService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<String> buildExportJson() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final export = <String, dynamic>{
      'app': 'Omnya Driver',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': user.id,
      'profile': await _selectProfile(user.id),
      'vehicles': await _selectByUser('vehicles', user.id),
      'platforms': await _selectByUser('platforms', user.id),
      'journeys': await _selectByUser('journeys', user.id),
      'journey_platforms': await _selectVisible('journey_platforms'),
      'trip_expenses': await _selectByUser('trip_expenses', user.id),
      'fuelings': await _selectByUser('fuelings', user.id),
      'maintenances': await _selectByUser('maintenances', user.id),
      'maintenance_items': await _selectVisible('maintenance_items'),
      'goals': await _selectByUser('goals', user.id),
      'goal_transactions': await _selectVisible('goal_transactions'),
      'subscriptions': await _selectByUser('subscriptions', user.id),
      'notifications': await _selectByUser('driver_notifications', user.id),
      'referrals_sent': await _selectByUser(
        'driver_referrals',
        user.id,
        userColumn: 'referrer_user_id',
      ),
      'push_devices': await _selectByUser('driver_push_devices', user.id),
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  Future<void> requestAccountDeletion({required String reason}) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client
        .schema('driver')
        .rpc(
          'request_account_deletion',
          params: {'p_reason': reason.trim().isEmpty ? null : reason.trim()},
        );
  }

  Future<List<dynamic>> _selectProfile(String userId) async {
    return _safeSelect(() {
      return _authService
          .requireClient()
          .schema('driver')
          .from('profiles')
          .select()
          .eq('id', userId);
    });
  }

  Future<List<dynamic>> _selectByUser(
    String table,
    String userId, {
    String userColumn = 'user_id',
  }) async {
    return _safeSelect(() {
      return _authService
          .requireClient()
          .schema('driver')
          .from(table)
          .select()
          .eq(userColumn, userId);
    });
  }

  Future<List<dynamic>> _selectVisible(String table) async {
    return _safeSelect(() {
      return _authService.requireClient().schema('driver').from(table).select();
    });
  }

  Future<List<dynamic>> _safeSelect(Future<dynamic> Function() query) async {
    try {
      final result = await query();
      if (result is List) return result;
      return <dynamic>[result];
    } catch (error) {
      return <dynamic>[
        {'export_error': error.toString()},
      ];
    }
  }
}
