import 'package:local_auth/local_auth.dart';

class BiometricLockService {
  BiometricLockService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<bool> canUseDeviceLock() async {
    try {
      final supported = await _authentication.isDeviceSupported();
      final biometrics = await _authentication.canCheckBiometrics;
      return supported || biometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlock() async {
    try {
      return _authentication.authenticate(
        localizedReason: 'Confirme que e voce para voltar ao Driver.',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
