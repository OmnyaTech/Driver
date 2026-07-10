import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../funcionalidade/auth/auth_form_mode.dart';
import '../funcionalidade/auth/captcha_service.dart';
import '../models/oauth_provider_option.dart';
import '../models/turnstile_flow.dart';
import '../utilities/state/app_session.dart';

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF081C15), Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omnya Driver',
                          style: Theme.of(context).textTheme.headlineMedium,
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
                                    if (value == null || value.trim().isEmpty) {
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
                                  if (value == null || value.trim().isEmpty) {
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
                              child: Divider(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou'),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: session.isBusy
                                  ? null
                                  : () => _signInWithOAuth(
                                      OauthProviderOption.google,
                                    ),
                              icon: const Icon(Icons.g_mobiledata),
                              label: const Text('Google'),
                            ),
                            OutlinedButton.icon(
                              onPressed: session.isBusy
                                  ? null
                                  : () => _signInWithOAuth(
                                      OauthProviderOption.microsoft,
                                    ),
                              icon: const Icon(Icons.window_outlined),
                              label: const Text('Microsoft'),
                            ),
                          ],
                        ),
                        if (session.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            session.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
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
            ),
          ),
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
