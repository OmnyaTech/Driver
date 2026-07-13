import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_profile.dart';
import '../../services/biometric_lock_service.dart';
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
  Timer? _timer;
  bool _locked = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final profile = context.read<AppSession>().profile;
      if (profile?.biometricLockEnabled == true &&
          profile?.reauthOnResume == true) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppSession>().profile;
    _schedule(profile);

    if (profile?.biometricLockEnabled != true) {
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
        ],
      ),
    );
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
    });
    _schedule(context.read<AppSession>().profile);
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
