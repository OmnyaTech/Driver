import 'plan_type.dart';
import 'driver_reserve_preference.dart';
import 'user_role.dart';

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.state,
    required this.country,
    required this.role,
    required this.planType,
    required this.onboardingCompletedAt,
    required this.reservePreference,
    required this.languageCode,
    required this.currencyCode,
    required this.biometricLockEnabled,
    required this.inactivityLockMinutes,
    required this.reauthOnResume,
    required this.totpMfaEnabled,
    required this.totpMfaFactorId,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? fullName;
  final String? phone;
  final String? city;
  final String? state;
  final String? country;
  final UserRole role;
  final PlanType planType;
  final DateTime? onboardingCompletedAt;
  final DriverReservePreference reservePreference;
  final String languageCode;
  final String currencyCode;
  final bool biometricLockEnabled;
  final int inactivityLockMinutes;
  final bool reauthOnResume;
  final bool totpMfaEnabled;
  final String? totpMfaFactorId;

  bool get needsOnboarding => onboardingCompletedAt == null;

  String get languageLabel {
    return switch (languageCode) {
      'en-US' => 'English',
      'es-ES' => 'Espanol',
      _ => 'Portugues',
    };
  }

  String get currencyLabel {
    return switch (currencyCode) {
      'USD' => 'Dolar americano',
      'EUR' => 'Euro',
      _ => 'Real brasileiro',
    };
  }
}
