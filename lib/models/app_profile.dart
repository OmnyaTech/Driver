import 'plan_type.dart';
import 'user_role.dart';

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.planType,
    required this.onboardingCompletedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final PlanType planType;
  final DateTime? onboardingCompletedAt;

  bool get needsOnboarding => onboardingCompletedAt == null;
}
