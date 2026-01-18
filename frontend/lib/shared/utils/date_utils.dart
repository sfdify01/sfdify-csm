import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for date formatting and relative time display.
class AppDateUtils {
  AppDateUtils._();

  /// Formats a DateTime to a relative time string.
  ///
  /// Examples:
  /// - "Just now" (within 1 minute)
  /// - "5 minutes ago"
  /// - "2 hours ago"
  /// - "Yesterday"
  /// - "3 days ago"
  /// - "2 weeks ago"
  /// - "1 month ago"
  /// - "Jan 15, 2025" (more than 3 months ago)
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future date
      return _formatFutureRelativeTime(difference.abs());
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    if (difference.inDays < 90) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    // More than 3 months ago, show actual date
    return DateFormat.yMMMd().format(dateTime);
  }

  /// Formats a future time relative to now.
  static String _formatFutureRelativeTime(Duration difference) {
    if (difference.inSeconds < 60) {
      return 'In a moment';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'In $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'In $hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    if (difference.inDays == 1) {
      return 'Tomorrow';
    }

    if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }

    final months = (difference.inDays / 30).floor();
    return 'In $months ${months == 1 ? 'month' : 'months'}';
  }

  /// Formats a DateTime to a short relative string.
  ///
  /// Examples: "5m", "2h", "3d", "2w", "1mo"
  static String formatRelativeTimeShort(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return _formatFutureRelativeTimeShort(difference.abs());
    }

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    }

    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    }

    return '${(difference.inDays / 365).floor()}y';
  }

  static String _formatFutureRelativeTimeShort(Duration difference) {
    if (difference.inMinutes < 1) {
      return 'soon';
    }

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return 'in ${difference.inDays}d';
    }

    return 'in ${(difference.inDays / 7).floor()}w';
  }

  /// Formats a date for display in lists (e.g., "Jan 15" or "Jan 15, 2024")
  static String formatListDate(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final now = DateTime.now();
    if (dateTime.year == now.year) {
      return DateFormat.MMMd().format(dateTime);
    }
    return DateFormat.yMMMd().format(dateTime);
  }

  /// Formats a date with time (e.g., "Jan 15 at 3:45 PM")
  static String formatDateWithTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM d \'at\' h:mm a').format(dateTime);
  }

  /// Formats a full date (e.g., "January 15, 2025")
  static String formatFullDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat.yMMMMd().format(dateTime);
  }

  /// Formats a date for forms/inputs (e.g., "01/15/2025")
  static String formatFormDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MM/dd/yyyy').format(dateTime);
  }

  /// Formats a time only (e.g., "3:45 PM")
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat.jm().format(dateTime);
  }

  /// Calculates days until a future date
  static int? daysUntil(DateTime? dateTime) {
    if (dateTime == null) return null;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTarget = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return startOfTarget.difference(startOfToday).inDays;
  }

  /// Calculates days since a past date
  static int? daysSince(DateTime? dateTime) {
    if (dateTime == null) return null;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTarget = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return startOfToday.difference(startOfTarget).inDays;
  }

  /// Checks if a date is today
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Checks if a date is yesterday
  static bool isYesterday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Checks if a date is within the last N days
  static bool isWithinDays(DateTime? dateTime, int days) {
    if (dateTime == null) return false;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return dateTime.isAfter(cutoff);
  }
}

/// A widget that displays a relative time and optionally updates automatically.
class RelativeTimeText extends StatelessWidget {
  const RelativeTimeText({
    super.key,
    required this.dateTime,
    this.style,
    this.prefix,
    this.suffix,
    this.shortFormat = false,
    this.showTooltip = true,
  });

  final DateTime? dateTime;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final bool shortFormat;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final text = shortFormat
        ? AppDateUtils.formatRelativeTimeShort(dateTime)
        : AppDateUtils.formatRelativeTime(dateTime);

    final displayText =
        '${prefix ?? ''}$text${suffix ?? ''}';

    final widget = Text(
      displayText,
      style: style ??
          TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
    );

    if (showTooltip && dateTime != null) {
      return Tooltip(
        message: AppDateUtils.formatDateWithTime(dateTime),
        child: widget,
      );
    }

    return widget;
  }
}

/// A widget that shows a countdown or time since indicator.
class TimeSinceIndicator extends StatelessWidget {
  const TimeSinceIndicator({
    super.key,
    required this.dateTime,
    this.warningDays = 7,
    this.dangerDays = 30,
  });

  final DateTime? dateTime;
  final int warningDays;
  final int dangerDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dateTime == null) {
      return Text(
        'Never',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final daysSince = AppDateUtils.daysSince(dateTime);
    final color = _getColor(daysSince ?? 0, theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          AppDateUtils.formatRelativeTime(dateTime),
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Color _getColor(int days, ThemeData theme) {
    if (days <= warningDays) return Colors.green;
    if (days <= dangerDays) return Colors.orange;
    return theme.colorScheme.error;
  }
}

/// A widget that shows days remaining until a deadline.
class DaysRemainingBadge extends StatelessWidget {
  const DaysRemainingBadge({
    super.key,
    required this.deadline,
    this.warningDays = 7,
    this.dangerDays = 3,
  });

  final DateTime? deadline;
  final int warningDays;
  final int dangerDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (deadline == null) {
      return const SizedBox.shrink();
    }

    final daysUntil = AppDateUtils.daysUntil(deadline);
    if (daysUntil == null) return const SizedBox.shrink();

    final (backgroundColor, textColor, text) = _getDisplayConfig(daysUntil, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _getDisplayConfig(int days, ThemeData theme) {
    if (days < 0) {
      return (
        theme.colorScheme.error.withValues(alpha: 0.1),
        theme.colorScheme.error,
        'Overdue by ${-days} ${-days == 1 ? 'day' : 'days'}',
      );
    }

    if (days == 0) {
      return (
        theme.colorScheme.error.withValues(alpha: 0.1),
        theme.colorScheme.error,
        'Due today',
      );
    }

    if (days <= dangerDays) {
      return (
        Colors.orange.withValues(alpha: 0.1),
        Colors.orange.shade800,
        '$days ${days == 1 ? 'day' : 'days'} left',
      );
    }

    if (days <= warningDays) {
      return (
        Colors.amber.withValues(alpha: 0.1),
        Colors.amber.shade800,
        '$days days left',
      );
    }

    return (
      Colors.green.withValues(alpha: 0.1),
      Colors.green.shade700,
      '$days days left',
    );
  }
}
