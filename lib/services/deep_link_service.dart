import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'referral_service.dart';

class DeepLinkService {
  DeepLinkService({ReferralService? referralService, AppLinks? appLinks})
    : _referralService = referralService ?? ReferralService(),
      _appLinks = appLinks ?? AppLinks();

  final ReferralService _referralService;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> start({Future<void> Function()? onReferralCaptured}) async {
    if (kIsWeb) return;

    await _captureInitialLink(onReferralCaptured);
    _subscription ??= _appLinks.uriLinkStream.listen(
      (uri) async {
        final captured = await _referralService.captureReferralFromUri(uri);
        if (captured && onReferralCaptured != null) {
          await onReferralCaptured();
        }
      },
      onError: (_) {
        // Deep links should never block the app if the platform resolver fails.
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _captureInitialLink(
    Future<void> Function()? onReferralCaptured,
  ) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return;
      final captured = await _referralService.captureReferralFromUri(uri);
      if (captured && onReferralCaptured != null) {
        await onReferralCaptured();
      }
    } catch (_) {
      // The web flow still captures Uri.base; native deep links are best effort.
    }
  }
}
