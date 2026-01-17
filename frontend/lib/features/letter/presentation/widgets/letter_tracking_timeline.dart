import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class LetterTrackingTimeline extends StatelessWidget {
  const LetterTrackingTimeline({
    super.key,
    required this.letter,
  });

  final LetterEntity letter;

  Future<void> _openTracking() async {
    if (letter.trackingUrl != null) {
      final uri = Uri.parse(letter.trackingUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  'Tracking Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (letter.hasTracking)
                  TextButton.icon(
                    onPressed: _openTracking,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Track on USPS'),
                  ),
              ],
            ),
          ),
          // Tracking code
          if (letter.trackingCode != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Tracking Number: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SelectableText(
                    letter.trackingCode!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _TimelineItem(
                  title: 'Created',
                  date: letter.createdAt,
                  isComplete: true,
                  isFirst: true,
                  dateFormat: dateFormat,
                ),
                _TimelineItem(
                  title: 'Approved',
                  date: letter.approvedAt,
                  isComplete: letter.approvedAt != null,
                  dateFormat: dateFormat,
                ),
                _TimelineItem(
                  title: 'Sent',
                  date: letter.sentAt,
                  isComplete: letter.sentAt != null,
                  dateFormat: dateFormat,
                ),
                _TimelineItem(
                  title: 'In Transit',
                  date: letter.inTransitAt,
                  isComplete: letter.inTransitAt != null,
                  dateFormat: dateFormat,
                ),
                _TimelineItem(
                  title: letter.isReturned ? 'Returned' : 'Delivered',
                  date: letter.isReturned ? letter.returnedAt : letter.deliveredAt,
                  isComplete: letter.isDelivered || letter.isReturned,
                  isLast: true,
                  isError: letter.isReturned,
                  dateFormat: dateFormat,
                ),
              ],
            ),
          ),
          // Expected delivery
          if (letter.expectedDeliveryDate != null && !letter.isDelivered)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const Gap(8),
                  Text(
                    'Expected Delivery: ${DateFormat('EEEE, MMM d, yyyy').format(letter.expectedDeliveryDate!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.date,
    required this.isComplete,
    required this.dateFormat,
    this.isFirst = false,
    this.isLast = false,
    this.isError = false,
  });

  final String title;
  final DateTime? date;
  final bool isComplete;
  final DateFormat dateFormat;
  final bool isFirst;
  final bool isLast;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError
        ? Colors.red
        : isComplete
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isComplete ? color : theme.colorScheme.outlineVariant,
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isComplete ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                      color: isComplete
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (date != null)
                    Text(
                      dateFormat.format(date!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else if (!isComplete)
                    Text(
                      'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
