import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/biometric_lock_service.dart';
import '../../services/data_privacy_service.dart';
import '../../services/mfa_service.dart';
import '../../services/security_preference_service.dart';
import '../../utilities/localization/app_strings.dart';
import '../../utilities/state/app_session.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _service = DataPrivacyService();
  final _mfaService = const MfaService();
  final _biometricLockService = BiometricLockService();
  final _securityPreferenceService = SecurityPreferenceService();
  final _reasonController = TextEditingController();
  bool _exporting = false;
  bool _requestingDeletion = false;
  bool _loadingMfa = true;
  bool _disablingMfa = false;
  bool _savingLock = false;
  String? _totpFactorId;

  @override
  void initState() {
    super.initState();
    _loadMfa();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final profile = context.watch<AppSession>().profile;
    final hasVerifiedTotp = _totpFactorId != null;
    final mfaActive = hasVerifiedTotp && profile?.totpMfaEnabled == true;

    return Scaffold(
      appBar: AppBar(title: Text(strings.securityData)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF101522), Color(0xFF0000CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_moon_outlined,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.dataStaysWithYou,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.securityHeroBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.twoFactorTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingMfa
                        ? strings.preparing
                        : (!mfaActive
                              ? strings.twoFactorDisabled
                              : strings.twoFactorEnabled),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadingMfa || _disablingMfa
                        ? null
                        : (!hasVerifiedTotp
                              ? _openMfaSetup
                              : (mfaActive ? _disableMfa : _enableExistingMfa)),
                    icon: _loadingMfa || _disablingMfa
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            !mfaActive
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                          ),
                    label: Text(
                      !mfaActive
                          ? strings.configureTwoFactor
                          : strings.disableTwoFactor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bloqueio do app', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Proteja o Omnya Driver quando sair e voltar para o app.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usar biometria ou senha do aparelho'),
                    subtitle: const Text(
                      'Pede confirmacao para abrir o app de novo.',
                    ),
                    value: profile?.biometricLockEnabled ?? false,
                    onChanged: _savingLock
                        ? null
                        : (value) =>
                              _saveLockPreferences(biometricLockEnabled: value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bloquear ao voltar para o app'),
                    subtitle: const Text(
                      'Bom para quando o celular fica desbloqueado.',
                    ),
                    value: profile?.reauthOnResume ?? true,
                    onChanged: _savingLock
                        ? null
                        : (value) =>
                              _saveLockPreferences(reauthOnResume: value),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: profile?.inactivityLockMinutes ?? 15,
                    decoration: const InputDecoration(
                      labelText: 'Bloquear depois de inatividade',
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 minutos')),
                      DropdownMenuItem(value: 15, child: Text('15 minutos')),
                      DropdownMenuItem(value: 30, child: Text('30 minutos')),
                      DropdownMenuItem(value: 60, child: Text('1 hora')),
                    ],
                    onChanged: _savingLock
                        ? null
                        : (value) {
                            if (value != null) {
                              _saveLockPreferences(
                                inactivityLockMinutes: value,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.takeMyData, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(strings.takeMyDataBody),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _exporting ? null : () => _copyExportJson(),
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.data_object_outlined),
                        label: Text(
                          _exporting ? strings.preparing : 'Copiar JSON',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exporting
                            ? null
                            : () => _copyExportMarkdown(),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Copiar Markdown'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.closeAccount,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.closeAccountBody),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: strings.reasonOptional,
                      hintText: strings.reasonHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _requestingDeletion
                        ? null
                        : _confirmDeletionRequest,
                    icon: _requestingDeletion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      _requestingDeletion
                          ? strings.sendingRequest
                          : strings.requestClosure,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMfa() async {
    setState(() => _loadingMfa = true);
    try {
      final factors = await _mfaService.listVerifiedTotpFactors();
      if (!mounted) return;
      setState(() {
        _totpFactorId = factors.isEmpty ? null : factors.first.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _totpFactorId = null);
    } finally {
      if (mounted) setState(() => _loadingMfa = false);
    }
  }

  Future<void> _openMfaSetup() async {
    final configured = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MfaSetupSheet(),
    );

    if (configured == true) {
      await _loadMfa();
      if (!mounted) return;
      await context.read<AppSession>().refreshProfile();
    }
  }

  Future<void> _disableMfa() async {
    final factorId = _totpFactorId;
    if (factorId == null) return;

    setState(() => _disablingMfa = true);
    try {
      await _mfaService.disableTotp(factorId);
      await _mfaService.setTotpMfaEnabled(false);
      await _loadMfa();
      if (!mounted) return;
      await context.read<AppSession>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA desativado com seguranca.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para desativar o 2FA: $error')),
      );
    } finally {
      if (mounted) setState(() => _disablingMfa = false);
    }
  }

  Future<void> _enableExistingMfa() async {
    if (_totpFactorId == null) return;

    setState(() => _disablingMfa = true);
    try {
      await _mfaService.setTotpMfaEnabled(true);
      if (!mounted) return;
      await context.read<AppSession>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).twoFactorEnabled)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para ativar o 2FA: $error')),
      );
    } finally {
      if (mounted) setState(() => _disablingMfa = false);
    }
  }

  Future<void> _saveLockPreferences({
    bool? biometricLockEnabled,
    int? inactivityLockMinutes,
    bool? reauthOnResume,
  }) async {
    final profile = context.read<AppSession>().profile;
    final session = context.read<AppSession>();
    if (profile == null) return;

    final nextBiometric = biometricLockEnabled ?? profile.biometricLockEnabled;
    if (nextBiometric && biometricLockEnabled == true) {
      final canUse = await _biometricLockService.canUseDeviceLock();
      if (!canUse) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ative biometria ou senha no aparelho para usar este bloqueio.',
            ),
          ),
        );
        return;
      }

      final unlocked = await _biometricLockService.unlock();
      if (!unlocked) return;
    }

    setState(() => _savingLock = true);
    try {
      await _securityPreferenceService.updateLockPreferences(
        biometricLockEnabled: nextBiometric,
        inactivityLockMinutes:
            inactivityLockMinutes ?? profile.inactivityLockMinutes,
        reauthOnResume: reauthOnResume ?? profile.reauthOnResume,
      );
      await session.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias de seguranca salvas.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nao deu para salvar: $error')));
    } finally {
      if (mounted) setState(() => _savingLock = false);
    }
  }

  Future<void> _copyExportJson() async {
    setState(() => _exporting = true);
    try {
      final exportJson = await _service.buildExportJson();
      await Clipboard.setData(ClipboardData(text: exportJson));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).backupCopied)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para gerar o backup: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyExportMarkdown() async {
    setState(() => _exporting = true);
    try {
      final exportMarkdown = await _service.buildExportMarkdown();
      await Clipboard.setData(ClipboardData(text: exportMarkdown));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup em Markdown copiado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para gerar o Markdown: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeletionRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pedir encerramento?'),
          content: const Text(
            'Isso nao apaga sua conta na hora. Vamos registrar seu pedido para a equipe cuidar com seguranca.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Agora nao'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar pedido'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _requestingDeletion = true);
    try {
      await _service.requestAccountDeletion(reason: _reasonController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido registrado. Vamos acompanhar por aqui.'),
        ),
      );
      _reasonController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para registrar o pedido: $error')),
      );
    } finally {
      if (mounted) setState(() => _requestingDeletion = false);
    }
  }
}

class _MfaSetupSheet extends StatefulWidget {
  const _MfaSetupSheet();

  @override
  State<_MfaSetupSheet> createState() => _MfaSetupSheetState();
}

class _MfaSetupSheetState extends State<_MfaSetupSheet> {
  final _service = const MfaService();
  final _codeController = TextEditingController();
  MfaEnrollmentDraft? _draft;
  bool _loading = true;
  bool _verifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                Text(strings.twoFactorTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  strings.pick(
                    pt: 'Abra seu app autenticador, adicione uma nova conta e confirme o codigo de 6 digitos.',
                    en: 'Open your authenticator app, add a new account and confirm the 6-digit code.',
                    es: 'Abre tu app autenticadora, agrega una cuenta nueva y confirma el codigo de 6 digitos.',
                  ),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_draft != null) ...[
                  Text(
                    strings.pick(
                      pt: 'Chave manual',
                      en: 'Manual key',
                      es: 'Clave manual',
                    ),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_draft!.secret),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copy(_draft!.secret),
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(
                          strings.pick(
                            pt: 'Copiar chave',
                            en: 'Copy key',
                            es: 'Copiar clave',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _copy(_draft!.uri),
                        icon: const Icon(Icons.qr_code_2_outlined),
                        label: Text(
                          strings.pick(
                            pt: 'Copiar link do QR',
                            en: 'Copy QR link',
                            es: 'Copiar enlace QR',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: strings.pick(
                        pt: 'Codigo do autenticador',
                        en: 'Authenticator code',
                        es: 'Codigo del autenticador',
                      ),
                      counterText: '',
                    ),
                  ),
                ],
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
                        onPressed: _verifying
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading || _verifying ? null : _verify,
                        child: _verifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                strings.pick(
                                  pt: 'Ativar 2FA',
                                  en: 'Enable 2FA',
                                  es: 'Activar 2FA',
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

  Future<void> _start() async {
    try {
      final draft = await _service.startTotpEnrollment();
      if (!mounted) return;
      setState(() => _draft = draft);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(
            context,
          ).pick(pt: 'Copiado.', en: 'Copied.', es: 'Copiado.'),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final draft = _draft;
    if (draft == null) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = AppStrings.of(context).pick(
          pt: 'Informe o codigo de 6 digitos.',
          en: 'Enter the 6-digit code.',
          es: 'Ingresa el codigo de 6 digitos.',
        );
      });
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      await _service.verifyTotpEnrollment(factorId: draft.factorId, code: code);
      await _service.setTotpMfaEnabled(true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pick(
              pt: '2FA ativado. Sua conta ficou mais protegida.',
              en: '2FA enabled. Your account is safer now.',
              es: '2FA activado. Tu cuenta esta mas protegida.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }
}
