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
import '../utilities/localization/app_format.dart';
import '../utilities/localization/app_strings.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_visuals.dart';
import '../utilities/ui/profile_avatar.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;
    final strings = AppStrings.of(context);
    final format = AppFormat.of(context);
    final canOpenDeveloper = profile != null
        ? DeveloperGuard().canOpen(profile.role)
        : false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        OmnyaAnimatedEntrance(child: _SettingsHeroCard(session: session)),
        const SizedBox(height: 18),
        OmnyaAnimatedEntrance(
          delay: const Duration(milliseconds: 80),
          child: _SettingsSection(
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
                    '${strings.languageLabel(profile?.languageCode ?? 'pt-BR')} - ${strings.currencyLabel(profile?.currencyCode ?? 'BRL')}',
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
                subtitle: profile == null
                    ? strings.reserveSummary(
                        const DriverReservePreference(
                          mode: DriverReserveMode.dailyPercent,
                          dailyPercentage: 30,
                          amountPerDelivery: 0,
                        ),
                        format.currency,
                      )
                    : strings.reserveSummary(
                        profile.reservePreference,
                        format.currency,
                      ),
                onTap: () => _openReservePreferenceSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OmnyaAnimatedEntrance(
          delay: const Duration(milliseconds: 140),
          child: _SettingsSection(
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
        ),
        const SizedBox(height: 18),
        OmnyaAnimatedEntrance(
          delay: const Duration(milliseconds: 200),
          child: _SettingsSection(
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
        ),
        const SizedBox(height: 18),
        OmnyaAnimatedEntrance(
          delay: const Duration(milliseconds: 260),
          child: _SettingsSection(
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
              _SettingsTile(
                icon: Icons.help_outline,
                title: strings.helpCenter,
                subtitle: strings.helpCenterSubtitle,
                onTap: () => _pushPage(
                  context,
                  _InfoScreen(
                    title: strings.helpCenter,
                    icon: Icons.help_outline,
                    subtitle: strings.helpCenterSubtitle,
                    searchHint: strings.helpCenterSearchHint,
                    actionLabel: strings.helpCenterAction,
                    highlights: strings.helpCenterHighlights,
                    sectionLabels: strings.helpCenterSectionLabels,
                    body: [
                      strings.helpCenterIntro,
                      strings.helpCenterFirstSteps,
                      strings.helpCenterVehicles,
                      strings.helpCenterTipJourney,
                      strings.helpCenterGoals,
                      strings.helpCenterTipBilling,
                      strings.helpCenterTipSupport,
                      strings.helpCenterFooter,
                    ],
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: strings.aboutOmnyaDriver,
                subtitle: strings.aboutOmnyaDriverSubtitle,
                onTap: () => _pushPage(
                  context,
                  _InfoScreen(
                    title: strings.aboutOmnyaDriver,
                    icon: Icons.info_outline,
                    subtitle: strings.aboutOmnyaDriverSubtitle,
                    highlights: strings.aboutHighlights,
                    sectionLabels: strings.aboutSectionLabels,
                    body: [
                      strings.aboutOmnyaDriverBody,
                      strings.aboutOmnyaDriverWhy,
                      strings.aboutOmnyaDriverCanDo,
                      strings.aboutOmnyaDriverBrand,
                      strings.aboutOmnyaDriverTech,
                    ],
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.article_outlined,
                title: strings.termsOfUse,
                subtitle: strings.termsOfUseSubtitle,
                onTap: () => _pushPage(
                  context,
                  _InfoScreen(
                    title: strings.termsOfUse,
                    icon: Icons.article_outlined,
                    subtitle: strings.termsOfUseSubtitle,
                    highlights: strings.termsHighlights,
                    sectionLabels: strings.termsSectionLabels,
                    body: [
                      strings.termsOfUseBody,
                      strings.termsOfUseService,
                      strings.termsOfUseAccount,
                      strings.termsOfUseBilling,
                      strings.termsOfUseData,
                      strings.termsOfUseConduct,
                      strings.termsOfUseContact,
                    ],
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: strings.privacyPolicy,
                subtitle: strings.privacyPolicySubtitle,
                onTap: () => _pushPage(
                  context,
                  _InfoScreen(
                    title: strings.privacyPolicy,
                    icon: Icons.shield_outlined,
                    subtitle: strings.privacyPolicySubtitle,
                    highlights: strings.privacyHighlights,
                    sectionLabels: strings.privacySectionLabels,
                    body: [
                      strings.privacyPolicyBody,
                      strings.privacyPolicyCollected,
                      strings.privacyPolicyUse,
                      strings.privacyPolicyStorage,
                      strings.privacyPolicyPublicProfile,
                      strings.privacyPolicyContact,
                      strings.privacyPolicyDpo,
                    ],
                  ),
                ),
              ),
              if (canOpenDeveloper)
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Developer',
                  subtitle: strings.developerTools,
                  onTap: () =>
                      _pushPage(context, const DeveloperAccessScreen()),
                ),
              _SettingsTile(
                icon: Icons.logout,
                title: strings.signOut,
                subtitle: strings.signOutSubtitle,
                onTap: session.isBusy ? null : session.signOut,
              ),
            ],
          ),
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

class _InfoScreen extends StatelessWidget {
  const _InfoScreen({
    required this.title,
    required this.icon,
    required this.body,
    this.subtitle,
    this.searchHint,
    this.actionLabel,
    this.highlights = const [],
    this.sectionLabels = const [],
  });

  final String title;
  final IconData icon;
  final List<String> body;
  final String? subtitle;
  final String? searchHint;
  final String? actionLabel;
  final List<String> highlights;
  final List<String> sectionLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intro = body.isNotEmpty ? body.first : '';
    final sections = body.length > 1 ? body.skip(1).toList() : <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: OmnyaAtmosphere(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            OmnyaAnimatedEntrance(
              child: OmnyaHeroCard(
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  subtitle!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      intro,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.94),
                        height: 1.45,
                      ),
                    ),
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final highlight in highlights)
                            OmnyaGlowChip(label: highlight),
                        ],
                      ),
                    ],
                    if (searchHint != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                searchHint!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(actionLabel!)),
                            );
                          },
                          icon: const Icon(Icons.support_agent_outlined),
                          label: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < sections.length; index++)
              OmnyaAnimatedEntrance(
                delay: Duration(milliseconds: 80 * (index + 1)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InfoSectionCard(
                    index: index + 1,
                    title: index < sectionLabels.length
                        ? sectionLabels[index]
                        : '${index + 1}',
                    body: sections[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OmnyaGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0000CD).withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5265FF)),
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.48),
                ),
              ],
            ),
          ),
        ],
      ),
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

    return OmnyaHeroCard(
      compact: true,
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
              _HeroPill(
                label: 'Perfil ${profile?.displayName ?? 'Entregador'}',
              ),
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
    return OmnyaGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
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
    final theme = Theme.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  OmnyaVisualTokens.electricBlue.withValues(alpha: 0.24),
                  OmnyaVisualTokens.neonBlue.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: OmnyaVisualTokens.neonBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ?? const Icon(Icons.chevron_right),
        ],
      ),
    );
    if (onTap == null) return tile;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: tile,
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
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
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
    _cityController = TextEditingController(text: profile?.city ?? '');
    _stateController = TextEditingController(text: profile?.state ?? '');
    _countryController = TextEditingController(
      text: profile?.country?.trim().isNotEmpty == true
          ? profile!.country!
          : 'Brasil',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
                    strings.driverProfile,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.pick(
                      pt: 'Deixe seu nome e foto do jeito que voce quer aparecer no app.',
                      en: 'Set your name and photo the way you want to appear in the app.',
                      es: 'Deja tu nombre y foto como quieres aparecer en la app.',
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        ProfileAvatar(
                          displayName:
                              _displayNameController.text.trim().isEmpty
                              ? 'Entregador'
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
                              label: Text(
                                strings.pick(
                                  pt: 'Alterar foto',
                                  en: 'Change photo',
                                  es: 'Cambiar foto',
                                ),
                              ),
                            ),
                            if ((profile?.avatarUrl ?? '').trim().isNotEmpty)
                              TextButton(
                                onPressed: (_saving || _uploadingAvatar)
                                    ? null
                                    : _removeAvatar,
                                child: Text(
                                  strings.pick(
                                    pt: 'Remover foto',
                                    en: 'Remove photo',
                                    es: 'Quitar foto',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: strings.pick(
                        pt: 'Nome exibido',
                        en: 'Display name',
                        es: 'Nombre visible',
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: strings.pick(
                        pt: 'Nome completo',
                        en: 'Full name',
                        es: 'Nombre completo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: strings.pick(
                        pt: 'Telefone',
                        en: 'Phone',
                        es: 'Telefono',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.pick(
                      pt: 'Regiao da sua rotina',
                      en: 'Your work region',
                      es: 'Region de tu rutina',
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final fields = [
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Cidade',
                              en: 'City',
                              es: 'Ciudad',
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Estado',
                              en: 'State',
                              es: 'Estado',
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Pais',
                              en: 'Country',
                              es: 'Pais',
                            ),
                          ),
                        ),
                      ];

                      if (compact) {
                        return Column(
                          children: [
                            for (final field in fields) ...[
                              field,
                              if (field != fields.last)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          for (final field in fields) ...[
                            Expanded(child: field),
                            if (field != fields.last) const SizedBox(width: 12),
                          ],
                        ],
                      );
                    },
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
                              : Text(
                                  strings.pick(
                                    pt: 'Salvar perfil',
                                    en: 'Save profile',
                                    es: 'Guardar perfil',
                                  ),
                                ),
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
    final strings = AppStrings.of(context);

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.updateProfile(
        displayName: _displayNameController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
      );
      await session.refreshProfile();
      if (!mounted) return;
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'Perfil atualizado com sucesso.',
              en: 'Profile updated successfully.',
              es: 'Perfil actualizado correctamente.',
            ),
          ),
        ),
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
  final _bannerController = TextEditingController();
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
    _bannerController.dispose();
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
        _bannerController.text = settings.publicBannerUrl ?? '';
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
    final strings = AppStrings.of(context);
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
                          strings.publicProfile,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.pick(
                            pt: 'Escolha como outros entregadores vao te encontrar. Seus ganhos continuam privados.',
                            en: 'Choose how other drivers find you. Your earnings stay private.',
                            es: 'Elige como otros conductores te encuentran. Tus ingresos siguen privados.',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            strings.pick(
                              pt: 'Perfil publico ativo',
                              en: 'Public profile on',
                              es: 'Perfil publico activo',
                            ),
                          ),
                          subtitle: Text(
                            strings.pick(
                              pt: 'Mostra seu nome, foto, cidade e conquistas.',
                              en: 'Shows your name, photo, city and achievements.',
                              es: 'Muestra tu nombre, foto, ciudad y conquistas.',
                            ),
                          ),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                        TextFormField(
                          controller: _slugController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Seu @ no Omnya Driver',
                              en: 'Your @ on Omnya Driver',
                              es: 'Tu @ en Omnya Driver',
                            ),
                            hintText: 'ex: yan-driver',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Cidade',
                              en: 'City',
                              es: 'Ciudad',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bannerController,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Cor do banner',
                              en: 'Profile banner',
                              es: 'Banner del perfil',
                            ),
                            hintText: strings.pick(
                              pt: 'ex: #001BFF',
                              en: 'e.g. #001BFF',
                              es: 'ej: #001BFF',
                            ),
                            helperText: strings.pick(
                              pt: 'O visual do perfil publico segue a ideia de banner, como no Discord.',
                              en: 'Your public profile uses this as a Discord-like banner style.',
                              es: 'Tu perfil publico usa esto como un banner estilo Discord.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: strings.pick(
                              pt: 'Sobre voce',
                              en: 'About you',
                              es: 'Sobre ti',
                            ),
                            hintText: strings.pick(
                              pt: 'Conte rapidinho como e seu corre.',
                              en: 'Tell people briefly how you work.',
                              es: 'Cuenta rapido como es tu rutina.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            strings.pick(
                              pt: 'Participar do ranking',
                              en: 'Join the ranking',
                              es: 'Participar del ranking',
                            ),
                          ),
                          subtitle: Text(
                            strings.pick(
                              pt: 'Seu nome pode aparecer no placar da comunidade.',
                              en: 'Your name can appear on the community board.',
                              es: 'Tu nombre puede aparecer en el ranking de la comunidad.',
                            ),
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
                                child: Text(strings.cancel),
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
                                    : Text(
                                        strings.pick(
                                          pt: 'Salvar perfil',
                                          en: 'Save profile',
                                          es: 'Guardar perfil',
                                        ),
                                      ),
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
    if (_enabled && _slugController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Escolha um @ para ativar seu perfil publico.',
          en: 'Choose an @ to activate your public profile.',
          es: 'Elige un @ para activar tu perfil publico.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final available = await _service.isSlugAvailable(_slugController.text);
      if (!available) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _errorMessage = AppStrings.of(context).pick(
            pt: 'Esse @ ja esta em uso. Escolha outro para continuar.',
            en: 'This @ is already taken. Choose another one to continue.',
            es: 'Ese @ ya esta en uso. Elige otro para continuar.',
          );
        });
        return;
      }

      await _service.updateSettings(
        publicProfileEnabled: _enabled,
        publicSlug: _slugController.text,
        publicBio: _bioController.text,
        publicCity: _cityController.text,
        publicBannerUrl: _bannerController.text,
        rankingOptIn: _rankingOptIn,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: 'Perfil publico atualizado com sucesso.',
              en: 'Public profile updated.',
              es: 'Perfil publico actualizado.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Nao consegui salvar agora. Tente de novo em instantes.',
          en: 'Could not save right now. Try again in a moment.',
          es: 'No pude guardar ahora. Intenta de nuevo en un momento.',
        );
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
    final format = AppFormat.of(context);
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
                Text(
                  strings.pick(
                    pt: 'Reserva automatica',
                    en: 'Automatic reserve',
                    es: 'Reserva automatica',
                  ),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.pick(
                    pt: 'Escolha quanto voce costuma guardar para despesa, meta ou seguranca.',
                    en: 'Choose how much you usually set aside for expenses, goals or safety.',
                    es: 'Elige cuanto sueles guardar para gastos, metas o seguridad.',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: Text(
                        strings.pick(
                          pt: 'Sem reserva',
                          en: 'No reserve',
                          es: 'Sin reserva',
                        ),
                      ),
                      selected: _mode == DriverReserveMode.none,
                      onSelected: (_) =>
                          setState(() => _mode = DriverReserveMode.none),
                    ),
                    ChoiceChip(
                      label: Text(
                        strings.pick(
                          pt: '% do que sobrar',
                          en: '% of what is left',
                          es: '% de lo que sobra',
                        ),
                      ),
                      selected: _mode == DriverReserveMode.dailyPercent,
                      onSelected: (_) => setState(
                        () => _mode = DriverReserveMode.dailyPercent,
                      ),
                    ),
                    ChoiceChip(
                      label: Text(
                        strings.pick(
                          pt: 'Valor por entrega',
                          en: 'Amount per delivery',
                          es: 'Valor por entrega',
                        ),
                      ),
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
                    decoration: const InputDecoration(suffixText: '%').copyWith(
                      labelText: strings.pick(
                        pt: 'Percentual do que sobrar',
                        en: 'Percent of what is left',
                        es: 'Porcentaje de lo que sobra',
                      ),
                      hintText: strings.pick(
                        pt: 'Ex: 30',
                        en: 'Ex: 30',
                        es: 'Ej: 30',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.pick(
                      pt: 'A sugestao usa o valor que sobrou no periodo atual.',
                      en: 'The suggestion uses what is left in the current period.',
                      es: 'La sugerencia usa lo que sobra en el periodo actual.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_mode == DriverReserveMode.perDeliveryFixed) ...[
                  TextFormField(
                    controller: _perDeliveryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: strings.pick(
                        pt: 'Valor reservado por entrega',
                        en: 'Reserved amount per delivery',
                        es: 'Valor reservado por entrega',
                      ),
                      hintText: strings.pick(
                        pt: 'Ex: 2.50',
                        en: 'Ex: 2.50',
                        es: 'Ej: 2.50',
                      ),
                      prefixText:
                          '${format.currency(0).replaceAll(RegExp(r'[0-9.,\s]'), '')} ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.pick(
                      pt: 'Cada entrega concluida gera uma sugestao proporcional ao valor definido por voce.',
                      en: 'Each completed delivery creates a suggestion based on the amount you set.',
                      es: 'Cada entrega terminada crea una sugerencia segun el valor definido por ti.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_mode == DriverReserveMode.none)
                  Text(
                    strings.pick(
                      pt: 'Nenhuma reserva automatica sera sugerida no painel ou nas notificacoes.',
                      en: 'No automatic reserve will be suggested on the dashboard or notifications.',
                      es: 'No se sugerira reserva automatica en el panel ni en las notificaciones.',
                    ),
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
                            : Text(
                                strings.pick(
                                  pt: 'Salvar regra',
                                  en: 'Save rule',
                                  es: 'Guardar regla',
                                ),
                              ),
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
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Informe um percentual valido entre 0 e 100.',
          en: 'Enter a valid percentage between 0 and 100.',
          es: 'Ingresa un porcentaje valido entre 0 y 100.',
        );
      });
      return;
    }

    if (_mode == DriverReserveMode.perDeliveryFixed &&
        (perDelivery == null || perDelivery < 0)) {
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Informe um valor valido por entrega.',
          en: 'Enter a valid amount per delivery.',
          es: 'Ingresa un valor valido por entrega.',
        );
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
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: 'Preferencia de reserva atualizada com sucesso.',
              en: 'Reserve preference updated.',
              es: 'Preferencia de reserva actualizada.',
            ),
          ),
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
