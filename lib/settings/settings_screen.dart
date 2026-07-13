import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/community/community_hub_screen.dart';
import '../funcionalidade/developer/developer_access_screen.dart';
import '../funcionalidade/gamification/gamification_screen.dart';
import '../funcionalidade/notifications/notifications_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/community/ranking_screen.dart';
import '../funcionalidade/security/security_screen.dart';
import '../funcionalidade/subscriptions/subscriptions_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../models/driver_reserve_preference.dart';
import '../services/avatar_service.dart';
import '../services/driver_preference_service.dart';
import '../services/profile_service.dart';
import '../services/public_profile_service.dart';
import '../utilities/guards/developer_guard.dart';
import '../utilities/localization/app_strings.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/profile_avatar.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;
    final strings = AppStrings.of(context);
    final canOpenDeveloper = profile != null
        ? DeveloperGuard().canOpen(profile.role)
        : false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _SettingsHeroCard(session: session),
        const SizedBox(height: 18),
        _SettingsSection(
          title: strings.accountIdentity,
          children: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: strings.driverProfile,
              subtitle: strings.driverProfileSubtitle,
              onTap: () => _openProfileSheet(context),
            ),
            _SettingsTile(
              icon: Icons.public_outlined,
              title: strings.publicProfile,
              subtitle: strings.publicProfileSubtitle,
              onTap: () => _openPublicProfileSheet(context),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: strings.appPreferences,
              subtitle:
                  '${profile?.languageLabel ?? 'Portugues'} - ${profile?.currencyLabel ?? 'Real brasileiro'}',
              onTap: () => _openAppPreferenceSheet(context),
            ),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: strings.themeApp,
              subtitle: session.themeMode == ThemeMode.dark
                  ? strings.darkThemeActive
                  : strings.lightThemeActive,
              trailing: Switch(
                value: session.themeMode == ThemeMode.dark,
                onChanged: (_) => session.toggleThemeMode(),
              ),
            ),
            _SettingsTile(
              icon: Icons.savings_outlined,
              title: strings.automaticReserve,
              subtitle:
                  profile?.reservePreference.summaryLabel ??
                  '30% do que sobrar',
              onTap: () => _openReservePreferenceSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: strings.records,
          children: [
            _SettingsTile(
              icon: Icons.two_wheeler_outlined,
              title: strings.vehicles,
              subtitle: strings.vehiclesSubtitle,
              onTap: () => _pushPage(context, const VehiclesScreen()),
            ),
            _SettingsTile(
              icon: Icons.storefront_outlined,
              title: strings.platforms,
              subtitle: strings.platformsSubtitle,
              onTap: () => _pushPage(context, const PlatformsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: strings.communityProgress,
          children: [
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: strings.driverProgress,
              subtitle: strings.driverProgressSubtitle,
              onTap: () => _pushPage(context, const GamificationScreen()),
            ),
            _SettingsTile(
              icon: Icons.groups_outlined,
              title: strings.community,
              subtitle: strings.communitySubtitle,
              onTap: () => _pushPage(context, const CommunityHubScreen()),
            ),
            _SettingsTile(
              icon: Icons.emoji_events_outlined,
              title: strings.ranking,
              subtitle: strings.rankingSubtitle,
              onTap: () => _pushPage(context, const RankingScreen()),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: strings.notices,
              subtitle: strings.noticesSubtitle,
              onTap: () => _pushPage(context, const NotificationsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: strings.planSupport,
          children: [
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: strings.subscription,
              subtitle: strings.subscriptionSubtitle,
              onTap: () => _pushPage(context, const SubscriptionsScreen()),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: strings.securityData,
              subtitle: strings.securityDataSubtitle,
              onTap: () => _pushPage(context, const SecurityScreen()),
            ),
            if (canOpenDeveloper)
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Developer',
                subtitle: strings.developerTools,
                onTap: () => _pushPage(context, const DeveloperAccessScreen()),
              ),
            _SettingsTile(
              icon: Icons.logout,
              title: strings.signOut,
              subtitle: strings.signOutSubtitle,
              onTap: session.isBusy ? null : session.signOut,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pushPage(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openProfileSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheet(),
    );
  }

  Future<void> _openPublicProfileSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PublicProfileSheet(),
    );
  }

  Future<void> _openReservePreferenceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReservePreferenceSheet(),
    );
  }

  Future<void> _openAppPreferenceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AppPreferenceSheet(),
    );
  }
}

class SettingsStandaloneScreen extends StatelessWidget {
  const SettingsStandaloneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).settingsTitle)),
      body: const SettingsScreen(),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final profile = session.profile;
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B0E16), Color(0xFF151A29), Color(0xFF0000CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0000CD).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    displayName: profile?.displayName ?? 'Omnya Driver',
                    avatarUrl: profile?.avatarUrl,
                    radius: 28,
                    showBorder: true,
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Image.asset(_driverLogoAsset),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.settingsTitle} OmnyaTech',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? 'driver@omnyatech.com.br',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: 'Plano ${profile?.planType.name ?? 'free'}'),
              _HeroPill(label: 'Perfil ${profile?.displayName ?? 'Motorista'}'),
              _HeroPill(
                label: session.themeMode == ThemeMode.dark
                    ? 'Tema escuro'
                    : 'Tema claro',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF0000CD).withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: const Color(0xFF0000CD)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _avatarService = AvatarService();
  late final TextEditingController _displayNameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppSession>().profile;
    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    );
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final profile = context.watch<AppSession>().profile;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Perfil do motorista',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deixe seu nome e foto do jeito que voce quer aparecer no app.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        ProfileAvatar(
                          displayName:
                              _displayNameController.text.trim().isEmpty
                              ? 'Motorista'
                              : _displayNameController.text.trim(),
                          avatarUrl: profile?.avatarUrl,
                          radius: 42,
                          showBorder: true,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: (_saving || _uploadingAvatar)
                                  ? null
                                  : _pickAvatar,
                              icon: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_camera_outlined),
                              label: const Text('Alterar foto'),
                            ),
                            if ((profile?.avatarUrl ?? '').trim().isNotEmpty)
                              TextButton(
                                onPressed: (_saving || _uploadingAvatar)
                                    ? null
                                    : _removeAvatar,
                                child: const Text('Remover foto'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome exibido',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar perfil'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<AppSession>();
    final navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.updateProfile(
        displayName: _displayNameController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
      );
      await session.refreshProfile();
      if (!mounted) return;
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final session = context.read<AppSession>();
    setState(() {
      _uploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final url = await _avatarService.pickAndUploadProfileAvatar();
      if (url == null) {
        return;
      }
      await session.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    final session = context.read<AppSession>();
    setState(() {
      _uploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      await _avatarService.removeProfileAvatar();
      await session.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil removida com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
  }
}

class _PublicProfileSheet extends StatefulWidget {
  const _PublicProfileSheet();

  @override
  State<_PublicProfileSheet> createState() => _PublicProfileSheetState();
}

class _PublicProfileSheetState extends State<_PublicProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = PublicProfileService();
  final _slugController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  bool _enabled = false;
  bool _rankingOptIn = false;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.loadSettings();
      if (!mounted) return;
      setState(() {
        _enabled = settings.publicProfileEnabled;
        _rankingOptIn = settings.rankingOptIn;
        _slugController.text = settings.publicSlug ?? '';
        _bioController.text = settings.publicBio ?? '';
        _cityController.text = settings.publicCity ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Nao consegui carregar seu perfil agora.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.dividerColor),
          ),
          child: _loading
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Perfil publico',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Escolha como outros motoristas vao te encontrar. Seus ganhos continuam privados.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Perfil publico ativo'),
                          subtitle: const Text(
                            'Mostra seu nome, foto, cidade e conquistas.',
                          ),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                        TextFormField(
                          controller: _slugController,
                          decoration: const InputDecoration(
                            labelText: 'Seu @ no Omnya Driver',
                            hintText: 'ex: yan-driver',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Sobre voce',
                            hintText: 'Conte rapidinho como e seu corre.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Participar do ranking'),
                          subtitle: const Text(
                            'Seu nome pode aparecer no placar da comunidade.',
                          ),
                          value: _rankingOptIn,
                          onChanged: (value) =>
                              setState(() => _rankingOptIn = value),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Salvar perfil'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _service.updateSettings(
        publicProfileEnabled: _enabled,
        publicSlug: _slugController.text,
        publicBio: _bioController.text,
        publicCity: _cityController.text,
        rankingOptIn: _rankingOptIn,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil publico atualizado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Nao consegui salvar agora. Tente de novo em instantes.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _AppPreferenceSheet extends StatefulWidget {
  const _AppPreferenceSheet();

  @override
  State<_AppPreferenceSheet> createState() => _AppPreferenceSheetState();
}

class _AppPreferenceSheetState extends State<_AppPreferenceSheet> {
  final _service = DriverPreferenceService();
  late String _languageCode;
  late String _currencyCode;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppSession>().profile;
    _languageCode = profile?.languageCode ?? 'pt-BR';
    _currencyCode = profile?.currencyCode ?? 'BRL';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(strings.appPreferences, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  strings.appPreferencesDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _normalizeLanguage(_languageCode),
                  decoration: InputDecoration(
                    labelText: strings.language,
                    prefixIcon: const Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pt-BR',
                      child: Text('Portugues do Brasil'),
                    ),
                    DropdownMenuItem(value: 'en-US', child: Text('English')),
                    DropdownMenuItem(value: 'es-ES', child: Text('Espanol')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _languageCode = value);
                        },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _normalizeCurrency(_currencyCode),
                  decoration: InputDecoration(
                    labelText: strings.currency,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'BRL',
                      child: Text('Real brasileiro (R\$)'),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('Dolar americano (US\$)'),
                    ),
                    DropdownMenuItem(value: 'EUR', child: Text('Euro')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _currencyCode = value);
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  strings.appPreferencesSubtitle,
                  style: theme.textTheme.bodySmall,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(strings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final session = context.read<AppSession>();
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _service.updateAppPreferences(
        languageCode: _languageCode,
        currencyCode: _currencyCode,
      );
      await session.refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).preferencesSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _normalizeLanguage(String value) {
    return switch (value) {
      'en-US' => 'en-US',
      'es-ES' => 'es-ES',
      _ => 'pt-BR',
    };
  }

  String _normalizeCurrency(String value) {
    return switch (value) {
      'USD' => 'USD',
      'EUR' => 'EUR',
      _ => 'BRL',
    };
  }
}

class _ReservePreferenceSheet extends StatefulWidget {
  const _ReservePreferenceSheet();

  @override
  State<_ReservePreferenceSheet> createState() =>
      _ReservePreferenceSheetState();
}

class _ReservePreferenceSheetState extends State<_ReservePreferenceSheet> {
  final _service = DriverPreferenceService();
  late DriverReserveMode _mode;
  late TextEditingController _percentageController;
  late TextEditingController _perDeliveryController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final preference =
        context.read<AppSession>().profile?.reservePreference ??
        const DriverReservePreference(
          mode: DriverReserveMode.dailyPercent,
          dailyPercentage: 30,
          amountPerDelivery: 0,
        );
    _mode = preference.mode;
    _percentageController = TextEditingController(
      text: preference.dailyPercentage.toStringAsFixed(
        preference.dailyPercentage.truncateToDouble() ==
                preference.dailyPercentage
            ? 0
            : 1,
      ),
    );
    _perDeliveryController = TextEditingController(
      text: preference.amountPerDelivery <= 0
          ? ''
          : preference.amountPerDelivery.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _perDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Reserva automatica', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Escolha quanto voce costuma guardar para despesa, meta ou seguranca.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Sem reserva'),
                      selected: _mode == DriverReserveMode.none,
                      onSelected: (_) =>
                          setState(() => _mode = DriverReserveMode.none),
                    ),
                    ChoiceChip(
                      label: const Text('% do que sobrar'),
                      selected: _mode == DriverReserveMode.dailyPercent,
                      onSelected: (_) => setState(
                        () => _mode = DriverReserveMode.dailyPercent,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Valor por entrega'),
                      selected: _mode == DriverReserveMode.perDeliveryFixed,
                      onSelected: (_) => setState(
                        () => _mode = DriverReserveMode.perDeliveryFixed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_mode == DriverReserveMode.dailyPercent) ...[
                  TextFormField(
                    controller: _percentageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Percentual do que sobrar',
                      hintText: 'Ex: 30',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A sugestao usa o valor que sobrou no periodo atual.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_mode == DriverReserveMode.perDeliveryFixed) ...[
                  TextFormField(
                    controller: _perDeliveryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor reservado por entrega',
                      hintText: 'Ex: 2.50',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cada entrega concluida gera uma sugestao proporcional ao valor definido por voce.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_mode == DriverReserveMode.none)
                  Text(
                    'Nenhuma reserva automatica sera sugerida no painel ou nas notificacoes.',
                    style: theme.textTheme.bodySmall,
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar regra'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final session = context.read<AppSession>();
    final percentage = double.tryParse(
      _percentageController.text.replaceAll(',', '.'),
    );
    final perDelivery = double.tryParse(
      _perDeliveryController.text.replaceAll(',', '.'),
    );

    if (_mode == DriverReserveMode.dailyPercent &&
        (percentage == null || percentage < 0 || percentage > 100)) {
      setState(() {
        _errorMessage = 'Informe um percentual valido entre 0 e 100.';
      });
      return;
    }

    if (_mode == DriverReserveMode.perDeliveryFixed &&
        (perDelivery == null || perDelivery < 0)) {
      setState(() {
        _errorMessage = 'Informe um valor valido por entrega.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _service.updateReservePreference(
        mode: _mode,
        dailyPercentage: percentage ?? 30,
        amountPerDelivery: perDelivery ?? 0,
      );
      await session.refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencia de reserva atualizada com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
