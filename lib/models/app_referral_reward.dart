class AppReferralReward {
  const AppReferralReward({
    required this.id,
    required this.referredUserId,
    required this.referredDisplayName,
    required this.rewardXp,
    required this.acceptedAt,
    this.referredAvatarUrl,
  });

  final String id;
  final String referredUserId;
  final String referredDisplayName;
  final String? referredAvatarUrl;
  final int rewardXp;
  final DateTime? acceptedAt;

  factory AppReferralReward.fromMap(Map<String, dynamic> data) {
    return AppReferralReward(
      id: data['referral_id'].toString(),
      referredUserId: data['referred_user_id'].toString(),
      referredDisplayName:
          (data['referred_display_name'] ?? 'Entregador indicado').toString(),
      referredAvatarUrl: data['referred_avatar_url'] as String?,
      rewardXp: _parseInt(data['reward_xp']),
      acceptedAt: DateTime.tryParse((data['accepted_at'] ?? '').toString()),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
