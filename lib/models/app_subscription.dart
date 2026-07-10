class AppSubscription {
  const AppSubscription({
    required this.id,
    required this.planType,
    required this.status,
    required this.provider,
    required this.startedAt,
    required this.expiresAt,
    required this.cancelledAt,
    required this.giftedBy,
  });

  final String id;
  final String planType;
  final String status;
  final String? provider;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final String? giftedBy;
}

class AdminAccessProfile {
  const AdminAccessProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.role,
    required this.planType,
    required this.subscriptionStatus,
    required this.onboardingCompletedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? fullName;
  final String role;
  final String planType;
  final String subscriptionStatus;
  final DateTime? onboardingCompletedAt;
}
