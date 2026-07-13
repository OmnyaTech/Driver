import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class MfaEnrollmentDraft {
  const MfaEnrollmentDraft({
    required this.factorId,
    required this.secret,
    required this.uri,
    required this.qrCode,
  });

  final String factorId;
  final String secret;
  final String uri;
  final String qrCode;
}

class MfaService {
  const MfaService({AuthService authService = const AuthService()})
    : _authService = authService;

  final AuthService _authService;

  Future<List<Factor>> listTotpFactors() async {
    final response = await _authService.requireClient().auth.mfa.listFactors();
    return response.totp;
  }

  Future<MfaEnrollmentDraft> startTotpEnrollment() async {
    final response = await _authService.requireClient().auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'Omnya Driver',
      friendlyName: 'Omnya Driver',
    );
    final totp = response.totp;
    if (totp == null) {
      throw StateError('Nao foi possivel gerar a chave do autenticador.');
    }

    return MfaEnrollmentDraft(
      factorId: response.id,
      secret: totp.secret,
      uri: totp.uri,
      qrCode: totp.qrCode,
    );
  }

  Future<void> verifyTotpEnrollment({
    required String factorId,
    required String code,
  }) async {
    final challenge = await _authService.requireClient().auth.mfa.challenge(
      factorId: factorId,
    );
    await _authService.requireClient().auth.mfa.verify(
      factorId: factorId,
      challengeId: challenge.id,
      code: code.trim(),
    );
  }

  Future<void> disableTotp(String factorId) async {
    await _authService.requireClient().auth.mfa.unenroll(factorId);
  }
}
