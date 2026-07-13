import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'omnya_visuals.dart';

class OmnyaFabAction {
  const OmnyaFabAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

BoxDecoration omnyaBackgroundDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      colors: isDark
          ? const [Color(0xFF070A12), Color(0xFF090D18), Color(0xFF05070D)]
          : const [Color(0xFFF8FAFF), Color(0xFFF0F4FF), Color(0xFFE9EEFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

class OmnyaPageBackground extends StatelessWidget {
  const OmnyaPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OmnyaAtmosphere(child: child);
  }
}

class OmnyaSubPageScaffold extends StatelessWidget {
  const OmnyaSubPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActions = const [],
    this.actions,
    this.heroTagPrefix,
  });

  final String title;
  final Widget body;
  final List<OmnyaFabAction> floatingActions;
  final List<Widget>? actions;
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        title: Text(title),
        actions: actions,
      ),
      body: OmnyaPageBackground(child: OmnyaAnimatedEntrance(child: body)),
      floatingActionButton: floatingActions.isEmpty
          ? null
          : OmnyaFloatingActionMenu(
              actions: floatingActions,
              heroTagPrefix: heroTagPrefix ?? title.toLowerCase(),
            ),
    );
  }
}

class OmnyaFloatingActionMenu extends StatefulWidget {
  const OmnyaFloatingActionMenu({
    super.key,
    required this.actions,
    required this.heroTagPrefix,
  });

  final List<OmnyaFabAction> actions;
  final String heroTagPrefix;

  @override
  State<OmnyaFloatingActionMenu> createState() =>
      _OmnyaFloatingActionMenuState();
}

class _OmnyaFloatingActionMenuState extends State<OmnyaFloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (keyboardOpen) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final curve = CurvedAnimation(
                parent: _controller,
                curve: Interval(index * 0.08, 1, curve: Curves.easeOutBack),
              );
              final value = curve.value;

              return IgnorePointer(
                ignoring: !_open,
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 24),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OmnyaGlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            borderRadius: 18,
                            child: Text(
                              action.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FloatingActionButton.small(
                            heroTag:
                                '${widget.heroTagPrefix}-action-$index-${action.label}',
                            elevation: 10,
                            backgroundColor: OmnyaVisualTokens.omnyaPrimary,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              _toggle();
                              action.onTap();
                            },
                            child: Icon(action.icon),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        FloatingActionButton.extended(
          heroTag: '${widget.heroTagPrefix}-main-fab',
          onPressed: _toggle,
          elevation: 14,
          backgroundColor: OmnyaVisualTokens.electricBlue,
          foregroundColor: Colors.white,
          icon: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 240),
            child: const Icon(Icons.add),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
          label: Text(
            _open
                ? AppStrings.of(context).close
                : AppStrings.of(context).newItem,
          ),
        ),
      ],
    );
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
      return;
    }
    _controller.reverse();
  }
}
