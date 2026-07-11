import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../funcionalidade/auth/auth_form_mode.dart';
import '../funcionalidade/auth/captcha_service.dart';
import '../models/oauth_provider_option.dart';
import '../models/turnstile_flow.dart';
import '../utilities/state/app_session.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';
const _googleIconAsset = 'src/icons/google.webp';
const _microsoftIconAsset = 'src/icons/microsoft.png';

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
  AuthFormMode _mode = AuthFormMode.signIn;

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
    final isRegister = _mode == AuthFormMode.signUp;
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020409), Color(0xFF07101E), Color(0xFF0000CD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0000CD).withValues(alpha: 0.24),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                _driverLogoAsset,
                                width: 72,
                                height: 72,
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  'OmnyaTech Driver Platform',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Mobilidade com inteligencia operacional.',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  height: 1.14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Controle jornadas, metas e custos em uma experiencia pensada para a identidade OmnyaTech.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.76),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 36,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
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
                            const SizedBox(height: 20),
                            Text(
                              'Omnya Driver',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRegister
                                  ? 'Crie sua conta e inicie o onboarding do motorista.'
                                  : 'Entre com seguranca para acessar seu painel.',
                            ),
                            const SizedBox(height: 24),
                            SegmentedButton<AuthFormMode>(
                              segments: const [
                                ButtonSegment(
                                  value: AuthFormMode.signIn,
                                  label: Text('Entrar'),
                                ),
                                ButtonSegment(
                                  value: AuthFormMode.signUp,
                                  label: Text('Cadastrar'),
                                ),
                              ],
                              selected: {_mode},
                              onSelectionChanged: session.isBusy
                                  ? null
                                  : (selection) {
                                      setState(() => _mode = selection.first);
                                    },
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (isRegister) ...[
                                    TextFormField(
                                      controller: _fullNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome completo',
                                      ),
                                      validator: (value) {
                                        if (!isRegister) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Informe seu nome.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Informe seu e-mail.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: isRegister
                                          ? 'Crie uma senha'
                                          : 'Senha',
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Informe sua senha.';
                                      }
                                      if (isRegister && value.length < 6) {
                                        return 'Use pelo menos 6 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: session.isBusy ? null : _submit,
                                child: session.isBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isRegister
                                            ? 'Criar conta e continuar'
                                            : 'Entrar',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: theme.dividerColor),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('ou'),
                                ),
                                Expanded(
                                  child: Divider(color: theme.dividerColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                _SocialLoginButton(
                                  assetPath: _googleIconAsset,
                                  label: 'Continuar com Google',
                                  onPressed: session.isBusy
                                      ? null
                                      : () => _signInWithOAuth(
                                          OauthProviderOption.google,
                                        ),
                                ),
                                const SizedBox(height: 10),
                                _SocialLoginButton(
                                  assetPath: _microsoftIconAsset,
                                  label: 'Continuar com Microsoft',
                                  onPressed: session.isBusy
                                      ? null
                                      : () => _signInWithOAuth(
                                          OauthProviderOption.microsoft,
                                        ),
                                ),
                              ],
                            ),
                            if (session.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                session.errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _AuthStatusPanel(
                              supabaseConfigured: session.supabaseConfigured,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = await _captchaService.obtainToken(
      context,
      siteKey: SupabaseRuntimeConfig.turnstileSiteKey,
      flow: _mode == AuthFormMode.signUp
          ? TurnstileFlow.register
          : TurnstileFlow.login,
    );

    if (!mounted || token == null || token.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    if (_mode == AuthFormMode.signUp) {
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
            'Conta criada. Se o projeto exigir confirmacao de e-mail, finalize pelo link recebido.',
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
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.68 : 1,
          ),
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(assetPath, width: 22, height: 22),
            ),
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

class _AuthStatusPanel extends StatelessWidget {
  const _AuthStatusPanel({required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado da autenticacao',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            supabaseConfigured
                ? 'Supabase e Turnstile estao conectados ao app.'
                : 'Supabase ainda nao esta configurado no ambiente atual.',
          ),
          const SizedBox(height: 6),
          const Text(
            'Fluxos ativos nesta etapa: e-mail e senha, Google, Microsoft e captcha endurecido no Flutter.',
          ),
        ],
      ),
    );
  }
}
