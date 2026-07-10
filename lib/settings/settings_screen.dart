import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/developer/developer_access_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/subscriptions/subscriptions_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../services/avatar_service.dart';
import '../services/profile_service.dart';
import '../services/public_profile_service.dart';
import '../utilities/guards/developer_guard.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/profile_avatar.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;
    final canOpenDeveloper = profile != null
        ? DeveloperGuard().canOpen(profile.role)
        : false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _SettingsHeroCard(session: session),
        const SizedBox(height: 18),
        _SettingsSection(
          title: 'Conta e identidade',
          children: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Perfil do motorista',
              subtitle: 'Nome, telefone e identidade publica',
              onTap: () => _openProfileSheet(context),
            ),
            _SettingsTile(
              icon: Icons.public_outlined,
              title: 'Perfil publico',
              subtitle: 'Slug, bio, cidade e preparacao para ranking',
              onTap: () => _openPublicProfileSheet(context),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Preferencias',
              subtitle: session.themeMode == ThemeMode.dark
                  ? 'Tema escuro ativo'
                  : 'Tema claro ativo',
              trailing: Switch(
                value: session.themeMode == ThemeMode.dark,
                onChanged: (_) => session.toggleThemeMode(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: 'Cadastros',
          children: [
            _SettingsTile(
              icon: Icons.two_wheeler_outlined,
              title: 'Veiculos',
              subtitle: 'Gerencie frota, status e dados do veiculo',
              onTap: () => _pushPage(context, const VehiclesScreen()),
            ),
            _SettingsTile(
              icon: Icons.storefront_outlined,
              title: 'Plataformas',
              subtitle: 'Cadastre apps, restaurantes e fontes de receita',
              onTap: () => _pushPage(context, const PlatformsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: 'Plano e suporte',
          children: [
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Assinatura',
              subtitle: 'Planos, checkout e historico de billing',
              onTap: () => _pushPage(context, const SubscriptionsScreen()),
            ),
            if (canOpenDeveloper)
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Developer',
                subtitle: 'Auditoria, lookup e controle administrativo',
                onTap: () => _pushPage(context, const DeveloperAccessScreen()),
              ),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sair da conta',
              subtitle: 'Encerrar sessao neste dispositivo',
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
}

class SettingsStandaloneScreen extends StatelessWidget {
  const SettingsStandaloneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
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
                      'Configuracoes OmnyaTech',
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
                    'Atualize sua identidade principal e mantenha o painel alinhado com a marca OmnyaTech.',
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
        _errorMessage = 'Nao foi possivel carregar o perfil publico.';
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
                          'Organize a vitrine publica sem expor ganhos e deixe o ranking pronto para a proxima etapa.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Perfil publico ativo'),
                          subtitle: const Text(
                            'Permite exibir seu nome, avatar, cidade e conquistas publicas.',
                          ),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                        TextFormField(
                          controller: _slugController,
                          decoration: const InputDecoration(
                            labelText: 'Slug publico',
                            hintText: 'ex: yan-driver',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade publica',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Bio publica',
                            hintText: 'Resumo curto do seu perfil no app.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Participar do ranking'),
                          subtitle: const Text(
                            'Opt-in para a futura exibicao no ranking publico.',
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
                                    : const Text('Salvar perfil publico'),
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
        _errorMessage = 'Nao foi possivel salvar as configuracoes agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
