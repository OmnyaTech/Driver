class AppGiftAccess {
  const AppGiftAccess({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.planType,
    required this.subscriptionStatus,
    required this.giftedAt,
    required this.expiresAt,
    required this.giftedByEmail,
    required this.isActiveGift,
    required this.isExpired,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? fullName;
  final String planType;
  final String subscriptionStatus;
  final DateTime? giftedAt;
  final DateTime? expiresAt;
  final String? giftedByEmail;
  final bool isActiveGift;
  final bool isExpired;

  String get nameLabel {
    final label = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : fullName?.trim();
    return label?.isNotEmpty == true ? label! : email;
  }
}
