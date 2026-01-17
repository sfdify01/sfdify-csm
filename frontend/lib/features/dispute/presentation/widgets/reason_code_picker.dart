import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ReasonCodePicker extends StatelessWidget {
  const ReasonCodePicker({
    super.key,
    required this.selectedCodes,
    required this.onChanged,
  });

  final List<String> selectedCodes;
  final ValueChanged<List<String>> onChanged;

  static const List<({String code, String description})> reasonCodes = [
    (code: 'NOT_MY_ACCOUNT', description: 'Account does not belong to me'),
    (code: 'WRONG_BALANCE', description: 'Balance reported is incorrect'),
    (code: 'WRONG_CREDIT_LIMIT', description: 'Credit limit is incorrect'),
    (code: 'WRONG_PAYMENT_HISTORY', description: 'Payment history is inaccurate'),
    (code: 'WRONG_DATE_OPENED', description: 'Account open date is wrong'),
    (code: 'WRONG_DATE_CLOSED', description: 'Account close date is wrong'),
    (code: 'ACCOUNT_PAID', description: 'Account was paid in full'),
    (code: 'INCLUDED_IN_BANKRUPTCY', description: 'Account included in bankruptcy'),
    (code: 'IDENTITY_THEFT', description: 'Result of identity theft'),
    (code: 'DUPLICATE_ACCOUNT', description: 'Duplicate of another account'),
    (code: 'TOO_OLD', description: 'Account is beyond 7-year limit'),
    (code: 'NO_VERIFICATION', description: 'Cannot be verified'),
    (code: 'REPORTING_ERROR', description: 'General reporting error'),
    (code: 'OTHER', description: 'Other reason (specify in narrative)'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reason Codes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${selectedCodes.length} selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          'Select all applicable reasons for the dispute',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasonCodes.map((reason) {
            final isSelected = selectedCodes.contains(reason.code);
            return FilterChip(
              label: Text(reason.description),
              selected: isSelected,
              onSelected: (selected) {
                final newCodes = List<String>.from(selectedCodes);
                if (selected) {
                  newCodes.add(reason.code);
                } else {
                  newCodes.remove(reason.code);
                }
                onChanged(newCodes);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}
