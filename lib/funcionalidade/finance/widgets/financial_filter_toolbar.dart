import 'package:flutter/material.dart';

import '../../../utilities/localization/app_strings.dart';

class FinancialFilterToolbar extends StatelessWidget {
  const FinancialFilterToolbar({
    super.key,
    required this.searchController,
    required this.range,
    required this.hintText,
    required this.onPickRange,
    required this.onClear,
  });

  final TextEditingController searchController;
  final DateTimeRange range;
  final String hintText;
  final VoidCallback onPickRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final searchField = SizedBox(
      height: 44,
      child: TextField(
        controller: searchController,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: compact
              ? strings.pick(pt: 'Buscar', en: 'Search', es: 'Buscar')
              : hintText,
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: searchController.clear,
                  icon: const Icon(Icons.close, size: 18),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 36),
        ),
      ),
    );

    final dateButton = SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPickRange,
        icon: const Icon(Icons.calendar_today_outlined, size: 17),
        label: Text(_formatRange(range)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );

    final clearButton = SizedBox(
      height: 44,
      width: 44,
      child: IconButton(
        tooltip: strings.pick(
          pt: 'Limpar filtros',
          en: 'Clear filters',
          es: 'Limpiar filtros',
        ),
        onPressed: onClear,
        icon: const Icon(Icons.tune_outlined, size: 18),
      ),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 8),
          dateButton,
          clearButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        dateButton,
        const SizedBox(width: 6),
        TextButton(
          onPressed: onClear,
          child: Text(strings.pick(pt: 'Limpar', en: 'Clear', es: 'Limpiar')),
        ),
      ],
    );
  }

  String _formatRange(DateTimeRange value) {
    String format(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return '${format(value.start)} - ${format(value.end)}';
  }
}
