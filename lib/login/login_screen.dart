import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../funcionalidade/auth/captcha_service.dart';
import '../models/oauth_provider_option.dart';
import '../models/turnstile_flow.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_visuals.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';
const _googleIconAsset = 'src/icons/google.webp';
const _microsoftIconAsset = 'src/icons/microsoft.png';

enum _LoginPanelMode { signIn, signUp, recover }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captchaService = const CaptchaService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginPanelMode _mode = _LoginPanelMode.signIn;

  bool get _isRegister => _mode == _LoginPanelMode.signUp;
  bool get _isRecovering => _mode == _LoginPanelMode.recover;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                    ? Column(
                        children: [
                          _LoginHero(compact: true),
                          const SizedBox(height: 18),
                          _AccessCard(
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
                          ),
                        ],
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
    setState(() => _mode = mode);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = await _captchaService.obtainToken(
      context,
      siteKey: SupabaseRuntimeConfig.turnstileSiteKey,
      flow: _isRegister ? TurnstileFlow.register : TurnstileFlow.login,
    );

    if (!mounted || token == null || token.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    if (_isRecovering) {
      final sent = await session.resetPasswordForEmail(
        email: _emailController.text.trim(),
        captchaToken: token,
      );
      if (!mounted || !sent) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enviamos o link para seu e-mail. Abra por la para criar uma nova senha.',
          ),
        ),
      );
      setState(() => _mode = _LoginPanelMode.signIn);
      return;
    }

    if (_isRegister) {
      await session.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        captchaToken: token,
      );
      if (!mounted || session.errorMessage != null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conta criada. Se chegar um e-mail de confirmacao, toque no link para liberar o acesso.',
          ),
        ),
      );
      return;
    }

    await session.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      captchaToken: token,
    );
  }

  Future<void> _signInWithOAuth(OauthProviderOption provider) async {
    final token = await _captchaService.obtainToken(
      context,
      siteKey: SupabaseRuntimeConfig.turnstileSiteKey,
      flow: TurnstileFlow.oauth,
    );

    if (!mounted || token == null || token.isEmpty) {
      return;
    }

    await context.read<AppSession>().signInWithOAuth(
      provider,
      verificationToken: token,
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OmnyaAnimatedEntrance(
      child: OmnyaHeroCard(
        compact: compact,
        padding: EdgeInsets.all(compact ? 22 : 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 58 : 72,
                  height: compact ? 58 : 72,
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
                        'Omnya Driver',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: compact ? 20 : 24,
                        ),
                      ),
                      Text(
                        'By OmnyaTech',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 24 : 44),
            Text(
              'Seu corre no controle. Sem planilha, sem bagunca.',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                height: 1.08,
                fontSize: compact ? 26 : 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entre, registre a jornada e veja rapidinho quanto entrou, quanto sobrou e onde vale melhorar amanha.',
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
            if (!compact) ...[
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
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onOAuth,
  });

  final GlobalKey<FormState> formKey;
  final _LoginPanelMode mode;
  final bool isBusy;
  final String? errorMessage;
  final bool supabaseConfigured;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<_LoginPanelMode> onModeChanged;
  final VoidCallback onSubmit;
  final ValueChanged<OauthProviderOption> onOAuth;

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
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 20),
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
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: isRegister ? 'Crie uma senha' : 'Senha',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite sua senha.';
                        }
                        if (isRegister && value.length < 6) {
                          return 'Use pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
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
              _SocialLoginButton(
                assetPath: _googleIconAsset,
                label: 'Google',
                onPressed: isBusy
                    ? null
                    : () => onOAuth(OauthProviderOption.google),
              ),
              const SizedBox(height: 10),
              _SocialLoginButton(
                assetPath: _microsoftIconAsset,
                label: 'Microsoft',
                onPressed: isBusy
                    ? null
                    : () => onOAuth(OauthProviderOption.microsoft),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _InlineMessage(message: errorMessage!, isError: true),
            ],
            const SizedBox(height: 16),
            _AuthStatusPanel(supabaseConfigured: supabaseConfigured),
          ],
        ),
      ),
    );
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
