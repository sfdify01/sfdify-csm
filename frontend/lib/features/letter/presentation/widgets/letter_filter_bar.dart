import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LetterFilterBar extends StatelessWidget {
  const LetterFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.searchQuery,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;

  static const List<({String? value, String label, IconData icon})> statusFilters = [
    (value: null, label: 'All', icon: Icons.all_inbox),
    (value: 'draft', label: 'Draft', icon: Icons.edit_note),
    (value: 'pending_approval', label: 'Pending', icon: Icons.hourglass_empty),
    (value: 'approved', label: 'Approved', icon: Icons.check_circle_outline),
    (value: 'sent', label: 'In Transit', icon: Icons.local_shipping),
    (value: 'delivered', label: 'Delivered', icon: Icons.done_all),
    (value: 'returned_to_sender', label: 'Returned', icon: Icons.replay),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        SizedBox(
          width: 320,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search letters...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ),
        const Gap(16),
        // Status filter chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusFilters.map((filter) {
            final isSelected = selectedStatus == filter.value;
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(filter.label),
                ],
              ),
              onSelected: (_) => onStatusChanged(filter.value),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
