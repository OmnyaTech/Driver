import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../funcionalidade/developer/developer_access_screen.dart';
import '../funcionalidade/platforms/platforms_screen.dart';
import '../funcionalidade/subscriptions/subscriptions_screen.dart';
import '../funcionalidade/vehicles/vehicles_screen.dart';
import '../services/profile_service.dart';
import '../utilities/guards/developer_guard.dart';
import '../utilities/state/app_session.dart';

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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initial(profile?.displayName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
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

  String _initial(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return 'O';
    return normalized[0].toUpperCase();
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
  late final TextEditingController _displayNameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
  }
}
