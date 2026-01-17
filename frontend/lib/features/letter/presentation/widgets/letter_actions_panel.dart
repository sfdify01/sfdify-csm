import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_bloc.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_event.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_detail_state.dart';
import 'package:sfdify_scm/features/letter/presentation/widgets/letter_status_chip.dart';

class LetterActionsPanel extends StatelessWidget {
  const LetterActionsPanel({
    super.key,
    required this.letter,
    required this.state,
  });

  final LetterEntity letter;
  final LetterDetailState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProcessing = state.actionStatus == LetterActionStatus.processing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            // Status
            Row(
              children: [
                Text(
                  'Status: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                LetterStatusChip(
                  status: letter.status,
                  size: LetterStatusChipSize.medium,
                ),
              ],
            ),
            const Gap(16),
            // Action buttons based on status
            if (state.canApprove) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _showApproveDialog(context),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Approve Letter'),
                ),
              ),
            ],
            if (state.canSend) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _showSendDialog(context),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send Letter'),
                ),
              ),
            ],
            if (letter.isInTransit || letter.isDelivered) ...[
              _InfoRow(
                icon: Icons.schedule,
                label: 'Sent',
                value: letter.sentAt != null
                    ? '${_daysSince(letter.sentAt!)} days ago'
                    : 'N/A',
              ),
              if (letter.isDelivered) ...[
                const Gap(8),
                _InfoRow(
                  icon: Icons.done_all,
                  label: 'Delivered',
                  value: letter.deliveredAt != null
                      ? '${_daysSince(letter.deliveredAt!)} days ago'
                      : 'N/A',
                  color: Colors.green,
                ),
              ],
            ],
            if (letter.isReturned) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'This letter was returned to sender. Please verify the recipient address.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Gap(16),
            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.hasPdf ? () {} : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Duplicate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _daysSince(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Letter'),
        content: const Text(
          'Are you sure you want to approve this letter? Once approved, it can be sent via mail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<LetterDetailBloc>()
                  .add(const LetterDetailApproveRequested());
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showSendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Letter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will send the letter via USPS. This action cannot be undone.',
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mail Type: ${letter.mailTypeDisplayName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (letter.cost != null) ...[
                    const Gap(4),
                    Text(
                      'Cost: ${letter.formattedCost}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<LetterDetailBloc>()
                  .add(const LetterDetailSendRequested());
            },
            child: const Text('Send Letter'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const Gap(8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
