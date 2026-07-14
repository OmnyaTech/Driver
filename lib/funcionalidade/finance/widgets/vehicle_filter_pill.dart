import 'package:flutter/material.dart';

import '../../../utilities/localization/app_strings.dart';

class VehicleFilterPill extends StatelessWidget {
  const VehicleFilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withValues(alpha: 0.72)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.34,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.two_wheeler_rounded, size: 17),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: strings.pick(
                    pt: 'Limpar veiculo',
                    en: 'Clear vehicle',
                    es: 'Limpiar vehiculo',
                  ),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
