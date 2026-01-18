import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';

class LetterCostBreakdown extends StatelessWidget {
  const LetterCostBreakdown({
    super.key,
    required this.letter,
  });

  final LetterEntity letter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Cost Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            _CostRow(
              label: 'Mail Type',
              value: letter.mailTypeDisplayName,
            ),
            const Gap(8),
            _CostRow(
              label: 'Letter Type',
              value: letter.typeDisplayName,
            ),
            const Divider(height: 24),
            if (letter.cost != null) ...[
              _CostRow(
                label: 'Postage',
                value: _getPostageCost(letter.mailType),
                isMoney: true,
              ),
              const Gap(8),
              _CostRow(
                label: 'Processing Fee',
                value: '\$0.50',
                isMoney: true,
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    letter.formattedCost,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Cost will be calculated when the letter is approved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPostageCost(String mailType) {
    return switch (mailType) {
      'usps_first_class' => '\$0.63',
      'usps_certified' => '\$4.15',
      'usps_certified_return_receipt' => '\$7.46',
      _ => 'N/A',
    };
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.isMoney = false,
  });

  final String label;
  final String value;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isMoney ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
