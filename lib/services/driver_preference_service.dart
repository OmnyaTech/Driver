import '../models/driver_reserve_preference.dart';
import 'auth_service.dart';

class DriverPreferenceService {
  DriverPreferenceService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<DriverReservePreference> loadReservePreference() async {
    final profile = await _authService.fetchProfile();
    if (profile == null) {
      return _fallbackPreference();
    }

    return mapPreference(profile);
  }

  Future<void> updateReservePreference({
    required DriverReserveMode mode,
    required double dailyPercentage,
    required double amountPerDelivery,
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
          'reserve_mode': _modeToDb(mode),
          'reserve_percentage': dailyPercentage.clamp(0, 100),
          'reserve_amount_per_delivery': amountPerDelivery < 0
              ? 0
              : amountPerDelivery,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  DriverReservePreference mapPreference(Map<String, dynamic> data) {
    return DriverReservePreference(
      mode: _modeFromDb(data['reserve_mode']?.toString()),
      dailyPercentage: _parseDouble(data['reserve_percentage'], fallback: 30),
      amountPerDelivery: _parseDouble(
        data['reserve_amount_per_delivery'],
        fallback: 0,
      ),
    );
  }

  double calculateSuggestedReserve({
    required DriverReservePreference preference,
    required double netResult,
    required int deliveries,
  }) {
    return switch (preference.mode) {
      DriverReserveMode.none => 0,
      DriverReserveMode.dailyPercent =>
        ((netResult > 0 ? netResult : 0) * (preference.dailyPercentage / 100))
            .toDouble(),
      DriverReserveMode.perDeliveryFixed =>
        (deliveries * preference.amountPerDelivery).toDouble(),
    };
  }

  String buildSuggestionLabel({
    required DriverReservePreference preference,
    required double amount,
    required String periodLabel,
  }) {
    if (amount <= 0) {
      return switch (preference.mode) {
        DriverReserveMode.none => 'Reserva automatica desativada por enquanto.',
        DriverReserveMode.dailyPercent =>
          'Sem reserva sugerida porque o liquido do periodo ainda nao ficou positivo.',
        DriverReserveMode.perDeliveryFixed =>
          'Sem reserva sugerida porque ainda nao houve entregas suficientes no periodo.',
      };
    }

    return switch (preference.mode) {
      DriverReserveMode.none => 'Reserva automatica desativada por enquanto.',
      DriverReserveMode.dailyPercent =>
        'Separar R\$ ${amount.toStringAsFixed(2)} em $periodLabel segue sua regra de ${preference.dailyPercentage.toStringAsFixed(preference.dailyPercentage.truncateToDouble() == preference.dailyPercentage ? 0 : 1)}% do liquido.',
      DriverReserveMode.perDeliveryFixed =>
        'Separar R\$ ${amount.toStringAsFixed(2)} em $periodLabel segue sua regra de R\$ ${preference.amountPerDelivery.toStringAsFixed(2)} por entrega.',
    };
  }

  DriverReservePreference _fallbackPreference() {
    return const DriverReservePreference(
      mode: DriverReserveMode.dailyPercent,
      dailyPercentage: 30,
      amountPerDelivery: 0,
    );
  }

  DriverReserveMode _modeFromDb(String? value) {
    return switch (value) {
      'none' => DriverReserveMode.none,
      'per_delivery_fixed' => DriverReserveMode.perDeliveryFixed,
      _ => DriverReserveMode.dailyPercent,
    };
  }

  String _modeToDb(DriverReserveMode mode) {
    return switch (mode) {
      DriverReserveMode.none => 'none',
      DriverReserveMode.dailyPercent => 'daily_percent',
      DriverReserveMode.perDeliveryFixed => 'per_delivery_fixed',
    };
  }

  double _parseDouble(Object? value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}
