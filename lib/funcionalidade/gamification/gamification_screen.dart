import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_gamification.dart';
import '../../services/gamification_service.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/profile_avatar.dart';
import 'records_screen.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _service = GamificationService();
  late final AnimationController _pulseController;
  bool _loading = true;
  String? _errorMessage;
  AppGamificationSummary? _summary;
  AppGrowthSummary? _growth;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.loadSummary();
      AppGrowthSummary? growth;
      try {
        growth = await _service.loadGrowthSummary();
      } catch (_) {
        growth = null;
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _growth = growth;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nao foi possivel carregar seu progresso agora.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Progresso',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final summary =
        _summary ??
        const AppGamificationSummary(
          xp: 0,
          level: 1,
          levelTitle: 'Motorista iniciante',
          nextLevelXp: 250,
          currentStreakDays: 0,
          bestStreakDays: 0,
          medalsCount: 0,
          rankingOptIn: false,
          publicScore: 0,
          records: AppDriverRecords(
            bestFridayDate: null,
            highestRevenueDayDate: null,
            highestProfitPerHourStartedAt: null,
            highestDeliveriesDayDate: null,
            highestDeliveriesCount: 0,
          ),
          medals: [],
        );

    final profile = context.watch<AppSession>().profile;

    return OmnyaSubPageScaffold(
      title: 'Progresso',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _GameHero(
              summary: summary,
              animation: _pulseController,
              displayName: profile?.displayName ?? 'Motorista',
              avatarUrl: profile?.avatarUrl,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sequencia atual',
                    value: '${summary.currentStreakDays} dias',
                    subtitle: 'Ritmo recente',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Melhor ritmo',
                    value: '${summary.bestStreakDays} dias',
                    subtitle: 'Seu recorde',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Conquistas',
                    value: '${summary.medalsCount}',
                    subtitle: 'Conquistas liberadas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Disputa',
                    value: summary.rankingOptIn ? 'Ativo' : 'Pendente',
                    subtitle: summary.rankingOptIn
                        ? 'Valendo pontos'
                        : 'Ative no perfil',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_growth != null) ...[
              _TierAndMissionsCard(
                growth: _growth!,
                animation: _pulseController,
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Proximos passos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecordsScreen(),
                            ),
                          ),
                          child: const Text('Recordes'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._nextGoals(summary).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdviceRow(title: item.$1, description: item.$2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medalhas visiveis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (summary.medals.isEmpty)
                      const Text(
                        'Suas conquistas vao aparecer aqui conforme voce usa o app.',
                      ),
                    ...summary.medals
                        .take(6)
                        .map(
                          (medal) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0000CD,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
                                color: Color(0xFF7582FF),
                              ),
                            ),
                            title: Text(medal.name),
                            subtitle: Text(
                              medal.description ??
                                  'Conquista registrada no perfil.',
                            ),
                            trailing: medal.awardedAt == null
                                ? null
                                : Text(_formatDate(medal.awardedAt!)),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _nextGoals(AppGamificationSummary summary) {
    final items = <(String, String)>[];
    final remainingXp = summary.remainingXpToNextLevel;
    if (remainingXp != null) {
      items.add((
        'Subir de nivel',
        'Faltam $remainingXp XP para subir mais um nivel.',
      ));
    }
    if (summary.bestStreakDays < 7) {
      items.add((
        'Sequencia de 7 dias',
        'Trabalhe em dias seguidos para liberar a conquista Foco da semana.',
      ));
    }
    if (summary.medalsCount < 5) {
      items.add((
        'Colecionar conquistas',
        'Registre jornadas, entregas e metas para ganhar mais pontos.',
      ));
    }
    if (items.isEmpty) {
      items.add((
        'Voce esta voando',
        'Agora o jogo e manter o ritmo e subir no ranking.',
      ));
    }
    return items;
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

class _TierAndMissionsCard extends StatelessWidget {
  const _TierAndMissionsCard({required this.growth, required this.animation});

  final AppGrowthSummary growth;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Transform.rotate(
                    angle: animation.value * 0.08,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0000CD).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFF7582FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liga ${growth.tier}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        growth.nextTierScore == 0
                            ? 'Voce chegou no topo por enquanto.'
                            : 'Faltam ${growth.nextTierScore - growth.publicScore} pts para a proxima liga.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${growth.publicScore} pts',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MissionPill(label: '${growth.totalDeliveries} entregas'),
                _MissionPill(label: '${growth.accountDays} dias no app'),
                _MissionPill(label: '${growth.visibleBadges} badges'),
              ],
            ),
            const SizedBox(height: 18),
            Text('Missoes da semana', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (growth.missions.isEmpty)
              const Text(
                'As proximas missoes aparecem aqui quando houver dados suficientes.',
              ),
            ...growth.missions.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MissionProgressRow(mission: mission),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionPill extends StatelessWidget {
  const _MissionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0000CD).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _MissionProgressRow extends StatelessWidget {
  const _MissionProgressRow({required this.mission});

  final AppDriverMission mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(mission.title, style: theme.textTheme.titleSmall),
            ),
            Text(
              mission.completed
                  ? '+${mission.rewardXp} XP'
                  : '${mission.current}/${mission.target}',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(mission.description, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: mission.progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ),
      ],
    );
  }
}

class _GameHero extends StatelessWidget {
  const _GameHero({
    required this.summary,
    required this.animation,
    required this.displayName,
    required this.avatarUrl,
  });

  final AppGamificationSummary summary;
  final Animation<double> animation;
  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow = 0.18 + (animation.value * 0.14);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0000CD).withValues(alpha: glow),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1320), Color(0xFF1A2133), Color(0xFF0000CD)],
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
                _AnimatedAvatarBadge(
                  animation: animation,
                  child: ProfileAvatar(
                    displayName: displayName,
                    avatarUrl: avatarUrl,
                    radius: 24,
                    showBorder: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liga ${_leagueName(summary.level)}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        'Nivel ${summary.level}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                _ProgressPill(label: '${summary.publicScore} pts'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              summary.levelTitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            _KarmaDial(
              progress: summary.progressToNextLevel,
              animation: animation,
              label: summary.remainingXpToNextLevel == null
                  ? 'Nivel maximo por enquanto'
                  : 'Faltam ${summary.remainingXpToNextLevel} XP',
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: summary.progressToNextLevel),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              summary.remainingXpToNextLevel == null
                  ? '${summary.xp} XP acumulados'
                  : '${summary.xp} XP | faltam ${summary.remainingXpToNextLevel} XP para o proximo nivel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProgressPill(label: '${summary.currentStreakDays} dias'),
                _ProgressPill(label: '${summary.medalsCount} conquistas'),
                _ProgressPill(
                  label: summary.rankingOptIn
                      ? 'Ranking ativo'
                      : 'Ranking pendente',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _leagueName(int level) {
    if (level >= 8) return 'Lenda';
    if (level >= 6) return 'Elite';
    if (level >= 4) return 'Pro';
    if (level >= 2) return 'Ritmo';
    return 'Inicio';
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label});

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

class _AnimatedAvatarBadge extends StatelessWidget {
  const _AnimatedAvatarBadge({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = 1 + (animation.value * 0.06);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 14,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _KarmaDial extends StatelessWidget {
  const _KarmaDial({
    required this.progress,
    required this.animation,
    required this.label,
  });

  final double progress;
  final Animation<double> animation;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _KarmaDialPainter(
                  progress: progress,
                  pulse: animation.value,
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meta do nivel',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KarmaDialPainter extends CustomPainter {
  const _KarmaDialPainter({required this.progress, required this.pulse});

  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 5;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.18);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF00E5FF), Colors.white],
      ).createShader(Offset.zero & size);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + (pulse * 2)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08 + pulse * 0.08);

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress.clamp(0, 1) * 6.283,
      false,
      glow,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress.clamp(0, 1) * 6.283,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _KarmaDialPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _AdviceRow extends StatelessWidget {
  const _AdviceRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0000CD).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome, color: Color(0xFF7582FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
