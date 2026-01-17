import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DisputeTypeSelector extends StatelessWidget {
  const DisputeTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onChanged;

  static const List<({String value, String label, String description})> disputeTypes = [
    (
      value: '609_request',
      label: 'Section 609 Request',
      description: 'Request original documents from credit bureau'
    ),
    (
      value: '611_dispute',
      label: 'Section 611 Dispute',
      description: 'Dispute accuracy of information'
    ),
    (
      value: 'mov_request',
      label: 'Method of Verification',
      description: 'Request verification method used by bureau'
    ),
    (
      value: 'deletion_request',
      label: 'Deletion Request',
      description: 'Request removal of inaccurate information'
    ),
    (
      value: 'goodwill_letter',
      label: 'Goodwill Letter',
      description: 'Request removal as act of goodwill'
    ),
    (
      value: 'debt_validation',
      label: 'Debt Validation',
      description: 'Request debt validation from collector'
    ),
    (
      value: 'pay_for_delete',
      label: 'Pay for Delete',
      description: 'Negotiate removal upon payment'
    ),
    (
      value: 'cease_desist',
      label: 'Cease & Desist',
      description: 'Stop collection calls'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dispute Type *',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: disputeTypes.map((type) {
            final isSelected = selectedType == type.value;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (_) => onChanged(type.value),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              tooltip: type.description,
            );
          }).toList(),
        ),
        if (selectedType != null) ...[
          const Gap(8),
          Text(
            disputeTypes.firstWhere((t) => t.value == selectedType).description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
