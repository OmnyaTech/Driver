import 'package:flutter/material.dart';

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

    final searchField = TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: searchController.clear,
                icon: const Icon(Icons.close),
              ),
      ),
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onPickRange,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_formatRange(range)),
        ),
        TextButton(onPressed: onClear, child: const Text('Limpar')),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [searchField, const SizedBox(height: 12), actions],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  String _formatRange(DateTimeRange value) {
    String format(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return '${format(value.start)} - ${format(value.end)}';
  }
}
