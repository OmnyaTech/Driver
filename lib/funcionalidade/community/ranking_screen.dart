import 'package:flutter/material.dart';

import '../../models/app_public_driver.dart';
import '../../services/public_profile_service.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/profile_avatar.dart';
import 'public_driver_profile_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final PublicProfileService _service = PublicProfileService();
  bool _loading = true;
  String? _errorMessage;
  List<AppPublicDriverPreview> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.listRankingPreview(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _errorMessage = 'Nao foi possivel carregar o ranking agora.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Ranking',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return OmnyaSubPageScaffold(
      title: 'Ranking',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          itemBuilder: (context, index) {
            if (_errorMessage != null) {
              return _RankingEmptyState(
                icon: Icons.wifi_tethering_error_rounded,
                title: 'Ranking fora do ar',
                message: _errorMessage!,
              );
            }
            if (_items.isEmpty) {
              return const _RankingEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Temporada em aquecimento',
                message:
                    'Quando os motoristas ativarem perfil publico e ranking, o placar aparece aqui.',
              );
            }

            final item = _items[index];
            final position = item.rankPosition ?? index + 1;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: Duration(
                milliseconds: 260 + (index * 42).clamp(0, 420),
              ),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PublicDriverProfileScreen(slug: item.publicSlug),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _RankBadge(position: position),
                        const SizedBox(width: 12),
                        ProfileAvatar(
                          displayName: item.displayName,
                          avatarUrl: item.avatarUrl,
                          radius: 22,
                          showBorder: position <= 3,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.levelTitle} | ${item.medalsCount} medalhas | ${item.bestStreakDays}d',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.publicScore}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '@${item.publicSlug}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: _errorMessage != null || _items.isEmpty
              ? 1
              : _items.length,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPodium
            ? const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0000CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPodium
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Text(
          '#$position',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isPodium ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: const Color(0xFF7582FF)),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message),
          ],
        ),
      ),
    );
  }
}
