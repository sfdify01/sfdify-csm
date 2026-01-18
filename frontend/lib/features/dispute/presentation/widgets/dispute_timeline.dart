import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';

class DisputeTimeline extends StatelessWidget {
  const DisputeTimeline({
    super.key,
    required this.dispute,
  });

  final DisputeEntity dispute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = _buildTimelineEvents();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            ...events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == events.length - 1;

              return _buildTimelineItem(
                context,
                event: event,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_TimelineEvent> _buildTimelineEvents() {
    final events = <_TimelineEvent>[];

    events.add(_TimelineEvent(
      title: 'Dispute Created',
      date: dispute.createdAt,
      icon: Icons.add_circle_outline,
      isCompleted: true,
    ));

    if (dispute.submittedAt != null) {
      events.add(_TimelineEvent(
        title: 'Submitted for Review',
        date: dispute.submittedAt!,
        icon: Icons.send,
        isCompleted: true,
      ));
    }

    if (dispute.status == 'approved' ||
        dispute.status == 'mailed' ||
        dispute.status == 'in_transit' ||
        dispute.status == 'delivered' ||
        dispute.status == 'bureau_investigating' ||
        dispute.status == 'resolved') {
      events.add(_TimelineEvent(
        title: 'Approved',
        date: dispute.updatedAt,
        icon: Icons.check_circle,
        isCompleted: true,
      ));
    }

    if (dispute.status == 'mailed' ||
        dispute.status == 'in_transit' ||
        dispute.status == 'delivered' ||
        dispute.status == 'bureau_investigating' ||
        dispute.status == 'resolved') {
      events.add(_TimelineEvent(
        title: 'Letter Mailed',
        date: dispute.updatedAt,
        icon: Icons.mail,
        isCompleted: true,
      ));
    }

    if (dispute.status == 'delivered' ||
        dispute.status == 'bureau_investigating' ||
        dispute.status == 'resolved') {
      events.add(_TimelineEvent(
        title: 'Delivered to Bureau',
        date: dispute.updatedAt,
        icon: Icons.mark_email_read,
        isCompleted: true,
      ));
    }

    if (dispute.bureauResponseReceivedAt != null) {
      events.add(_TimelineEvent(
        title: 'Bureau Response Received',
        date: dispute.bureauResponseReceivedAt!,
        icon: Icons.reply,
        isCompleted: true,
      ));
    }

    if (dispute.closedAt != null) {
      events.add(_TimelineEvent(
        title: dispute.status == 'resolved' ? 'Resolved' : 'Closed',
        date: dispute.closedAt!,
        icon: dispute.status == 'resolved'
            ? Icons.verified
            : Icons.archive,
        isCompleted: true,
      ));
    }

    // Add pending steps
    if (dispute.status == 'draft') {
      events.add(_TimelineEvent(
        title: 'Submit for Review',
        icon: Icons.send,
        isCompleted: false,
      ));
    }

    if (dispute.status == 'pending_review') {
      events.add(_TimelineEvent(
        title: 'Pending Approval',
        icon: Icons.hourglass_empty,
        isCompleted: false,
      ));
    }

    return events;
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required _TimelineEvent event,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final color = event.isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: event.isCompleted
                      ? color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  event.icon,
                  size: 16,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color,
                  ),
                ),
            ],
          ),
          const Gap(16),

          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: event.isCompleted ? null : color,
                    ),
                  ),
                  if (event.date != null) ...[
                    const Gap(4),
                    Text(
                      _formatDate(event.date!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _TimelineEvent {
  final String title;
  final DateTime? date;
  final IconData icon;
  final bool isCompleted;

  _TimelineEvent({
    required this.title,
    this.date,
    required this.icon,
    required this.isCompleted,
  });
}
