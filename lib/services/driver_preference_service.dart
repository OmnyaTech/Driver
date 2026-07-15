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

  Future<void> updateAppPreferences({
    required String languageCode,
    required String currencyCode,
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
          'language_code': _normalizeLanguage(languageCode),
          'currency_code': _normalizeCurrency(currencyCode),
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
      DriverReserveMode.perDeliveryPercent =>
        ((netResult > 0 ? netResult : 0) * (preference.dailyPercentage / 100))
            .toDouble(),
      DriverReserveMode.dailyPercent =>
        ((netResult > 0 ? netResult : 0) * (preference.dailyPercentage / 100))
            .toDouble(),
      DriverReserveMode.weeklyPercent =>
        ((netResult > 0 ? netResult : 0) * (preference.dailyPercentage / 100))
            .toDouble(),
      DriverReserveMode.monthlyPercent =>
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
        DriverReserveMode.none =>
          'Voce deixou a reserva desligada por enquanto.',
        DriverReserveMode.perDeliveryPercent =>
          'Ainda nao houve lucro positivo nesse periodo para separar por entrega.',
        DriverReserveMode.dailyPercent =>
          'Ainda nao houve lucro positivo nesse periodo para separar.',
        DriverReserveMode.weeklyPercent =>
          'Ainda nao houve lucro positivo nessa semana para separar.',
        DriverReserveMode.monthlyPercent =>
          'Ainda nao houve lucro positivo nesse mes para separar.',
        DriverReserveMode.perDeliveryFixed =>
          'Ainda nao tem entregas suficientes nesse periodo para sugerir reserva.',
      };
    }

    return switch (preference.mode) {
      DriverReserveMode.none => 'Voce deixou a reserva desligada por enquanto.',
      DriverReserveMode.perDeliveryPercent =>
        'Esse valor em $periodLabel segue sua regra de guardar ${_percentageLabel(preference.dailyPercentage)}% por entrega.',
      DriverReserveMode.dailyPercent =>
        'Esse valor em $periodLabel segue sua regra de guardar ${_percentageLabel(preference.dailyPercentage)}% por dia.',
      DriverReserveMode.weeklyPercent =>
        'Esse valor em $periodLabel segue sua regra de guardar ${_percentageLabel(preference.dailyPercentage)}% por semana.',
      DriverReserveMode.monthlyPercent =>
        'Esse valor em $periodLabel segue sua regra de guardar ${_percentageLabel(preference.dailyPercentage)}% por mes.',
      DriverReserveMode.perDeliveryFixed =>
        'Esse valor em $periodLabel segue sua regra por entrega concluida.',
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
      'per_delivery_percent' => DriverReserveMode.perDeliveryPercent,
      'per_delivery_fixed' => DriverReserveMode.perDeliveryFixed,
      'weekly_percent' => DriverReserveMode.weeklyPercent,
      'monthly_percent' => DriverReserveMode.monthlyPercent,
      _ => DriverReserveMode.dailyPercent,
    };
  }

  String _modeToDb(DriverReserveMode mode) {
    return switch (mode) {
      DriverReserveMode.none => 'none',
      DriverReserveMode.perDeliveryPercent => 'per_delivery_percent',
      DriverReserveMode.dailyPercent => 'daily_percent',
      DriverReserveMode.weeklyPercent => 'weekly_percent',
      DriverReserveMode.monthlyPercent => 'monthly_percent',
      DriverReserveMode.perDeliveryFixed => 'per_delivery_fixed',
    };
  }

  String _percentageLabel(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  double _parseDouble(Object? value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  String _normalizeLanguage(String value) {
    return switch (value) {
      'en-US' => 'en-US',
      'es-ES' => 'es-ES',
      _ => 'pt-BR',
    };
  }

  String _normalizeCurrency(String value) {
    return switch (value) {
      'USD' => 'USD',
      'EUR' => 'EUR',
      _ => 'BRL',
    };
  }
}
