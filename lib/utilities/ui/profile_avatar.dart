import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.radius = 28,
    this.showBorder = false,
  });

  final String displayName;
  final String? avatarUrl;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final normalized = avatarUrl?.trim();
    final hasAvatar = normalized != null && normalized.isNotEmpty;

    return Container(
      padding: showBorder ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.16))
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF0000CD).withValues(alpha: 0.18),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundImage: hasAvatar ? NetworkImage(normalized) : null,
        child: hasAvatar
            ? null
            : Text(
                _initial(displayName),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  String _initial(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'O';
    return normalized[0].toUpperCase();
  }
}
