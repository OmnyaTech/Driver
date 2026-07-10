import 'package:flutter/material.dart';

import '../../models/app_gamification.dart';
import '../../services/gamification_service.dart';
import '../../utilities/ui/omnya_shell.dart';
import 'records_screen.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final GamificationService _service = GamificationService();
  bool _loading = true;
  String? _errorMessage;
  AppGamificationSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.loadSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nao foi possivel carregar seu progresso agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

    return OmnyaSubPageScaffold(
      title: 'Progresso',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F1320),
                    Color(0xFF1A2133),
                    Color(0xFF0000CD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel ${summary.level}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.levelTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: summary.progressToNextLevel,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.remainingXpToNextLevel == null
                        ? '${summary.xp} XP acumulados'
                        : '${summary.xp} XP • faltam ${summary.remainingXpToNextLevel} XP para o proximo nivel',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ProgressPill(
                        label: '${summary.currentStreakDays} dias seguidos',
                      ),
                      _ProgressPill(label: '${summary.medalsCount} medalhas'),
                      _ProgressPill(
                        label: 'Score publico ${summary.publicScore}',
                      ),
                    ],
                  ),
                ],
              ),
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
                    title: 'Melhor sequencia',
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
                    title: 'Medalhas',
                    value: '${summary.medalsCount}',
                    subtitle: 'Conquistas desbloqueadas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Ranking',
                    value: summary.rankingOptIn ? 'Ativo' : 'Pendente',
                    subtitle: summary.rankingOptIn
                        ? 'Seu perfil pode aparecer'
                        : 'Ative no perfil publico',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                            'Proximas conquistas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecordsScreen(),
                            ),
                          ),
                          child: const Text('Ver recordes'),
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
                        'As medalhas aparecerao aqui conforme sua operacao for evoluindo.',
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
        'Faltam $remainingXp XP para alcancar a proxima faixa de reputacao.',
      ));
    }
    if (summary.bestStreakDays < 7) {
      items.add((
        'Sequencia de 7 dias',
        'Mantenha jornadas ativas para desbloquear a medalha Foco da semana.',
      ));
    }
    if (summary.medalsCount < 5) {
      items.add((
        'Colecionar medalhas',
        'Consolide jornadas, entregas e metas para fortalecer seu score publico.',
      ));
    }
    if (items.isEmpty) {
      items.add((
        'Perfil consolidado',
        'Seu perfil ja esta maduro. Agora vale focar em consistencia e ranking.',
      ));
    }
    return items;
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
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
