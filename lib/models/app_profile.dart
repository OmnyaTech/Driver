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
    required this.role,
    required this.planType,
    required this.onboardingCompletedAt,
    required this.reservePreference,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final PlanType planType;
  final DateTime? onboardingCompletedAt;
  final DriverReservePreference reservePreference;

  bool get needsOnboarding => onboardingCompletedAt == null;
}
