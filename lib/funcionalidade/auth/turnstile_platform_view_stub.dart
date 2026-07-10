import 'package:flutter/material.dart';

Widget buildTurnstilePlatformView({
  required String siteKey,
  required bool visible,
  required void Function(String type, Map<String, dynamic> payload) onEvent,
}) {
  return const SizedBox.shrink();
}
