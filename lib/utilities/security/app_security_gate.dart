import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _pausedAt;
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
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now().toUtc();
      _timer?.cancel();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final profile = context.read<AppSession>().profile;
      if (profile?.reauthOnResume == true && _pausedExceededLimit(profile)) {
        if (profile?.biometricLockEnabled == true) {
          setState(() {
            _locked = true;
            _lastMfaCheckUserId = null;
          });
        } else {
          unawaited(context.read<AppSession>().signOut());
        }
      }
      _pausedAt = null;
      _schedule(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppSession>().profile;
    _schedule(profile);
    _checkMfaRequirement(profile);

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
        final factors = await _mfaService.listVerifiedTotpFactors();
        if (factors.isEmpty) {
          await _mfaService.setTotpMfaEnabled(false);
          if (!mounted) return;
          await context.read<AppSession>().refreshProfile();
          if (!mounted) return;
          setState(() {
            _mfaRequired = false;
            _mfaErrorMessage = null;
            _mfaCodeController.clear();
          });
          return;
        }
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
    if (profile == null) return;

    final minutes = profile.inactivityLockMinutes.clamp(1, 240);
    _timer = Timer(Duration(minutes: minutes), () {
      if (!mounted) return;
      if (profile.biometricLockEnabled) {
        setState(() => _locked = true);
        return;
      }
      unawaited(context.read<AppSession>().signOut());
    });
  }

  bool _pausedExceededLimit(AppProfile? profile) {
    final pausedAt = _pausedAt;
    if (profile == null || pausedAt == null) return false;
    final minutes = profile.inactivityLockMinutes.clamp(1, 240);
    return DateTime.now().toUtc().difference(pausedAt) >=
        Duration(minutes: minutes);
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

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = data?.text?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return;
    controller.text = digits.length > 6 ? digits.substring(0, 6) : digits;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.94),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final currentCode = value.text;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 104,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  Icons.phone_iphone_rounded,
                                  color: theme.colorScheme.onSurface,
                                  size: 46,
                                ),
                              ),
                              Positioned(
                                top: -22,
                                right: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCE6FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    '...',
                                    style: TextStyle(
                                      color: Color(0xFF0B1020),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Verifique sua identidade',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Digite o codigo de 6 digitos do seu app autenticador.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                6,
                                (index) => _MfaCodeBox(
                                  value: index < currentCode.length
                                      ? currentCode[index]
                                      : '',
                                  active:
                                      index == currentCode.length &&
                                      currentCode.length < 6,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: 0.01,
                              child: SizedBox(
                                width: 320,
                                height: 56,
                                child: TextField(
                                  autofocus: true,
                                  controller: controller,
                                  enabled: !checking && !verifying,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  cursorColor: Colors.transparent,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => onVerify(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: checking || verifying
                                ? null
                                : _pasteCode,
                            icon: const Icon(Icons.content_paste, size: 16),
                            label: const Text('Colar'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: checking || verifying ? null : onVerify,
                          child: verifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(checking ? 'Verificando...' : 'Continuar'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MfaCodeBox extends StatelessWidget {
  const _MfaCodeBox({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 42,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary.withValues(alpha: 0.16)
            : theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? theme.colorScheme.primary : theme.dividerColor,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Text(
        value,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
