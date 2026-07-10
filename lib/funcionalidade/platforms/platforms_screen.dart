import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_platform.dart';
import '../../services/plan_access_service.dart';
import '../../services/platform_service.dart';
import '../../utilities/state/app_session.dart';

class PlatformsScreen extends StatefulWidget {
  const PlatformsScreen({super.key});

  @override
  State<PlatformsScreen> createState() => _PlatformsScreenState();
}

class _PlatformsScreenState extends State<PlatformsScreen> {
  final PlatformService _platformService = PlatformService();
  final PlanAccessService _planAccessService = const PlanAccessService();
  bool _loading = true;
  List<AppPlatform> _platforms = const [];

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    setState(() => _loading = true);
    final platforms = await _platformService.listPlatforms();
    if (!mounted) return;
    setState(() {
      _platforms = platforms;
      _loading = false;
    });
  }

  Future<void> _openCreateDialog() async {
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activePlatforms = _platforms.where((item) => item.active).length;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultiplePlatforms(profile.planType)
        : false;

    if (activePlatforms >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O plano free permite apenas uma plataforma ativa. Presente, premium ou developer liberam multiplas fontes.',
          ),
        ),
      );
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _PlatformFormDialog(
        onSubmit:
            ({
              required name,
              required type,
              required averageIncome,
              required averageDeliveries,
            }) async {
              await _platformService.createPlatform(
                name: name,
                type: type,
                averageIncome: averageIncome,
                averageDeliveries: averageDeliveries,
              );
            },
      ),
    );

    if (created == true) {
      await _loadPlatforms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final activePlatforms = _platforms.where((item) => item.active).length;
    final canUseMultiple = session.profile == null
        ? false
        : _planAccessService.canUseMultiplePlatforms(
            session.profile!.planType,
          );

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPlatforms,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plataformas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!canUseMultiple && activePlatforms >= 1)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Plano free: somente uma plataforma ativa por conta. Assinatura, presente ou papel developer liberam multiplas plataformas.',
                  ),
                ),
              ),
            if (_platforms.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma plataforma cadastrada ainda. Adicione ifood, 99, restaurantes e outras fontes de corrida.',
                  ),
                ),
              ),
            ..._platforms.map(
              (platform) => Card(
                child: ListTile(
                  title: Text(platform.name),
                  subtitle: Text(
                    [
                      platform.type,
                      if (platform.averageIncome != null)
                        'R\$ ${platform.averageIncome!.toStringAsFixed(2)}',
                      if (platform.averageDeliveries != null)
                        '${platform.averageDeliveries} entregas',
                      platform.active ? 'Ativa' : 'Arquivada',
                    ].join(' • '),
                  ),
                  trailing: platform.active
                      ? IconButton(
                          onPressed: () async {
                            await _platformService.archivePlatform(platform.id);
                            await _loadPlatforms();
                          },
                          icon: const Icon(Icons.archive_outlined),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformFormDialog extends StatefulWidget {
  const _PlatformFormDialog({required this.onSubmit});

  final Future<void> Function({
    required String name,
    required String type,
    required String averageIncome,
    required String averageDeliveries,
  })
  onSubmit;

  @override
  State<_PlatformFormDialog> createState() => _PlatformFormDialogState();
}

class _PlatformFormDialogState extends State<_PlatformFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _deliveriesController = TextEditingController();
  String _type = 'platform';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _deliveriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova plataforma'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: _required,
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: 'platform',
                    child: Text('Plataforma'),
                  ),
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text('Restaurante'),
                  ),
                  DropdownMenuItem(value: 'market', child: Text('Mercado')),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? 'platform'),
              ),
              TextFormField(
                controller: _incomeController,
                decoration: const InputDecoration(
                  labelText: 'Media diaria de ganhos',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextFormField(
                controller: _deliveriesController,
                decoration: const InputDecoration(
                  labelText: 'Media diaria de entregas',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  setState(() => _saving = true);
                  await widget.onSubmit(
                    name: _nameController.text,
                    type: _type,
                    averageIncome: _incomeController.text,
                    averageDeliveries: _deliveriesController.text,
                  );
                  if (!mounted) return;
                  navigator.pop(true);
                },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
  }
}
