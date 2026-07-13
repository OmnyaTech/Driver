import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_platform.dart';
import '../../services/plan_access_service.dart';
import '../../services/platform_logo_service.dart';
import '../../services/platform_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/state/app_session.dart';
import '../../utilities/ui/omnya_shell.dart';
import '../../utilities/ui/screen_action_controller.dart';

class PlatformsScreen extends StatefulWidget {
  const PlatformsScreen({
    super.key,
    this.showCreateButton = true,
    this.actionController,
    this.embedded = false,
  });

  final bool showCreateButton;
  final ScreenActionController? actionController;
  final bool embedded;

  @override
  State<PlatformsScreen> createState() => _PlatformsScreenState();
}

class _PlatformsScreenState extends State<PlatformsScreen> {
  final PlatformService _platformService = PlatformService();
  final PlatformLogoService _platformLogoService = PlatformLogoService();
  final PlanAccessService _planAccessService = const PlanAccessService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<AppPlatform> _platforms = const [];
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    widget.actionController?.bindCreate(_openCreateDialog);
    _searchController.addListener(_handleFilterChange);
    _loadPlatforms();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleFilterChange)
      ..dispose();
    widget.actionController?.clear();
    super.dispose();
  }

  void _handleFilterChange() {
    if (mounted) {
      setState(() {});
    }
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
    await _openPlatformDialog();
  }

  Future<void> _openEditDialog(AppPlatform platform) async {
    await _openPlatformDialog(initialPlatform: platform);
  }

  Future<void> _openPlatformDialog({AppPlatform? initialPlatform}) async {
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activePlatforms = _platforms.where((item) => item.active).length;
    final editingActivePlatform = initialPlatform?.active == true ? 1 : 0;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultiplePlatforms(profile.planType)
        : false;

    if (initialPlatform == null && activePlatforms >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O plano free permite apenas uma plataforma ativa. Presente, premium ou developer liberam multiplas fontes.',
          ),
        ),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PlatformFormDialog(
        initialPlatform: initialPlatform,
        canEditActiveState:
            canUseMultiple || activePlatforms <= editingActivePlatform,
        onSubmit:
            ({
              required name,
              required type,
              required averageIncome,
              required averageDeliveries,
              required active,
            }) async {
              if (active && !canUseMultiple) {
                final wouldHaveActive =
                    _platforms.where((item) => item.active).length -
                    editingActivePlatform +
                    1;
                if (wouldHaveActive > 1) {
                  throw StateError(
                    'O plano atual permite apenas uma plataforma ativa.',
                  );
                }
              }

              if (initialPlatform == null) {
                await _platformService.createPlatform(
                  name: name,
                  type: type,
                  averageIncome: averageIncome,
                  averageDeliveries: averageDeliveries,
                );
                return;
              }

              await _platformService.updatePlatform(
                id: initialPlatform.id,
                name: name,
                type: type,
                averageIncome: averageIncome,
                averageDeliveries: averageDeliveries,
                active: active,
              );
            },
      ),
    );

    if (saved == true) {
      await _loadPlatforms();
    }
  }

  Future<void> _archivePlatform(AppPlatform platform) async {
    await _platformService.archivePlatform(platform.id);
    await _loadPlatforms();
  }

  Future<void> _updatePlatformLogo(AppPlatform platform) async {
    setState(() => _uploadingLogo = true);
    try {
      final logoUrl = await _platformLogoService.pickAndUploadLogo(
        platformId: platform.id,
      );
      if (logoUrl == null) return;
      await _platformService.updatePlatformLogo(
        id: platform.id,
        logoUrl: logoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo atualizada com sucesso.')),
      );
      await _loadPlatforms();
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _removePlatformLogo(AppPlatform platform) async {
    setState(() => _uploadingLogo = true);
    try {
      await _platformLogoService.removeLogo(platformId: platform.id);
      await _platformService.updatePlatformLogo(id: platform.id, logoUrl: null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo removida com sucesso.')),
      );
      await _loadPlatforms();
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _deletePlatform(AppPlatform platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir plataforma'),
        content: Text(
          'Deseja excluir "${platform.name}"? Vinculos de jornadas com essa plataforma serao removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _platformService.deletePlatform(platform.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plataforma removida com sucesso.')),
    );
    await _loadPlatforms();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final activePlatforms = _platforms.where((item) => item.active).length;
    final canUseMultiple = session.profile == null
        ? false
        : _planAccessService.canUseMultiplePlatforms(session.profile!.planType);

    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return loading;
      }
      return const OmnyaSubPageScaffold(title: 'Plataformas', body: loading);
    }

    final content = RefreshIndicator(
      onRefresh: _loadPlatforms,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plataformas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.showCreateButton)
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (!canUseMultiple && activePlatforms >= 1)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Plano free: somente uma plataforma ativa por conta. Assinatura, presente ou papel developer liberam multiplas plataformas.',
                ),
              ),
            ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar plataforma, tipo ou status',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_uploadingLogo)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
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
          if (_platforms.isNotEmpty && _filteredPlatforms.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhuma plataforma encontrada na busca atual.'),
              ),
            ),
          ..._filteredPlatforms.map(
            (platform) => Card(
              child: ListTile(
                leading: _PlatformLogo(platform: platform),
                title: Text(platform.name),
                subtitle: Text(
                  [
                    platform.type,
                    if (platform.averageIncome != null)
                      AppFormat.of(context).currency(platform.averageIncome!),
                    if (platform.averageDeliveries != null)
                      '${platform.averageDeliveries} entregas',
                    platform.active ? 'Ativa' : 'Arquivada',
                  ].join(' • '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _openEditDialog(platform);
                      return;
                    }
                    if (value == 'logo') {
                      await _updatePlatformLogo(platform);
                      return;
                    }
                    if (value == 'remove_logo') {
                      await _removePlatformLogo(platform);
                      return;
                    }
                    if (value == 'archive') {
                      await _archivePlatform(platform);
                      return;
                    }
                    if (value == 'delete') {
                      await _deletePlatform(platform);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'logo',
                      child: Text('Alterar logo'),
                    ),
                    if ((platform.logoUrl ?? '').trim().isNotEmpty)
                      const PopupMenuItem(
                        value: 'remove_logo',
                        child: Text('Remover logo'),
                      ),
                    if (platform.active)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Arquivar'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return OmnyaSubPageScaffold(
      title: 'Plataformas',
      heroTagPrefix: 'platforms',
      floatingActions: [
        OmnyaFabAction(
          label: 'Nova plataforma',
          icon: Icons.add,
          onTap: _openCreateDialog,
        ),
      ],
      body: content,
    );
  }

  List<AppPlatform> get _filteredPlatforms {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _platforms;
    return _platforms.where((platform) {
      final haystack = [
        platform.name,
        platform.type,
        platform.active ? 'ativa' : 'arquivada',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _PlatformLogo extends StatelessWidget {
  const _PlatformLogo({required this.platform});

  final AppPlatform platform;

  @override
  Widget build(BuildContext context) {
    final logoUrl = platform.logoUrl?.trim();
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0000CD).withValues(alpha: 0.12),
      ),
      child: const Icon(Icons.storefront_outlined, color: Color(0xFF0000CD)),
    );

    if (logoUrl == null || logoUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        logoUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _PlatformFormDialog extends StatefulWidget {
  const _PlatformFormDialog({
    this.initialPlatform,
    required this.canEditActiveState,
    required this.onSubmit,
  });

  final AppPlatform? initialPlatform;
  final bool canEditActiveState;
  final Future<void> Function({
    required String name,
    required String type,
    required String averageIncome,
    required String averageDeliveries,
    required bool active,
  })
  onSubmit;

  @override
  State<_PlatformFormDialog> createState() => _PlatformFormDialogState();
}

class _PlatformFormDialogState extends State<_PlatformFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _incomeController;
  late final TextEditingController _deliveriesController;
  late String _type;
  late bool _active;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initialPlatform = widget.initialPlatform;
    _nameController = TextEditingController(text: initialPlatform?.name ?? '');
    _incomeController = TextEditingController(
      text: initialPlatform?.averageIncome?.toStringAsFixed(2) ?? '',
    );
    _deliveriesController = TextEditingController(
      text: initialPlatform?.averageDeliveries?.toString() ?? '',
    );
    _type = initialPlatform?.type ?? 'platform';
    _active = initialPlatform?.active ?? true;
  }

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
      title: Text(
        widget.initialPlatform == null
            ? 'Nova plataforma'
            : 'Editar plataforma',
      ),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Plataforma ativa'),
                subtitle: Text(
                  widget.canEditActiveState
                      ? 'Quando desligada, a plataforma fica arquivada.'
                      : 'O plano atual nao permite ativar mais plataformas.',
                ),
                value: _active,
                onChanged: (_saving || (!widget.canEditActiveState && !_active))
                    ? null
                    : (value) => setState(() => _active = value),
              ),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
                  setState(() {
                    _saving = true;
                    _submitError = null;
                  });
                  try {
                    await widget.onSubmit(
                      name: _nameController.text,
                      type: _type,
                      averageIncome: _incomeController.text,
                      averageDeliveries: _deliveriesController.text,
                      active: _active,
                    );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (error) {
                    if (!mounted) return;
                    setState(() => _submitError = error.toString());
                  } finally {
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  }
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
