import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

class ConsumerListItem extends StatelessWidget {
  const ConsumerListItem({
    super.key,
    required this.consumer,
    this.onTap,
    this.onActiveToggled,
  });

  final ConsumerEntity consumer;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onActiveToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                consumer.initials,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const Gap(12),

            // Consumer Name & Email
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consumer.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    consumer.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // DOB Column
            SizedBox(
              width: 90,
              child: Text(
                consumer.formattedDateOfBirth ?? '-',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),

            // Active Column
            SizedBox(
              width: 70,
              child: _buildActiveChip(context),
            ),

            // Status Column
            SizedBox(
              width: 130,
              child: _buildStatusChip(context),
            ),

            // Last Sent Letter Column
            SizedBox(
              width: 110,
              child: _buildRelativeDateCell(
                context,
                consumer.lastSentLetterAt,
                emptyText: 'Never',
              ),
            ),

            // Last Credit Report Column
            SizedBox(
              width: 130,
              child: _buildCreditReportCell(context),
            ),

            // Actions Column
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: onTap,
                    tooltip: 'View Details',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showActionsMenu(context),
                    tooltip: 'More Actions',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip(BuildContext context) {
    final isActive = consumer.isActive;

    return GestureDetector(
      onTap: () => onActiveToggled?.call(!isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(4),
            Text(
              isActive ? 'Yes' : 'No',
              style: TextStyle(
                color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final status = consumer.status;
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case ConsumerStatus.unsent:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Unsent';
        icon = Icons.hourglass_empty;
        break;
      case ConsumerStatus.awaitingResponse:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Awaiting';
        icon = Icons.schedule;
        break;
      case ConsumerStatus.inProgress:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'In Progress';
        icon = Icons.pending_actions;
        break;
      case ConsumerStatus.completed:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const Gap(4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelativeDateCell(
    BuildContext context,
    DateTime? date, {
    required String emptyText,
  }) {
    final theme = Theme.of(context);

    if (date == null) {
      return Text(
        emptyText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      );
    }

    return Text(
      _formatRelativeTime(date),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildCreditReportCell(BuildContext context) {
    final theme = Theme.of(context);
    final lastReport = consumer.lastCreditReportAt;
    final isConnected = consumer.isSmartCreditConnected;

    if (!isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Not Connected',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    if (lastReport == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const Gap(4),
          Text(
            'Pull Report',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final daysSinceRefresh = DateTime.now().difference(lastReport).inDays;
    final canRefresh = daysSinceRefresh >= 7;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canRefresh)
          Icon(
            Icons.refresh,
            size: 14,
            color: Colors.green,
          ),
        const Gap(4),
        Flexible(
          child: Text(
            _formatRelativeTime(lastReport),
            style: theme.textTheme.bodySmall?.copyWith(
              color: canRefresh
                  ? Colors.green
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: canRefresh ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Consumer'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/consumers/${consumer.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Create Dispute'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/disputes/new?consumerId=${consumer.id}');
              },
            ),
            if (consumer.isSmartCreditConnected)
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Refresh Credit Report'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing credit report...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            if (!consumer.isSmartCreditConnected)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Connect Credit Report'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/consumers/${consumer.id}');
                },
              ),
            ListTile(
              leading: Icon(
                consumer.isActive ? Icons.pause : Icons.play_arrow,
              ),
              title: Text(consumer.isActive ? 'Set Inactive' : 'Set Active'),
              onTap: () {
                Navigator.pop(ctx);
                onActiveToggled?.call(!consumer.isActive);
              },
            ),
          ],
        ),
      ),
    );
  }
}
