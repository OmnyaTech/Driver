import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_platform.dart';
import '../../services/plan_access_service.dart';
import '../../services/platform_logo_service.dart';
import '../../services/platform_service.dart';
import '../../utilities/localization/app_format.dart';
import '../../utilities/localization/app_strings.dart';
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
    final strings = AppStrings.of(context);
    final session = context.read<AppSession>();
    final profile = session.profile;
    final activePlatforms = _platforms.where((item) => item.active).length;
    final editingActivePlatform = initialPlatform?.active == true ? 1 : 0;
    final canUseMultiple = profile != null
        ? _planAccessService.canUseMultiplePlatforms(profile.planType)
        : false;

    if (initialPlatform == null && activePlatforms >= 1 && !canUseMultiple) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'No plano free, voce usa uma plataforma ativa por vez. Premium libera mais fontes.',
              en: 'On the free plan, you can use one active platform at a time. Premium unlocks more sources.',
              es: 'En el plan gratis, usas una plataforma activa por vez. Premium libera mas fuentes.',
            ),
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
                    strings.pick(
                      pt: 'Seu plano atual permite apenas uma plataforma ativa.',
                      en: 'Your current plan allows only one active platform.',
                      es: 'Tu plan actual permite solo una plataforma activa.',
                    ),
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
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'Logo atualizada.',
              en: 'Logo updated.',
              es: 'Logo actualizada.',
            ),
          ),
        ),
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
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.pick(
              pt: 'Logo removida.',
              en: 'Logo removed.',
              es: 'Logo eliminada.',
            ),
          ),
        ),
      );
      await _loadPlatforms();
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _deletePlatform(AppPlatform platform) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          strings.pick(
            pt: 'Excluir plataforma',
            en: 'Delete platform',
            es: 'Eliminar plataforma',
          ),
        ),
        content: Text(
          strings.pick(
            pt: 'Quer excluir "${platform.name}"? Jornadas ligadas a ela tambem saem.',
            en: 'Delete "${platform.name}"? Linked shifts will also be removed.',
            es: 'Quieres eliminar "${platform.name}"? Tambien se quitaran turnos vinculados.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.pick(pt: 'Excluir', en: 'Delete', es: 'Eliminar'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _platformService.deletePlatform(platform.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.pick(
            pt: 'Plataforma removida.',
            en: 'Platform removed.',
            es: 'Plataforma eliminada.',
          ),
        ),
      ),
    );
    await _loadPlatforms();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final format = AppFormat.of(context);
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
      return OmnyaSubPageScaffold(title: strings.platforms, body: loading);
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
                    strings.platforms,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.showCreateButton)
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: Text(strings.newItem),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (!canUseMultiple && activePlatforms >= 1)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.pick(
                    pt: 'Plano free: uma plataforma ativa por vez. Premium, presente ou developer liberam mais fontes.',
                    en: 'Free plan: one active platform at a time. Premium, gift or developer access unlocks more sources.',
                    es: 'Plan gratis: una plataforma activa por vez. Premium, regalo o developer liberan mas fuentes.',
                  ),
                ),
              ),
            ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: strings.pick(
                pt: 'Buscar plataforma, tipo ou status',
                en: 'Search platform, type or status',
                es: 'Buscar plataforma, tipo o estado',
              ),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhuma plataforma cadastrada ainda. Adicione apps, restaurantes e outras fontes de corrida.',
                    en: 'No platforms yet. Add apps, restaurants and other income sources.',
                    es: 'Aun no hay plataformas. Agrega apps, restaurantes y otras fuentes.',
                  ),
                ),
              ),
            ),
          if (_platforms.isNotEmpty && _filteredPlatforms.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.pick(
                    pt: 'Nenhuma plataforma encontrada nessa busca.',
                    en: 'No platforms found for this search.',
                    es: 'No se encontraron plataformas en esta busqueda.',
                  ),
                ),
              ),
            ),
          ..._filteredPlatforms.map(
            (platform) => Card(
              child: ListTile(
                leading: _PlatformLogo(platform: platform),
                title: Text(
                  '${_platformTypeLabel(platform.type, strings)} - ${platform.name}',
                ),
                subtitle: Text(
                  [
                    if (platform.averageIncome != null)
                      '${strings.pick(pt: 'Media', en: 'Average', es: 'Promedio')} ${format.currency(platform.averageIncome!)}',
                    if (platform.averageDeliveries != null)
                      strings.deliveriesCount(platform.averageDeliveries!),
                    platform.active
                        ? strings.pick(pt: 'Ativa', en: 'Active', es: 'Activa')
                        : strings.pick(
                            pt: 'Arquivada',
                            en: 'Archived',
                            es: 'Archivada',
                          ),
                  ].join(' / '),
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
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        strings.pick(pt: 'Editar', en: 'Edit', es: 'Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logo',
                      child: Text(
                        strings.pick(
                          pt: 'Alterar logo',
                          en: 'Change logo',
                          es: 'Cambiar logo',
                        ),
                      ),
                    ),
                    if ((platform.logoUrl ?? '').trim().isNotEmpty)
                      PopupMenuItem(
                        value: 'remove_logo',
                        child: Text(
                          strings.pick(
                            pt: 'Remover logo',
                            en: 'Remove logo',
                            es: 'Quitar logo',
                          ),
                        ),
                      ),
                    if (platform.active)
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(
                          strings.pick(
                            pt: 'Arquivar',
                            en: 'Archive',
                            es: 'Archivar',
                          ),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        strings.pick(
                          pt: 'Excluir',
                          en: 'Delete',
                          es: 'Eliminar',
                        ),
                      ),
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
      title: strings.platforms,
      heroTagPrefix: 'platforms',
      floatingActions: [
        OmnyaFabAction(
          label: strings.newPlatform,
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

  String _platformTypeLabel(String value, AppStrings strings) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('restaurant') ||
        normalized.contains('restaurante')) {
      return strings.pick(
        pt: 'Restaurante',
        en: 'Restaurant',
        es: 'Restaurante',
      );
    }
    if (normalized.contains('market') || normalized.contains('mercado')) {
      return strings.pick(pt: 'Mercado', en: 'Market', es: 'Mercado');
    }
    return strings.pick(pt: 'Plataforma', en: 'Platform', es: 'Plataforma');
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
  final PlatformService _platformService = PlatformService();
  late final TextEditingController _nameController;
  late final TextEditingController _incomeController;
  late final TextEditingController _deliveriesController;
  late String _type;
  late bool _active;
  bool _saving = false;
  bool _loadingSuggestions = false;
  Timer? _suggestionDebounce;
  List<PlatformCatalogSuggestion> _suggestions = const [];
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
    _nameController.addListener(_scheduleSuggestionRefresh);
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _nameController.removeListener(_scheduleSuggestionRefresh);
    _nameController.dispose();
    _incomeController.dispose();
    _deliveriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(
        widget.initialPlatform == null
            ? strings.pick(
                pt: 'Nova plataforma',
                en: 'New platform',
                es: 'Nueva plataforma',
              )
            : strings.pick(
                pt: 'Editar plataforma',
                en: 'Edit platform',
                es: 'Editar plataforma',
              ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: strings.pick(pt: 'Nome', en: 'Name', es: 'Nombre'),
                ),
                validator: _required,
              ),
              if (_loadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                )
              else if (_suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.pick(
                            pt: 'Encontramos parecidos na sua regiao',
                            en: 'Similar places found near you',
                            es: 'Encontramos parecidos en tu region',
                          ),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.pick(
                            pt: 'Toque para reaproveitar nome, tipo e logo/foto ja cadastrados perto de voce.',
                            en: 'Tap to reuse name, type and logo/photo already saved near you.',
                            es: 'Toca para reutilizar nombre, tipo y logo/foto ya guardados cerca de ti.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._suggestions.map(
                        (suggestion) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: _SuggestionLogo(url: suggestion.logoUrl),
                          title: Text(suggestion.name),
                          subtitle: Text(suggestion.locationLabel),
                          trailing: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _nameController.text = suggestion.name;
                                _type = suggestion.type;
                                _suggestions = const [];
                              });
                            },
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: Text(
                              strings.pick(pt: 'Usar', en: 'Use', es: 'Usar'),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _nameController.text = suggestion.name;
                              _type = suggestion.type;
                              _suggestions = const [];
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: strings.pick(pt: 'Tipo', en: 'Type', es: 'Tipo'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'platform',
                    child: Text(
                      strings.pick(
                        pt: 'Plataforma',
                        en: 'Platform',
                        es: 'Plataforma',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text(
                      strings.pick(
                        pt: 'Restaurante',
                        en: 'Restaurant',
                        es: 'Restaurante',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'market',
                    child: Text(
                      strings.pick(pt: 'Mercado', en: 'Market', es: 'Mercado'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(
                      strings.pick(pt: 'Outro', en: 'Other', es: 'Otro'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _type = value ?? 'platform');
                  _scheduleSuggestionRefresh();
                },
              ),
              TextFormField(
                controller: _incomeController,
                decoration: InputDecoration(
                  labelText: strings.pick(
                    pt: 'Media diaria de ganhos',
                    en: 'Average daily income',
                    es: 'Promedio diario de ingresos',
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextFormField(
                controller: _deliveriesController,
                decoration: InputDecoration(
                  labelText: strings.pick(
                    pt: 'Media diaria de entregas',
                    en: 'Average daily deliveries',
                    es: 'Promedio diario de entregas',
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.pick(
                    pt: 'Plataforma ativa',
                    en: 'Active platform',
                    es: 'Plataforma activa',
                  ),
                ),
                subtitle: Text(
                  widget.canEditActiveState
                      ? strings.pick(
                          pt: 'Quando desligada, ela fica arquivada.',
                          en: 'When turned off, it stays archived.',
                          es: 'Cuando se apaga, queda archivada.',
                        )
                      : strings.pick(
                          pt: 'Seu plano atual nao permite ativar mais plataformas.',
                          en: 'Your current plan does not allow more active platforms.',
                          es: 'Tu plan actual no permite activar mas plataformas.',
                        ),
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
          child: Text(strings.cancel),
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
          child: Text(strings.save),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context).pick(
        pt: 'Campo obrigatorio.',
        en: 'Required field.',
        es: 'Campo obligatorio.',
      );
    }
    return null;
  }

  void _scheduleSuggestionRefresh() {
    if (widget.initialPlatform != null) return;
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(
      const Duration(milliseconds: 450),
      _refreshSuggestions,
    );
  }

  Future<void> _refreshSuggestions() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }

    setState(() => _loadingSuggestions = true);
    final suggestions = await _platformService.findCatalogSuggestions(
      name: name,
      type: _type,
    );
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _loadingSuggestions = false;
    });
  }
}

class _SuggestionLogo extends StatelessWidget {
  const _SuggestionLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final logoUrl = url?.trim();
    final placeholder = CircleAvatar(
      backgroundColor: const Color(0xFF0000CD).withValues(alpha: 0.14),
      child: const Icon(Icons.storefront_outlined, color: Color(0xFF7582FF)),
    );
    if (logoUrl == null || logoUrl.isEmpty) return placeholder;
    return ClipOval(
      child: Image.network(
        logoUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
