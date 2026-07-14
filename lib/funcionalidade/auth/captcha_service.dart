import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/turnstile_flow.dart';
import 'turnstile_platform_view.dart';

class CaptchaService {
  const CaptchaService();

  Future<String?> obtainToken(
    BuildContext context, {
    required String siteKey,
    required TurnstileFlow flow,
  }) async {
    final visible = kIsWeb;
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CaptchaDialog(siteKey: siteKey, visible: visible, flow: flow);
      },
    );

    return result;
  }
}

class _CaptchaDialog extends StatefulWidget {
  const _CaptchaDialog({
    required this.siteKey,
    required this.visible,
    required this.flow,
  });

  final String siteKey;
  final bool visible;
  final TurnstileFlow flow;

  @override
  State<_CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<_CaptchaDialog> {
  String _status = 'Validando a seguranca do app. Aguarde alguns instantes.';
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() {
        _status = 'A verificacao demorou mais que o esperado. Tente novamente.';
      });
      Navigator.of(context).pop(null);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.visible ? 'Verificacao de seguranca' : 'Validando seguranca',
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            if (!widget.visible)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              ),
            buildTurnstilePlatformView(
              siteKey: widget.siteKey,
              visible: widget.visible,
              onEvent: (type, payload) {
                if (!mounted) return;

                switch (type) {
                  case 'success':
                    Navigator.of(context).pop(payload['token']?.toString());
                    return;
                  case 'error':
                    setState(() {
                      _status =
                          'Nao foi possivel validar a seguranca do app. Tente novamente.';
                    });
                    return;
                  case 'expired':
                    setState(() {
                      _status =
                          'A verificacao expirou. Tente novamente para continuar.';
                    });
                    return;
                  case 'rendered':
                    setState(() {
                      _status = widget.visible
                          ? 'Confirme a verificacao de seguranca para continuar.'
                          : 'Validando a seguranca do app. Aguarde alguns instantes.';
                    });
                    return;
                  case 'executed':
                    setState(() {
                      _status = 'Fazendo uma checagem rapida de seguranca.';
                    });
                    return;
                  default:
                    return;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.visible)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
      ],
    );
  }
}
