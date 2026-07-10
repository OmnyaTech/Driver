// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'turnstile_html.dart';

Widget buildTurnstilePlatformView({
  required String siteKey,
  required bool visible,
  required void Function(String type, Map<String, dynamic> payload) onEvent,
}) {
  return _TurnstileWebView(
    siteKey: siteKey,
    visible: visible,
    onEvent: onEvent,
  );
}

class _TurnstileWebView extends StatefulWidget {
  const _TurnstileWebView({
    required this.siteKey,
    required this.visible,
    required this.onEvent,
  });

  final String siteKey;
  final bool visible;
  final void Function(String type, Map<String, dynamic> payload) onEvent;

  @override
  State<_TurnstileWebView> createState() => _TurnstileWebViewState();
}

class _TurnstileWebViewState extends State<_TurnstileWebView> {
  late final String _viewType;
  StreamSubscription<html.MessageEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _viewType =
        'omnyadriver-turnstile-${widget.visible ? 'visible' : 'hidden'}-${DateTime.now().microsecondsSinceEpoch}';
    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = widget.visible ? '120px' : '1px'
      ..style.opacity = widget.visible ? '1' : '0.01'
      ..srcdoc = buildTurnstileHtml(
        siteKey: widget.siteKey,
        visible: widget.visible,
      );

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => iframe);

    _subscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! String || !data.contains('omnyadriver-turnstile')) {
        return;
      }

      final raw = jsonDecode(data) as Map<String, dynamic>;
      widget.onEvent(raw['type'].toString(), Map<String, dynamic>.from(raw));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.visible ? 120 : 1,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
