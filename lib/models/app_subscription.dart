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
    required this.externalReference,
  });

  final String id;
  final String planType;
  final String status;
  final String? provider;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final String? giftedBy;
  final String? externalReference;

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isActive {
    final normalizedStatus = status.toLowerCase();
    final normalizedPlan = planType.toLowerCase();
    return ['active', 'gifted'].contains(normalizedStatus) &&
        ['premium', 'gift', 'lifetime', 'developer'].contains(normalizedPlan);
  }

  bool get isCurrent {
    final normalizedStatus = status.toLowerCase();
    return [
      'pending',
      'active',
      'gifted',
      'overdue',
    ].contains(normalizedStatus);
  }
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
