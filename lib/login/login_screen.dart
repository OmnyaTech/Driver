import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../funcionalidade/auth/captcha_service.dart';
import '../models/oauth_provider_option.dart';
import '../models/turnstile_flow.dart';
import '../services/biometric_lock_service.dart';
import '../services/saved_login_service.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_visuals.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';
const _googleIconAsset = 'src/icons/google.webp';
const _microsoftIconAsset = 'src/icons/microsoft.png';

enum _LoginPanelMode { signIn, signUp, recover }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.startInSignUp = false,
    this.downloadMode = false,
  });

  final bool startInSignUp;
  final bool downloadMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captchaService = const CaptchaService();
  final _biometricLockService = BiometricLockService();
  final _savedLoginService = SavedLoginService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late _LoginPanelMode _mode;
  String? _feedbackMessage;
  String? _pendingConfirmationEmail;
  bool _feedbackIsError = false;
  bool _obscurePassword = true;
  bool _saveLogin = false;
  bool _biometricLoginAvailable = false;
  bool _biometricLoginBusy = false;
  SavedLoginCredentials? _savedCredentials;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  bool get _isRegister => _mode == _LoginPanelMode.signUp;
  bool get _isRecovering => _mode == _LoginPanelMode.recover;

  @override
  void initState() {
    super.initState();
    _mode = widget.startInSignUp
        ? _LoginPanelMode.signUp
        : _LoginPanelMode.signIn;
    _loadSavedLogin();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final compact = MediaQuery.sizeOf(context).width < 780;

    return Scaffold(
      body: OmnyaAtmosphere(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 32,
                24,
                compact ? 18 : 32,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: compact
                    ? _AccessCard(
                        formKey: _formKey,
                        mode: _mode,
                        isBusy: session.isBusy,
                        errorMessage: session.errorMessage,
                        supabaseConfigured: session.supabaseConfigured,
                        showStatusPanel: false,
                        fullNameController: _fullNameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        onModeChanged: _setMode,
                        onSubmit: _submit,
                        onOAuth: _signInWithOAuth,
                        onResendConfirmation: _resendConfirmationEmail,
                        feedbackMessage: _feedbackMessage,
                        pendingConfirmationEmail: _pendingConfirmationEmail,
                        feedbackIsError: _feedbackIsError,
                        resendCooldown: _resendCooldown,
                        downloadMode: widget.downloadMode,
                        obscurePassword: _obscurePassword,
                        onTogglePasswordVisibility: _togglePasswordVisibility,
                        saveLogin: _saveLogin,
                        onSaveLoginChanged: _setSaveLogin,
                        biometricLoginAvailable: _biometricLoginAvailable,
                        biometricLoginBusy: _biometricLoginBusy,
                        onBiometricLogin: _signInWithBiometric,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: _LoginHero()),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _AccessCard(
                              formKey: _formKey,
                              mode: _mode,
                              isBusy: session.isBusy,
                              errorMessage: session.errorMessage,
                              supabaseConfigured: session.supabaseConfigured,
                              fullNameController: _fullNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              onModeChanged: _setMode,
                              onSubmit: _submit,
                              onOAuth: _signInWithOAuth,
                              onResendConfirmation: _resendConfirmationEmail,
                              feedbackMessage: _feedbackMessage,
                              pendingConfirmationEmail:
                                  _pendingConfirmationEmail,
                              feedbackIsError: _feedbackIsError,
                              resendCooldown: _resendCooldown,
                              downloadMode: widget.downloadMode,
                              obscurePassword: _obscurePassword,
                              onTogglePasswordVisibility:
                                  _togglePasswordVisibility,
                              saveLogin: _saveLogin,
                              onSaveLoginChanged: _setSaveLogin,
                              biometricLoginAvailable: _biometricLoginAvailable,
                              biometricLoginBusy: _biometricLoginBusy,
                              onBiometricLogin: _signInWithBiometric,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setMode(_LoginPanelMode mode) {
    setState(() {
      _mode = mode;
      _feedbackMessage = null;
      if (mode != _LoginPanelMode.signUp) {
        _pendingConfirmationEmail = null;
      }
      _feedbackIsError = false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _setSaveLogin(bool? value) {
    setState(() => _saveLogin = value ?? false);
    if (_saveLogin) return;
    setState(() {
      _savedCredentials = null;
      _biometricLoginAvailable = false;
    });
    unawaited(_savedLoginService.clear());
  }

  Future<void> _loadSavedLogin() async {
    final credentials = await _savedLoginService.load();
    if (!mounted || credentials == null || !credentials.isNotEmpty) return;
    final canUseDeviceLock = await _biometricLockService.canUseDeviceLock();
    if (!mounted) return;
    setState(() {
      _savedCredentials = credentials;
      _emailController.text = credentials.email;
      _passwordController.text = credentials.password;
      _saveLogin = true;
      _biometricLoginAvailable = canUseDeviceLock;
    });
  }

  Future<void> _signInWithBiometric() async {
    final credentials = _savedCredentials;
    if (_biometricLoginBusy || credentials == null) return;

    setState(() => _biometricLoginBusy = true);
    final unlocked = await _biometricLockService.unlock();
    if (!mounted) return;

    if (!unlocked) {
      setState(() => _biometricLoginBusy = false);
      _setFeedback('Nao foi possivel confirmar sua identidade.');
      return;
    }

    setState(() {
      _mode = _LoginPanelMode.signIn;
      _emailController.text = credentials.email;
      _passwordController.text = credentials.password;
      _saveLogin = true;
    });

    await _submit();
    if (mounted) setState(() => _biometricLoginBusy = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setFeedback('Validando seguranca do app...', isError: false);
    final token = await _captchaService.obtainToken(
      context,
      siteKey: SupabaseRuntimeConfig.turnstileSiteKey,
      flow: _isRegister ? TurnstileFlow.register : TurnstileFlow.login,
    );

    if (!mounted || token == null || token.isEmpty) {
      _setFeedback(
        'Nao foi possivel concluir a verificacao de seguranca. Tente novamente.',
      );
      return;
    }

    final session = context.read<AppSession>();
    if (_isRecovering) {
      _setFeedback('Enviando link de recuperacao...', isError: false);
      final sent = await session.resetPasswordForEmail(
        email: _emailController.text.trim(),
        captchaToken: token,
      );
      if (!mounted || !sent) {
        _showAuthError(session.errorMessage);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enviamos o link para seu e-mail. Abra por la para criar uma nova senha.',
          ),
        ),
      );
      _setFeedback('Link enviado para seu e-mail.', isError: false);
      setState(() => _mode = _LoginPanelMode.signIn);
      return;
    }

    if (_isRegister) {
      _setFeedback('Criando sua conta...', isError: false);
      await session.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        captchaToken: token,
      );
      if (!mounted || session.errorMessage != null) {
        _showAuthError(session.errorMessage);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enviamos um e-mail de confirmacao. Abra o link para liberar o acesso.',
          ),
        ),
      );
      _setFeedback(
        'Confira seu e-mail para confirmar o acesso.',
        isError: false,
      );
      setState(() => _pendingConfirmationEmail = _emailController.text.trim());
      _startResendCooldown();
      return;
    }

    _setFeedback('Entrando no Driver...', isError: false);
    final signedIn = await session.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      captchaToken: token,
    );
    if (!mounted) return;
    if (signedIn) {
      if (_saveLogin) {
        await _savedLoginService.save(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _savedCredentials = SavedLoginCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _savedLoginService.clear();
      }
      _setFeedback('Login bem sucedido. Abrindo o app...', isError: false);
      return;
    }
    _showAuthError(session.errorMessage);
  }

  Future<void> _signInWithOAuth(OauthProviderOption provider) async {
    String token = 'native-oauth';
    if (kIsWeb) {
      _setFeedback('Validando seguranca do app...', isError: false);
      final webToken = await _captchaService.obtainToken(
        context,
        siteKey: SupabaseRuntimeConfig.turnstileSiteKey,
        flow: TurnstileFlow.oauth,
      );

      if (!mounted || webToken == null || webToken.isEmpty) {
        _setFeedback(
          'Nao foi possivel concluir a verificacao de seguranca. Tente novamente.',
        );
        return;
      }
      token = webToken;
    }

    _setFeedback(
      'Abrindo ${provider == OauthProviderOption.google ? 'Google' : 'Microsoft'}...',
      isError: false,
    );
    final started = await context.read<AppSession>().signInWithOAuth(
      provider,
      verificationToken: token,
    );
    if (!mounted || started) return;
    _showAuthError(context.read<AppSession>().errorMessage);
  }

  void _showAuthError(String? message) {
    if (!mounted || message == null || message.trim().isEmpty) return;
    final friendly = _friendlyAuthMessage(message);
    _setFeedback(friendly);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendly), behavior: SnackBarBehavior.floating),
    );
  }

  void _setFeedback(String message, {bool isError = true}) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
  }

  String _friendlyAuthMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid credentials')) {
      return 'E-mail ou senha incorretos. Confira os dados e tente novamente.';
    }
    if (normalized.contains('email not confirmed') ||
        normalized.contains('not confirmed')) {
      return "Seu e-mail ainda nao foi confirmado. Verifique sua caixa de entrada ou toque em 'Reenviar confirmacao' abaixo.";
    }
    if (normalized.contains('captcha') || normalized.contains('challenge')) {
      return 'A verificacao de seguranca falhou. Tente novamente.';
    }
    return message;
  }

  Future<void> _resendConfirmationEmail() async {
    final email = (_pendingConfirmationEmail ?? _emailController.text).trim();
    if (email.isEmpty || _resendCooldown > 0) return;
    final sent = await context.read<AppSession>().resendSignupConfirmation(
      email: email,
    );
    if (!mounted) return;
    if (sent) {
      _setFeedback(
        'Reenviamos a confirmacao. Verifique inbox e spam.',
        isError: false,
      );
      _startResendCooldown();
      return;
    }
    _showAuthError(context.read<AppSession>().errorMessage);
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
        return;
      }
      setState(() => _resendCooldown--);
    });
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OmnyaAnimatedEntrance(
      child: OmnyaHeroCard(
        padding: const EdgeInsets.all(34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Image.asset(_driverLogoAsset),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'Driver',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),
            Text(
              'Seu corre no controle. Sem planilha, sem bagunca.',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                height: 1.08,
                fontSize: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entre, registre a jornada e veja rapidinho quanto entrou, quanto lucrou e onde vale melhorar amanha.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                OmnyaGlowChip(label: 'Jornadas'),
                OmnyaGlowChip(label: 'Metas'),
                OmnyaGlowChip(label: 'Ranking'),
                OmnyaGlowChip(label: 'Premium'),
              ],
            ),
            const SizedBox(height: 34),
            Row(
              children: const [
                Expanded(
                  child: _HeroMiniStat(
                    title: 'Hoje',
                    value: 'R\$',
                    detail: 'Ganhos e sobras do dia',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HeroMiniStat(
                    title: 'Progresso',
                    value: 'XP',
                    detail: 'Missoes, medalhas e ranking',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.formKey,
    required this.mode,
    required this.isBusy,
    required this.errorMessage,
    required this.supabaseConfigured,
    this.showStatusPanel = true,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onOAuth,
    required this.onResendConfirmation,
    this.feedbackMessage,
    this.pendingConfirmationEmail,
    this.feedbackIsError = false,
    this.resendCooldown = 0,
    this.downloadMode = false,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.saveLogin,
    required this.onSaveLoginChanged,
    required this.biometricLoginAvailable,
    required this.biometricLoginBusy,
    required this.onBiometricLogin,
  });

  final GlobalKey<FormState> formKey;
  final _LoginPanelMode mode;
  final bool isBusy;
  final String? errorMessage;
  final bool supabaseConfigured;
  final bool showStatusPanel;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<_LoginPanelMode> onModeChanged;
  final VoidCallback onSubmit;
  final ValueChanged<OauthProviderOption> onOAuth;
  final VoidCallback onResendConfirmation;
  final String? feedbackMessage;
  final String? pendingConfirmationEmail;
  final bool feedbackIsError;
  final int resendCooldown;
  final bool downloadMode;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final bool saveLogin;
  final ValueChanged<bool?> onSaveLoginChanged;
  final bool biometricLoginAvailable;
  final bool biometricLoginBusy;
  final VoidCallback onBiometricLogin;

  bool get isRegister => mode == _LoginPanelMode.signUp;
  bool get isRecovering => mode == _LoginPanelMode.recover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (mode) {
      _LoginPanelMode.signUp => 'Criar conta',
      _LoginPanelMode.recover => 'Recuperar acesso',
      _ => 'Entrar no app',
    };
    final subtitle = switch (mode) {
      _LoginPanelMode.signUp =>
        'Leva menos de um minuto para deixar seu painel pronto.',
      _LoginPanelMode.recover =>
        'Informe seu e-mail e a gente envia o caminho para trocar a senha.',
      _ => 'Continue com seu e-mail ou entre direto com Google/Microsoft.',
    };

    return OmnyaAnimatedEntrance(
      delay: const Duration(milliseconds: 90),
      child: OmnyaGlassCard(
        highlight: true,
        borderRadius: 32,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        OmnyaVisualTokens.omnyaPrimaryDark,
                        OmnyaVisualTokens.electricBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: OmnyaVisualTokens.electricBlue.withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isRecovering
                      ? const Icon(Icons.lock_reset, color: Colors.white)
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(_driverLogoAsset),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (downloadMode && isRegister) ...[
              _DownloadEmailNotice(
                pendingEmail: pendingConfirmationEmail,
                resendCooldown: resendCooldown,
                onResend: isBusy ? null : onResendConfirmation,
              ),
              const SizedBox(height: 16),
            ],
            if (!isRecovering) ...[
              _ModeTabs(mode: mode, onChanged: isBusy ? null : onModeChanged),
              const SizedBox(height: 20),
            ],
            Form(
              key: formKey,
              child: Column(
                children: [
                  if (isRegister) ...[
                    TextFormField(
                      controller: fullNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        labelText: 'Nome completo',
                      ),
                      validator: (value) {
                        if (!isRegister) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: emailController,
                    textInputAction: isRecovering
                        ? TextInputAction.done
                        : TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline),
                      labelText: 'E-mail',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite seu e-mail.';
                      }
                      if (!value.contains('@')) {
                        return 'Confira se o e-mail esta certo.';
                      }
                      return null;
                    },
                  ),
                  if (!isRecovering) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      textInputAction: TextInputAction.done,
                      autofillHints: isRegister
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: isRegister ? 'Crie uma senha' : 'Senha',
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: onTogglePasswordVisibility,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite sua senha.';
                        }
                        if (isRegister) {
                          final passwordError = _validateStrongPassword(value);
                          if (passwordError != null) return passwordError;
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (mode == _LoginPanelMode.signIn) ...[
              CheckboxListTile(
                value: saveLogin,
                onChanged: isBusy ? null : onSaveLoginChanged,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Salvar login neste aparelho'),
                subtitle: const Text(
                  'Deixa e-mail e senha preenchidos na proxima entrada.',
                ),
              ),
              const SizedBox(height: 4),
              if (biometricLoginAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isBusy || biometricLoginBusy
                        ? null
                        : onBiometricLogin,
                    icon: biometricLoginBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: const Text('Entrar com biometria'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (!isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () => onModeChanged(
                          isRecovering
                              ? _LoginPanelMode.signIn
                              : _LoginPanelMode.recover,
                        ),
                  child: Text(
                    isRecovering ? 'Voltar para entrar' : 'Esqueci minha senha',
                  ),
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onSubmit,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isRecovering ? Icons.send_outlined : Icons.login),
                label: Text(switch (mode) {
                  _LoginPanelMode.signUp => 'Criar conta e continuar',
                  _LoginPanelMode.recover => 'Enviar link seguro',
                  _ => 'Entrar',
                }),
              ),
            ),
            if (!isRecovering) ...[
              const SizedBox(height: 18),
              if (isRegister) ...[
                Text(
                  'Ao continuar, voce concorda com os Termos de Uso e a Politica de Privacidade. Se o cadastro for por e-mail, enviaremos um link de confirmacao; verifique tambem a caixa de spam.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou continue com',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 430;
                  final buttons = [
                    _SocialLoginButton(
                      assetPath: _googleIconAsset,
                      label: 'Google',
                      onPressed: isBusy
                          ? null
                          : () => onOAuth(OauthProviderOption.google),
                    ),
                    _SocialLoginButton(
                      assetPath: _microsoftIconAsset,
                      label: 'Microsoft',
                      onPressed: isBusy
                          ? null
                          : () => onOAuth(OauthProviderOption.microsoft),
                    ),
                  ];

                  if (stacked) {
                    return Column(
                      children: [
                        buttons.first,
                        const SizedBox(height: 10),
                        buttons.last,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: buttons.first),
                      const SizedBox(width: 10),
                      Expanded(child: buttons.last),
                    ],
                  );
                },
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _InlineMessage(message: errorMessage!, isError: true),
            ],
            if (feedbackMessage != null) ...[
              const SizedBox(height: 16),
              _InlineMessage(
                message: feedbackMessage!,
                isError: feedbackIsError,
              ),
            ],
            if (showStatusPanel) ...[
              const SizedBox(height: 16),
              _AuthStatusPanel(supabaseConfigured: supabaseConfigured),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateStrongPassword(String value) {
    if (value.length < 8) {
      return 'Use no minimo 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Inclua pelo menos uma letra maiuscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Inclua pelo menos uma letra minuscula.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Inclua pelo menos um numero.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Inclua pelo menos um caractere especial.';
    }
    return null;
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final _LoginPanelMode mode;
  final ValueChanged<_LoginPanelMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTabButton(
              label: 'Entrar',
              selected: mode == _LoginPanelMode.signIn,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_LoginPanelMode.signIn),
            ),
          ),
          Expanded(
            child: _ModeTabButton(
              label: 'Cadastrar',
              selected: mode == _LoginPanelMode.signUp,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_LoginPanelMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? OmnyaVisualTokens.electricBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.assetPath,
    required this.label,
    required this.onPressed,
  });

  final String assetPath;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.58 : 1,
          ),
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 22, height: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadEmailNotice extends StatelessWidget {
  const _DownloadEmailNotice({
    required this.pendingEmail,
    required this.resendCooldown,
    required this.onResend,
  });

  final String? pendingEmail;
  final int resendCooldown;
  final VoidCallback? onResend;

  bool get _hasPendingEmail =>
      pendingEmail != null && pendingEmail!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final title = _hasPendingEmail
        ? 'Confirme seu e-mail para continuar'
        : 'Cadastre-se para liberar o APK';
    final text = _hasPendingEmail
        ? 'Enviamos um link de confirmacao para ${pendingEmail!.trim()}. Abra sua caixa de entrada ou spam, toque no link e volte aqui para liberar o download pelo MediaFire.'
        : 'Se voce criar a conta com e-mail e senha, vamos enviar um link de confirmacao. Se preferir, entre direto com Google ou Microsoft e pule essa etapa.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OmnyaVisualTokens.cyan.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OmnyaVisualTokens.cyan.withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: OmnyaVisualTokens.cyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(text),
                  ],
                ),
              ),
            ],
          ),
          if (_hasPendingEmail) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: resendCooldown > 0 ? null : onResend,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                resendCooldown > 0
                    ? 'Reenviar em ${resendCooldown}s'
                    : 'Reenviar e-mail de confirmacao',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Login com Google ou Microsoft nao precisa desse passo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : OmnyaVisualTokens.cyan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}

class _AuthStatusPanel extends StatelessWidget {
  const _AuthStatusPanel({required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.46 : 0.86,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            supabaseConfigured
                ? Icons.verified_user_outlined
                : Icons.info_outline,
            color: supabaseConfigured
                ? OmnyaVisualTokens.cyan
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supabaseConfigured
                  ? 'Acesso protegido com seguranca e pronto para uso.'
                  : 'Conecte o Supabase para liberar login e cadastro.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
