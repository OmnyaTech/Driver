import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/data_privacy_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _service = DataPrivacyService();
  final _reasonController = TextEditingController();
  bool _exporting = false;
  bool _requestingDeletion = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Seguranca e dados')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF101522), Color(0xFF0000CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_moon_outlined,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                const SizedBox(height: 14),
                Text(
                  'Seus dados continuam com voce',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aqui voce consegue copiar um backup da sua rotina e pedir encerramento da conta quando precisar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Levar meus dados', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Geramos um arquivo em texto com jornadas, despesas, abastecimentos, metas e configuracoes da conta.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _copyExport,
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.copy_all_outlined),
                    label: Text(_exporting ? 'Preparando...' : 'Copiar backup'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Encerrar conta', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Para evitar perda sem querer, o app registra um pedido. A equipe confere assinaturas, pagamentos e dados antes de apagar tudo.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Quer contar o motivo? Opcional',
                      hintText: 'Ex: parei de entregar por enquanto',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _requestingDeletion
                        ? null
                        : _confirmDeletionRequest,
                    icon: _requestingDeletion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      _requestingDeletion
                          ? 'Enviando pedido...'
                          : 'Pedir encerramento',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyExport() async {
    setState(() => _exporting = true);
    try {
      final exportJson = await _service.buildExportJson();
      await Clipboard.setData(ClipboardData(text: exportJson));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup copiado para a area de transferencia.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para gerar o backup: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeletionRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pedir encerramento?'),
          content: const Text(
            'Isso nao apaga sua conta na hora. Vamos registrar seu pedido para a equipe cuidar com seguranca.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Agora nao'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar pedido'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _requestingDeletion = true);
    try {
      await _service.requestAccountDeletion(reason: _reasonController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido registrado. Vamos acompanhar por aqui.'),
        ),
      );
      _reasonController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao deu para registrar o pedido: $error')),
      );
    } finally {
      if (mounted) setState(() => _requestingDeletion = false);
    }
  }
}
