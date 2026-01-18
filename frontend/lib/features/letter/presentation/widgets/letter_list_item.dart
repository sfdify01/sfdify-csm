import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';
import 'package:ustaxx_csm/features/letter/presentation/widgets/letter_status_chip.dart';

class LetterListItem extends StatelessWidget {
  const LetterListItem({
    super.key,
    required this.letter,
    required this.onTap,
  });

  final LetterEntity letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getLetterIcon(letter.type),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Gap(16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            letter.typeDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        LetterStatusChip(
                          status: letter.status,
                          size: LetterStatusChipSize.small,
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const Gap(4),
                        Text(
                          letter.mailTypeDisplayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Gap(16),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const Gap(4),
                        Text(
                          dateFormat.format(letter.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (letter.hasTracking) ...[
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const Gap(4),
                          Text(
                            letter.trackingCode!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(16),
              // Cost and action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (letter.cost != null)
                    Text(
                      letter.formattedCost,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const Gap(4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLetterIcon(String type) {
    return switch (type) {
      '609_request' => Icons.description,
      '611_dispute' => Icons.gavel,
      'mov_request' => Icons.fact_check,
      'reinvestigation' => Icons.refresh,
      'goodwill' => Icons.volunteer_activism,
      'pay_for_delete' => Icons.payments,
      'identity_theft_block' => Icons.security,
      'cfpb_complaint' => Icons.report,
      _ => Icons.mail,
    };
  }
}
