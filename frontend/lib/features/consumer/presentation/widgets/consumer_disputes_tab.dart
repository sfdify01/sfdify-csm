import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

class ConsumerDisputesTab extends StatelessWidget {
  const ConsumerDisputesTab({
    super.key,
    required this.disputes,
    required this.consumerId,
  });

  final List<DisputeEntity> disputes;
  final String consumerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disputes (${disputes.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    context.go('/disputes/new?consumerId=$consumerId');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Dispute'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Disputes List
          if (disputes.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildDisputeItem(context, disputes[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const Gap(16),
            Text(
              'No disputes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Gap(8),
            Text(
              'Create a dispute to start the credit repair process',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeItem(BuildContext context, DisputeEntity dispute) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.go('/disputes/${dispute.id}');
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(dispute.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(dispute.status),
                size: 20,
                color: _getStatusColor(dispute.status),
              ),
            ),
            const Gap(16),

            // Dispute Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispute.typeDisplayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      _buildTag(context, dispute.bureauDisplayName),
                      const Gap(8),
                      _buildStatusTag(context, dispute),
                    ],
                  ),
                ],
              ),
            ),

            // Days Remaining
            if (dispute.daysRemaining != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${dispute.daysRemaining} days',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dispute.isOverdue
                          ? Colors.red
                          : dispute.isSlaApproaching
                              ? Colors.orange
                              : null,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

            const Gap(8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  Widget _buildStatusTag(BuildContext context, DisputeEntity dispute) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(dispute.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dispute.statusDisplayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(dispute.status),
            ),
      ),
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
}
