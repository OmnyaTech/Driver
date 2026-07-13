import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_public_driver.dart';
import '../../models/app_referral_reward.dart';
import '../../services/public_profile_service.dart';
import '../../services/referral_service.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/omnya_visuals.dart';
import '../../utilities/ui/profile_avatar.dart';
import 'public_driver_profile_screen.dart';
import 'ranking_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  final PublicProfileService _service = PublicProfileService();
  final ReferralService _referralService = ReferralService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppPublicDriverPreview> _ranking = const [];
  List<AppPublicDriverPreview> _results = const [];
  List<AppReferralReward> _rewards = const [];
  PublicProfileSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ranking = await _service.listRankingPreview(limit: 10);
      final results = await _service.searchDrivers('', limit: 12);
      final settings = await _service.loadSettings();
      final rewards = await _referralService.listRewards();
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
        _results = results;
        _rewards = rewards;
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    try {
      final results = await _service.searchDrivers(query, limit: 20);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;
    final strings = AppStrings.of(context);

    if (_loading) {
      return OmnyaSubPageScaffold(
        title: strings.community,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return OmnyaSubPageScaffold(
      title: strings.community,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            OmnyaAnimatedEntrance(
              child: OmnyaHeroCard(
                compact: true,
                child: Row(
                  children: [
                    ProfileAvatar(
                      displayName:
                          profile?.displayName ?? strings.driverFallback,
                      avatarUrl: profile?.avatarUrl,
                      radius: 24,
                      showBorder: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.pick(
                              pt: 'Chame seus amigos',
                              en: 'Invite your friends',
                              es: 'Invita a tus amigos',
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.pick(
                              pt: 'Compartilhe seu link. Quando alguem entrar por ele, voce ganha pontos no progresso.',
                              en: 'Share your link. When someone joins through it, you earn progress points.',
                              es: 'Comparte tu link. Cuando alguien entra por el, ganas puntos de progreso.',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _copyInvite(profile?.displayName),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      strings.pick(
                        pt: 'Copiar meu link',
                        en: 'Copy my link',
                        es: 'Copiar mi link',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RankingScreen()),
                  ),
                  child: Text(strings.ranking),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ReferralRewardsCard(rewards: _rewards),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: strings.pick(
                  pt: 'Buscar motorista, @usuario ou cidade',
                  en: 'Search driver, @user or city',
                  es: 'Buscar conductor, @usuario o ciudad',
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            OmnyaGlassCard(
              highlight: _ranking.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.pick(
                            pt: 'Motoristas em destaque',
                            en: 'Featured drivers',
                            es: 'Conductores destacados',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RankingScreen(),
                          ),
                        ),
                        child: Text(
                          strings.pick(
                            pt: 'Ver ranking',
                            en: 'View ranking',
                            es: 'Ver ranking',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._ranking
                      .take(3)
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ProfileAvatar(
                            displayName: item.displayName,
                            avatarUrl: item.avatarUrl,
                            radius: 20,
                          ),
                          title: Text(item.displayName),
                          subtitle: Text(
                            strings.pick(
                              pt: '${item.levelTitle} | ${item.medalsCount} conquistas',
                              en: '${item.levelTitle} | ${item.medalsCount} achievements',
                              es: '${item.levelTitle} | ${item.medalsCount} logros',
                            ),
                          ),
                          trailing: Text('#${item.rankPosition ?? 0}'),
                          onTap: () => _openProfile(item.publicSlug),
                        ),
                      ),
                  if (_ranking.isEmpty)
                    Text(
                      strings.pick(
                        pt: 'O ranking esta comecando. Ative seu perfil e chame a galera.',
                        en: 'The ranking is just getting started. Enable your profile and invite the crew.',
                        es: 'El ranking esta empezando. Activa tu perfil e invita a la gente.',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.pick(
                pt: 'Encontrar motoristas',
                en: 'Find drivers',
                es: 'Encontrar conductores',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_results.isEmpty)
              OmnyaGlassCard(
                child: Text(
                  strings.pick(
                    pt: 'Nao achei ninguem com esse nome ainda.',
                    en: 'No one found with that name yet.',
                    es: 'No encontre a nadie con ese nombre todavia.',
                  ),
                ),
              ),
            ..._results.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OmnyaGlassCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _openProfile(item.publicSlug),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: ProfileAvatar(
                      displayName: item.displayName,
                      avatarUrl: item.avatarUrl,
                      radius: 22,
                    ),
                    title: Text(item.displayName),
                    subtitle: Text(
                      [
                        item.levelTitle,
                        if ((item.publicCity ?? '').isNotEmpty)
                          item.publicCity!,
                      ].join(' | '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProfile(String slug) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicDriverProfileScreen(slug: slug)),
    );
  }

  Future<void> _copyInvite(String? displayName) async {
    final strings = AppStrings.of(context);
    try {
      final slug = await _service.ensureInviteSlug(
        currentSettings: _settings,
        displayName: displayName,
      );
      final url = PublicProfileService.buildInviteUrl(slug);
      await Clipboard.setData(
        ClipboardData(
          text: strings.pick(
            pt: 'Me encontre no Omnya Driver: @$slug\n$url',
            en: 'Find me on Omnya Driver: @$slug\n$url',
            es: 'Encuentrame en Omnya Driver: @$slug\n$url',
          ),
        ),
      );
      final settings = await _service.loadSettings();
      if (!mounted) return;
      setState(() => _settings = settings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'Link @$slug copiado.',
              en: 'Link @$slug copied.',
              es: 'Link @$slug copiado.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'Nao consegui copiar o link agora. Tente de novo.',
              en: 'Could not copy the link right now. Try again.',
              es: 'No pude copiar el link ahora. Intentalo otra vez.',
            ),
          ),
        ),
      );
    }
  }
}

class _ReferralRewardsCard extends StatelessWidget {
  const _ReferralRewardsCard({required this.rewards});

  final List<AppReferralReward> rewards;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final totalXp = rewards.fold<int>(
      0,
      (total, reward) => total + reward.rewardXp,
    );

    return OmnyaGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0000CD).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.group_add_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pick(
                        pt: 'Seu placar de convites',
                        en: 'Your invite score',
                        es: 'Tu marcador de invitaciones',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rewards.isEmpty
                          ? strings.pick(
                              pt: 'Convide amigos e ganhe XP quando eles entrarem.',
                              en: 'Invite friends and earn XP when they join.',
                              es: 'Invita amigos y gana XP cuando entren.',
                            )
                          : strings.pick(
                              pt: '${rewards.length} motorista(s) entraram | +$totalXp XP',
                              en: '${rewards.length} driver(s) joined | +$totalXp XP',
                              es: '${rewards.length} conductor(es) entraron | +$totalXp XP',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...rewards
                .take(3)
                .map(
                  (reward) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ProfileAvatar(
                      displayName: reward.referredDisplayName,
                      avatarUrl: reward.referredAvatarUrl,
                      radius: 18,
                    ),
                    title: Text(reward.referredDisplayName),
                    subtitle: Text(_dateLabel(context, reward.acceptedAt)),
                    trailing: Text(
                      '+${reward.rewardXp} XP',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime? value) {
    final strings = AppStrings.of(context);
    if (value == null) {
      return strings.pick(
        pt: 'Convite aceito',
        en: 'Invite accepted',
        es: 'Invitacion aceptada',
      );
    }
    final date = value.toLocal();
    final label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return strings.pick(
      pt: 'Entrou em $label',
      en: 'Joined on $label',
      es: 'Entro el $label',
    );
  }
}
