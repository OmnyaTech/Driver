import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_version_gate_result.dart';
import '../../services/app_version_gate_service.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  final _service = AppVersionGateService();
  late Future<AppVersionGateResult> _future;
  bool _continuedWithOldVersion = false;

  @override
  void initState() {
    super.initState();
    _future = _service.check();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersionGateResult>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data!;
        if (result.canContinue) {
          if (result.updateAvailable && !_continuedWithOldVersion) {
            return _SoftVersionScreen(
              result: result,
              onContinue: () => setState(() => _continuedWithOldVersion = true),
              onRetry: () => setState(() => _future = _service.check()),
            );
          }
          return widget.child;
        }

        return _BlockedVersionScreen(
          result: result,
          onRetry: () => setState(() => _future = _service.check()),
        );
      },
    );
  }
}

class _SoftVersionScreen extends StatelessWidget {
  const _SoftVersionScreen({
    required this.result,
    required this.onContinue,
    required this.onRetry,
  });

  final AppVersionGateResult result;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = result.daysRemaining.clamp(0, 99);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020409), Color(0xFF111827), Color(0xFF0000CD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.new_releases_outlined, size: 42),
                      const SizedBox(height: 18),
                      Text(
                        'Tem uma atualizacao pronta',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Atualize quando puder para receber melhorias, seguranca e correcoes. Voce ainda pode usar o app por $days dias.',
                      ),
                      const SizedBox(height: 18),
                      Text('Versao instalada: ${result.installedVersion}'),
                      Text('Versao disponivel: ${result.latestVersion}'),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: result.updateUrl == null
                            ? null
                            : () => launchUrl(
                                Uri.parse(result.updateUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Atualizar agora'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: onContinue,
                        child: const Text('Continuar por enquanto'),
                      ),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Ja atualizei, verificar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedVersionScreen extends StatelessWidget {
  const _BlockedVersionScreen({required this.result, required this.onRetry});

  final AppVersionGateResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020409), Color(0xFF101522), Color(0xFF0000CD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.system_update_alt, size: 42),
                      const SizedBox(height: 18),
                      Text(
                        'Atualize para continuar',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sua versao ficou antiga e precisa ser atualizada para manter o app seguro e funcionando bem.',
                      ),
                      const SizedBox(height: 18),
                      Text('Versao instalada: ${result.installedVersion}'),
                      Text('Versao disponivel: ${result.latestVersion}'),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: result.updateUrl == null
                            ? null
                            : () => launchUrl(
                                Uri.parse(result.updateUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Atualizar aplicativo'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Ja atualizei, tentar de novo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
