import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_public_driver.dart';
import '../../services/public_profile_service.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/profile_avatar.dart';

class PublicDriverProfileScreen extends StatefulWidget {
  const PublicDriverProfileScreen({super.key, required this.slug});

  final String slug;

  @override
  State<PublicDriverProfileScreen> createState() =>
      _PublicDriverProfileScreenState();
}

class _PublicDriverProfileScreenState extends State<PublicDriverProfileScreen> {
  final PublicProfileService _service = PublicProfileService();
  bool _loading = true;
  AppPublicDriverProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _service.loadPublicProfile(widget.slug);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Perfil',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const OmnyaSubPageScaffold(
        title: 'Perfil',
        body: Center(child: Text('Esse perfil nao esta disponivel.')),
      );
    }
    final bannerValue = profile.publicBannerUrl?.trim();
    final bannerColor = _tryBannerColor(bannerValue) ?? const Color(0xFF001BFF);
    final bannerIsImage = _isRemoteBanner(bannerValue);
    final tierColors = _tierColors(profile.tier);

    return OmnyaSubPageScaffold(
      title: 'Perfil',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              image: bannerIsImage
                  ? DecorationImage(
                      image: NetworkImage(bannerValue!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    )
                  : null,
              gradient: bannerIsImage
                  ? null
                  : LinearGradient(
                      colors: [
                        const Color(0xFF111522),
                        bannerColor.withValues(alpha: 0.52),
                        bannerColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileAvatar(
                      displayName: profile.displayName,
                      avatarUrl: profile.avatarUrl,
                      radius: 28,
                      showBorder: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.publicSlug}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          if ((profile.publicTitle ?? '').isNotEmpty)
                            Text(
                              profile.publicTitle!,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PublicPill(label: '#${profile.publicScore} pts'),
                    _PublicPill(label: profile.levelTitle),
                    _PublicPill(
                      label: 'Liga ${profile.tier}',
                      background: tierColors.background,
                      foreground: tierColors.foreground,
                      border: tierColors.border,
                    ),
                    _PublicPill(label: '${profile.medalsCount} conquistas'),
                  ],
                ),
                if ((profile.publicBio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    profile.publicBio!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            'Me encontre no Omnya Driver: @${profile.publicSlug}\n${PublicProfileService.buildInviteUrl(profile.publicSlug)}',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado.')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Copiar link'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PublicStatCard(
                  title: 'Nivel',
                  value: '${profile.level}',
                  subtitle: profile.levelTitle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PublicStatCard(
                  title: 'Melhor sequencia',
                  value: '${profile.bestStreakDays} dias',
                  subtitle: 'Ritmo maximo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PublicStatCard(
                  title: 'Entregas',
                  value: '${profile.totalDeliveries}',
                  subtitle: 'total publico',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PublicStatCard(
                  title: 'No app ha',
                  value: '${profile.accountDays} dias',
                  subtitle: 'jornada com Driver',
                ),
              ),
            ],
          ),
          if (profile.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badges em destaque',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conquistas escolhidas pelo entregador para aparecer no perfil.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profile.badges
                          .map((badge) => _PublicBadgePill(label: badge))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Melhores marcas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _PublicRecordRow(
                    label: 'Melhor sexta',
                    value: _format(profile.bestFridayDate),
                  ),
                  _PublicRecordRow(
                    label: 'Melhor dia',
                    value: _format(profile.highestRevenueDayDate),
                  ),
                  _PublicRecordRow(
                    label: 'Maior ritmo de entregas',
                    value: profile.highestDeliveriesCount == 0
                        ? 'Sem registro'
                        : '${profile.highestDeliveriesCount} entregas',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime? value) {
    if (value == null) return 'Sem registro';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _PublicPill extends StatelessWidget {
  const _PublicPill({
    required this.label,
    this.background,
    this.foreground,
    this.border,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border ?? Colors.white10),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foreground ?? Colors.white),
      ),
    );
  }
}

class _PublicBadgePill extends StatelessWidget {
  const _PublicBadgePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF001BFF).withValues(alpha: 0.26),
            const Color(0xFF00D4FF).withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 16),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

bool _isRemoteBanner(String? value) =>
    value != null &&
    RegExp(r'^https?://', caseSensitive: false).hasMatch(value);

Color? _tryBannerColor(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  if (match == null) return null;
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}

class _TierColors {
  const _TierColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

_TierColors _tierColors(String tier) {
  final normalized = tier.toLowerCase();
  if (normalized.contains('lend')) {
    return const _TierColors(
      background: Color(0xFF38115E),
      foreground: Color(0xFFFFE7FF),
      border: Color(0xFFFF4DFF),
    );
  }
  if (normalized.contains('diam')) {
    return const _TierColors(
      background: Color(0xFF083344),
      foreground: Color(0xFFE0F7FF),
      border: Color(0xFF67E8F9),
    );
  }
  if (normalized.contains('ouro')) {
    return const _TierColors(
      background: Color(0xFF422006),
      foreground: Color(0xFFFFF7CC),
      border: Color(0xFFFACC15),
    );
  }
  if (normalized.contains('prata')) {
    return const _TierColors(
      background: Color(0xFF334155),
      foreground: Color(0xFFF8FAFC),
      border: Color(0xFFCBD5E1),
    );
  }
  return const _TierColors(
    background: Color(0xFF451A03),
    foreground: Color(0xFFFFEDD5),
    border: Color(0xFFCD7F32),
  );
}

class _PublicStatCard extends StatelessWidget {
  const _PublicStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PublicRecordRow extends StatelessWidget {
  const _PublicRecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
