import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_public_driver.dart';
import '../../services/public_profile_service.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppPublicDriverPreview> _ranking = const [];
  List<AppPublicDriverPreview> _results = const [];
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
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
        _results = results;
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

    if (_loading) {
      return const OmnyaSubPageScaffold(
        title: 'Comunidade',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return OmnyaSubPageScaffold(
      title: 'Comunidade',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D1020),
                    Color(0xFF1B2031),
                    Color(0xFF0000CD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    displayName: profile?.displayName ?? 'Motorista',
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
                          'Convide outros motoristas',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use seu perfil publico e compartilhe seu convite sem expor ganhos.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _copyInvite(profile?.displayName),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Gerar convite'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RankingScreen()),
                  ),
                  child: const Text('Ranking'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar motoristas, slug ou cidade',
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
                            'Motoristas em destaque',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RankingScreen(),
                            ),
                          ),
                          child: const Text('Ver ranking'),
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
                              '${item.levelTitle} • ${item.medalsCount} medalhas',
                            ),
                            trailing: Text('#${item.rankPosition ?? 0}'),
                            onTap: () => _openProfile(item.publicSlug),
                          ),
                        ),
                    if (_ranking.isEmpty)
                      const Text(
                        'O ranking esta em aquecimento. Ative perfis publicos para liberar a disputa.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Encontrar perfis publicos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_results.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Nenhum perfil publico encontrado para esse filtro.',
                  ),
                ),
              ),
            ..._results.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
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
                      ].join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openProfile(item.publicSlug),
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
    try {
      final slug = await _service.ensureInviteSlug(
        currentSettings: _settings,
        displayName: displayName,
      );
      final url = PublicProfileService.buildInviteUrl(slug);
      await Clipboard.setData(
        ClipboardData(text: 'Me encontre no Omnya Driver: @$slug\n$url'),
      );
      final settings = await _service.loadSettings();
      if (!mounted) return;
      setState(() => _settings = settings);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Convite @$slug copiado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel gerar o convite agora.'),
        ),
      );
    }
  }
}
