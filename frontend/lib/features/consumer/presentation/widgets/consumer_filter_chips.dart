import 'package:flutter/material.dart';

class ConsumerFilterChips extends StatelessWidget {
  const ConsumerFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onStatusSelected;

  static const List<({String? value, String label, IconData icon})> _filters = [
    (value: null, label: 'All Consumers', icon: Icons.people_outline),
    (value: 'active', label: 'Active', icon: Icons.check_circle_outline),
    (value: 'smartcredit_connected', label: 'SmartCredit Connected', icon: Icons.link),
    (value: 'has_disputes', label: 'Has Disputes', icon: Icons.description_outlined),
    (value: 'recent', label: 'Added Recently', icon: Icons.schedule),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = selectedStatus == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(filter.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onStatusSelected(filter.value),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
