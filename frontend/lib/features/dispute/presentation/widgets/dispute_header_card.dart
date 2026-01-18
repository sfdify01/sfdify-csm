import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';

class DisputeHeaderCard extends StatelessWidget {
  const DisputeHeaderCard({
    super.key,
    required this.dispute,
  });

  final DisputeEntity dispute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(dispute.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(dispute.status),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(dispute.status),
                        size: 16,
                        color: _getStatusColor(dispute.status),
                      ),
                      const Gap(6),
                      Text(
                        dispute.statusDisplayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _getStatusColor(dispute.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(dispute.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dispute.priority.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getPriorityColor(dispute.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Dispute Type
            Text(
              dispute.typeDisplayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),

            // Bureau & Consumer Info
            Row(
              children: [
                _buildInfoChip(context, dispute.bureauDisplayName, Icons.business),
                const Gap(8),
                if (dispute.consumer != null)
                  _buildInfoChip(
                    context,
                    dispute.consumer!.fullName,
                    Icons.person_outline,
                  ),
              ],
            ),
            const Gap(16),

            const Divider(),
            const Gap(16),

            // Timeline Info
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    context,
                    label: 'Created',
                    date: dispute.createdAt,
                  ),
                ),
                Expanded(
                  child: _buildDateInfo(
                    context,
                    label: 'Submitted',
                    date: dispute.submittedAt,
                  ),
                ),
                Expanded(
                  child: _buildDateInfo(
                    context,
                    label: 'Due Date',
                    date: dispute.dueAt,
                    isWarning: dispute.isOverdue || dispute.isSlaApproaching,
                  ),
                ),
                if (dispute.daysRemaining != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: dispute.isOverdue
                          ? Colors.red.withValues(alpha: 0.1)
                          : dispute.isSlaApproaching
                              ? Colors.orange.withValues(alpha: 0.1)
                              : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dispute.daysRemaining!.abs().toString(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dispute.isOverdue
                                ? Colors.red
                                : dispute.isSlaApproaching
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          dispute.isOverdue ? 'days overdue' : 'days left',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const Gap(6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(
    BuildContext context, {
    required String label,
    DateTime? date,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(4),
        Text(
          date != null
              ? '${date.month}/${date.day}/${date.year}'
              : 'Not set',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isWarning ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'pending_review':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'mailed':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
      case 'bureau_investigating':
        return Colors.indigo;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit_outlined;
      case 'pending_review':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'mailed':
      case 'in_transit':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.mark_email_read_outlined;
      case 'bureau_investigating':
        return Icons.search;
      case 'resolved':
        return Icons.verified_outlined;
      case 'closed':
        return Icons.archive_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
