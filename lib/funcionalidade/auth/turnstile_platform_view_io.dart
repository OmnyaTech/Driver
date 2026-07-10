import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'turnstile_html.dart';

Widget buildTurnstilePlatformView({
  required String siteKey,
  required bool visible,
  required void Function(String type, Map<String, dynamic> payload) onEvent,
}) {
  return _TurnstileIoView(siteKey: siteKey, visible: visible, onEvent: onEvent);
}

class _TurnstileIoView extends StatefulWidget {
  const _TurnstileIoView({
    required this.siteKey,
    required this.visible,
    required this.onEvent,
  });

  final String siteKey;
  final bool visible;
  final void Function(String type, Map<String, dynamic> payload) onEvent;

  @override
  State<_TurnstileIoView> createState() => _TurnstileIoViewState();
}

class _TurnstileIoViewState extends State<_TurnstileIoView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TurnstileBridge',
        onMessageReceived: (message) {
          final raw = jsonDecode(message.message) as Map<String, dynamic>;
          widget.onEvent(
            raw['type'].toString(),
            Map<String, dynamic>.from(raw),
          );
        },
      )
      ..loadHtmlString(
        buildTurnstileHtml(siteKey: widget.siteKey, visible: widget.visible),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.visible ? double.infinity : 1,
      height: widget.visible ? 120 : 1,
      child: WebViewWidget(controller: _controller),
    );
  }
}
