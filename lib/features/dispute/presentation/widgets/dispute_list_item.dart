import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sfdify_scm/core/theme/app_colors.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

class DisputeListItem extends StatelessWidget {
  const DisputeListItem({
    required this.dispute,
    this.onTap,
    super.key,
  });

  final DisputeEntity dispute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Consumer avatar
            CircleAvatar(
              backgroundColor: _getBureauColor(dispute.bureau),
              child: Text(
                dispute.consumer?.initials ??
                    dispute.consumerId.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(12),

            // Consumer info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispute.consumer?.fullName ?? 'Unknown Consumer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ID: ${dispute.consumerId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Bureau badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBureauColor(dispute.bureau).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getBureauColor(dispute.bureau),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    dispute.bureauDisplayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getBureauColor(dispute.bureau),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Dispute type
            Expanded(
              flex: 2,
              child: Text(
                dispute.typeDisplayName,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(12),

            // Status badge
            _buildStatusBadge(theme, dispute),
            const Gap(12),

            // Actions
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              iconSize: 20,
              onPressed: onTap,
              tooltip: 'View details',
            ),
          ],
        ),
      ),
    );
  }

  Color _getBureauColor(String bureau) {
    switch (bureau) {
      case 'equifax':
        return AppColors.error;
      case 'experian':
        return const Color(0xFF3B82F6);
      case 'transunion':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  Widget _buildStatusBadge(ThemeData theme, DisputeEntity dispute) {
    final statusColor = _getStatusColor(dispute.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dispute.statusDisplayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'mailed':
        return AppColors.warning;
      case 'pending_review':
        return const Color(0xFF3B82F6);
      case 'failed':
      case 'returned_to_sender':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }
}
