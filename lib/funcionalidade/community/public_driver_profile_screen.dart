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

    return OmnyaSubPageScaffold(
      title: 'Perfil',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              image: (profile.publicBannerUrl ?? '').trim().isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(profile.publicBannerUrl!.trim()),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    ),
              gradient: (profile.publicBannerUrl ?? '').trim().isEmpty
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF111522),
                        Color(0xFF1A1F31),
                        Color(0xFF0000CD),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
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
                    _PublicPill(label: 'Liga ${profile.tier}'),
                    if ((profile.publicCity ?? '').isNotEmpty)
                      _PublicPill(label: profile.publicCity!),
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
                  subtitle: 'jornada com Omnya',
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
                          .map((badge) => Chip(label: Text(badge)))
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
  const _PublicPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
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
