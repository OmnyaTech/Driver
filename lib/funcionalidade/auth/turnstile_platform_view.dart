import 'package:flutter/widgets.dart';

import 'turnstile_platform_view_stub.dart'
    if (dart.library.html) 'turnstile_platform_view_web.dart'
    if (dart.library.io) 'turnstile_platform_view_io.dart'
    as impl;

Widget buildTurnstilePlatformView({
  required String siteKey,
  required bool visible,
  required void Function(String type, Map<String, dynamic> payload) onEvent,
}) {
  return impl.buildTurnstilePlatformView(
    siteKey: siteKey,
    visible: visible,
    onEvent: onEvent,
  );
}
