import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_profile.dart';
import '../../services/biometric_lock_service.dart';
import '../../services/mfa_service.dart';
import '../state/app_session.dart';

class AppSecurityGate extends StatefulWidget {
  const AppSecurityGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppSecurityGate> createState() => _AppSecurityGateState();
}

class _AppSecurityGateState extends State<AppSecurityGate>
    with WidgetsBindingObserver {
  final _lockService = BiometricLockService();
  final _mfaService = const MfaService();
  final _mfaCodeController = TextEditingController();
  Timer? _timer;
  bool _locked = false;
  bool _unlocking = false;
  bool _checkingMfa = false;
  bool _mfaRequired = false;
  bool _verifyingMfa = false;
  String? _mfaErrorMessage;
  String? _lastMfaCheckUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _mfaCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final profile = context.read<AppSession>().profile;
      if (profile?.biometricLockEnabled == true &&
          profile?.reauthOnResume == true) {
        setState(() {
          _locked = true;
          _lastMfaCheckUserId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppSession>().profile;
    _schedule(profile);
    _checkMfaRequirement(profile);

    if (profile?.biometricLockEnabled != true && !_mfaRequired) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _schedule(profile),
      onPointerMove: (_) => _schedule(profile),
      child: Stack(
        children: [
          widget.child,
          if (_locked) _LockOverlay(unlocking: _unlocking, onUnlock: _unlock),
          if (_mfaRequired && !_locked)
            _MfaOverlay(
              controller: _mfaCodeController,
              checking: _checkingMfa,
              verifying: _verifyingMfa,
              errorMessage: _mfaErrorMessage,
              onVerify: _verifyMfa,
            ),
        ],
      ),
    );
  }

  void _checkMfaRequirement(AppProfile? profile) {
    if (profile == null || _checkingMfa || _mfaRequired) return;
    if (profile.totpMfaEnabled != true) {
      if (_mfaRequired || _mfaErrorMessage != null) {
        setState(() {
          _mfaRequired = false;
          _mfaErrorMessage = null;
          _mfaCodeController.clear();
        });
      }
      return;
    }
    if (_lastMfaCheckUserId == profile.id) return;

    _lastMfaCheckUserId = profile.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _checkingMfa = true);
      try {
        final required = await _mfaService.requiresTotpChallenge();
        if (!mounted) return;
        setState(() {
          _mfaRequired = required;
          _mfaErrorMessage = null;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _mfaRequired = false;
          _mfaErrorMessage = null;
        });
      } finally {
        if (mounted) setState(() => _checkingMfa = false);
      }
    });
  }

  void _schedule(AppProfile? profile) {
    _timer?.cancel();
    if (profile?.biometricLockEnabled != true) return;

    final minutes = profile!.inactivityLockMinutes.clamp(1, 240);
    _timer = Timer(Duration(minutes: minutes), () {
      if (mounted) setState(() => _locked = true);
    });
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final unlocked = await _lockService.unlock();
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      _locked = !unlocked;
      if (unlocked) _lastMfaCheckUserId = null;
    });
    _schedule(context.read<AppSession>().profile);
  }

  Future<void> _verifyMfa() async {
    if (_verifyingMfa) return;
    final code = _mfaCodeController.text.trim();
    if (code.length < 6) {
      setState(
        () => _mfaErrorMessage = 'Digite os 6 numeros do app autenticador.',
      );
      return;
    }

    setState(() {
      _verifyingMfa = true;
      _mfaErrorMessage = null;
    });

    try {
      await _mfaService.verifyFirstTotpChallenge(code);
      if (!mounted) return;
      setState(() {
        _mfaRequired = false;
        _verifyingMfa = false;
        _mfaCodeController.clear();
        _lastMfaCheckUserId = context.read<AppSession>().profile?.id;
      });
      _schedule(context.read<AppSession>().profile);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingMfa = false;
        _mfaErrorMessage = 'Codigo invalido. Confira e tente de novo.';
      });
    }
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({required this.unlocking, required this.onUnlock});

  final bool unlocking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.92),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF202748), Color(0xFF0000CD)],
                        ),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'App protegido',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use sua biometria ou senha do aparelho para continuar.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: unlocking ? null : onUnlock,
                      icon: unlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_outlined),
                      label: const Text('Desbloquear'),
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
}

class _MfaOverlay extends StatelessWidget {
  const _MfaOverlay({
    required this.controller,
    required this.checking,
    required this.verifying,
    required this.errorMessage,
    required this.onVerify,
  });

  final TextEditingController controller;
  final bool checking;
  final bool verifying;
  final String? errorMessage;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.94),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF202748), Color(0xFF0000CD)],
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Confirme que e voce',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o codigo do seu app autenticador para continuar.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      enabled: !checking && !verifying,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        errorText: errorMessage,
                      ),
                      onSubmitted: (_) => onVerify(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: checking || verifying ? null : onVerify,
                      icon: verifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_outlined),
                      label: Text(checking ? 'Verificando...' : 'Continuar'),
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
}
