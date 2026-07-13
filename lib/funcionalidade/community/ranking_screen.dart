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
  String _scope = 'global';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.listRankingPreview(limit: 50, scope: _scope);
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _errorMessage = 'Nao consegui carregar o ranking agora.';
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
            if (index == 0) {
              return _RankingScopeBar(
                selectedScope: _scope,
                onChanged: (value) {
                  setState(() {
                    _scope = value;
                    _loading = true;
                  });
                  _load();
                },
              );
            }

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
                title: 'Temporada comecando',
                message:
                    'Quando a galera ativar o perfil publico, o placar aparece aqui.',
              );
            }

            final item = _items[index - 1];
            final position = item.rankPosition ?? index;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(
                milliseconds: 320 + (index * 48).clamp(0, 520),
              ),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.96 + (value * 0.04),
                      child: child,
                    ),
                  ),
                );
              },
              child: _RankingCard(item: item, position: position),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: _errorMessage != null || _items.isEmpty
              ? 2
              : _items.length + 1,
        ),
      ),
    );
  }
}

class _RankingScopeBar extends StatelessWidget {
  const _RankingScopeBar({
    required this.selectedScope,
    required this.onChanged,
  });

  final String selectedScope;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scopes = const <(String, String)>[
      ('local', 'Cidade'),
      ('state', 'Estado'),
      ('national', 'Pais'),
      ('global', 'Global'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scopes.map((scope) {
            final selected = scope.$1 == selectedScope;
            return ChoiceChip(
              label: Text(scope.$2),
              selected: selected,
              onSelected: (_) => onChanged(scope.$1),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.item, required this.position});

  final AppPublicDriverPreview item;
  final int position;

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicDriverProfileScreen(slug: item.publicSlug),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: isPodium
                ? LinearGradient(
                    colors: [
                      const Color(0xFF0000CD).withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBadge(position: position),
              const SizedBox(width: 12),
              ProfileAvatar(
                displayName: item.displayName,
                avatarUrl: item.avatarUrl,
                radius: 23,
                showBorder: isPodium,
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
                      '${item.levelTitle} | ${item.medalsCount} conquistas | ${item.bestStreakDays}d',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.publicScore}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('pts', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
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
