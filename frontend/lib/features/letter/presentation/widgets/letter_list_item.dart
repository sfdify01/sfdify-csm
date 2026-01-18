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
    this.showCheckbox = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final LetterEntity letter;
  final VoidCallback onTap;
  final bool showCheckbox;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

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
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox for selection
              if (showCheckbox) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged?.call(value ?? false),
                ),
                const Gap(8),
              ],

              // Round Badge
              _buildRoundBadge(context),
              const Gap(12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                letter.recipientDisplayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(8),
                              _buildRecipientTypeChip(context),
                            ],
                          ),
                        ),
                        LetterStatusChip(
                          status: letter.status,
                          size: LetterStatusChipSize.small,
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      letter.typeDisplayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
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
                    if (letter.hasResponse) ...[
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            size: 14,
                            color: Colors.teal,
                          ),
                          const Gap(4),
                          Text(
                            'Response received ${dateFormat.format(letter.responseReceivedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.teal,
                              fontWeight: FontWeight.w500,
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

  Widget _buildRoundBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isFollowup = letter.isFollowup;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isFollowup
            ? Colors.orange.shade50
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getLetterIcon(letter.type),
            size: 20,
            color: isFollowup
                ? Colors.orange.shade700
                : theme.colorScheme.onPrimaryContainer,
          ),
          const Gap(2),
          Text(
            'R${letter.round}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isFollowup
                  ? Colors.orange.shade700
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientTypeChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (letter.recipientType) {
      case LetterRecipientType.bureau:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Bureau';
        icon = Icons.account_balance;
        break;
      case LetterRecipientType.creditor:
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Creditor';
        icon = Icons.business;
        break;
      case LetterRecipientType.collector:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Collector';
        icon = Icons.phone_in_talk;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLetterIcon(String type) {
    return switch (type) {
      '609_request' => Icons.description,
      '611_dispute' => Icons.gavel,
      '605b_id_theft' => Icons.security,
      'mov_request' => Icons.fact_check,
      'reinvestigation' => Icons.refresh,
      'goodwill' => Icons.volunteer_activism,
      'pay_for_delete' => Icons.payments,
      'identity_theft_block' => Icons.security,
      'cfpb_complaint' => Icons.report,
      'cease_desist' => Icons.gavel,
      'debt_validation' => Icons.verified_user,
      _ => Icons.mail,
    };
  }
}
