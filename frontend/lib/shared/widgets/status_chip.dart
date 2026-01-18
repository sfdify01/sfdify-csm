import 'package:flutter/material.dart';

/// Standardized status chip widget for consistent status display across the app.
///
/// Supports various entity types:
/// - Consumer status (unsent, awaiting_response, in_progress, completed)
/// - Dispute status (pending, submitted, investigating, resolved, rejected)
/// - Letter status (draft, approved, mailed, in_transit, delivered, returned)
/// - Document status (pending, verified, rejected, expired)
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    required this.statusType,
    this.size = StatusChipSize.medium,
    this.showIcon = false,
  });

  final String status;
  final StatusType statusType;
  final StatusChipSize size;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StatusChipSize.small ? 8 : 12,
        vertical: size == StatusChipSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(size == StatusChipSize.small ? 4 : 6),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: size == StatusChipSize.small ? 12 : 14,
              color: config.textColor,
            ),
            SizedBox(width: size == StatusChipSize.small ? 4 : 6),
          ],
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: size == StatusChipSize.small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (statusType) {
      case StatusType.consumer:
        return _getConsumerStatusConfig();
      case StatusType.dispute:
        return _getDisputeStatusConfig();
      case StatusType.letter:
        return _getLetterStatusConfig();
      case StatusType.document:
        return _getDocumentStatusConfig();
      case StatusType.payment:
        return _getPaymentStatusConfig();
    }
  }

  _StatusConfig _getConsumerStatusConfig() {
    switch (status.toLowerCase()) {
      case 'unsent':
        return _StatusConfig(
          label: 'Unsent',
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.hourglass_empty,
        );
      case 'awaiting_response':
      case 'awaiting response':
        return _StatusConfig(
          label: 'Awaiting Response',
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade800,
          icon: Icons.schedule,
        );
      case 'in_progress':
      case 'in progress':
        return _StatusConfig(
          label: 'In Progress',
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade700,
          icon: Icons.autorenew,
        );
      case 'completed':
        return _StatusConfig(
          label: 'Completed',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case 'active':
        return _StatusConfig(
          label: 'Active',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case 'inactive':
        return _StatusConfig(
          label: 'Inactive',
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade600,
          icon: Icons.pause_circle,
        );
      default:
        return _StatusConfig(
          label: _formatLabel(status),
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  _StatusConfig _getDisputeStatusConfig() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'draft':
        return _StatusConfig(
          label: 'Pending',
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.pending,
        );
      case 'submitted':
        return _StatusConfig(
          label: 'Submitted',
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade700,
          icon: Icons.send,
        );
      case 'investigating':
      case 'in_review':
        return _StatusConfig(
          label: 'Investigating',
          backgroundColor: Colors.purple.shade50,
          borderColor: Colors.purple.shade300,
          textColor: Colors.purple.shade700,
          icon: Icons.search,
        );
      case 'resolved':
      case 'verified':
        return _StatusConfig(
          label: 'Resolved',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case 'deleted':
        return _StatusConfig(
          label: 'Deleted',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.delete_sweep,
        );
      case 'rejected':
        return _StatusConfig(
          label: 'Rejected',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.cancel,
        );
      case 'needs_followup':
      case 'needs followup':
        return _StatusConfig(
          label: 'Needs Followup',
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade300,
          textColor: Colors.orange.shade800,
          icon: Icons.reply,
        );
      default:
        return _StatusConfig(
          label: _formatLabel(status),
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  _StatusConfig _getLetterStatusConfig() {
    switch (status.toLowerCase()) {
      case 'draft':
        return _StatusConfig(
          label: 'Draft',
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.edit_note,
        );
      case 'approved':
      case 'ready':
        return _StatusConfig(
          label: 'Ready to Send',
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade700,
          icon: Icons.check,
        );
      case 'mailed':
      case 'sent':
        return _StatusConfig(
          label: 'Sent',
          backgroundColor: Colors.indigo.shade50,
          borderColor: Colors.indigo.shade300,
          textColor: Colors.indigo.shade700,
          icon: Icons.outbox,
        );
      case 'in_transit':
      case 'in transit':
        return _StatusConfig(
          label: 'In Transit',
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade800,
          icon: Icons.local_shipping,
        );
      case 'delivered':
        return _StatusConfig(
          label: 'Delivered',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.mark_email_read,
        );
      case 'returned':
        return _StatusConfig(
          label: 'Returned',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.undo,
        );
      case 'failed':
        return _StatusConfig(
          label: 'Failed',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.error,
        );
      default:
        return _StatusConfig(
          label: _formatLabel(status),
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  _StatusConfig _getDocumentStatusConfig() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'uploaded':
        return _StatusConfig(
          label: 'Pending Review',
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade800,
          icon: Icons.hourglass_empty,
        );
      case 'verified':
      case 'approved':
        return _StatusConfig(
          label: 'Verified',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.verified,
        );
      case 'rejected':
        return _StatusConfig(
          label: 'Rejected',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.cancel,
        );
      case 'expired':
        return _StatusConfig(
          label: 'Expired',
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade300,
          textColor: Colors.orange.shade800,
          icon: Icons.schedule,
        );
      default:
        return _StatusConfig(
          label: _formatLabel(status),
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  _StatusConfig _getPaymentStatusConfig() {
    switch (status.toLowerCase()) {
      case 'current':
        return _StatusConfig(
          label: 'Current',
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case '30_days_late':
      case '30 days late':
        return _StatusConfig(
          label: '30 Days Late',
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade800,
          icon: Icons.warning,
        );
      case '60_days_late':
      case '60 days late':
        return _StatusConfig(
          label: '60 Days Late',
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade300,
          textColor: Colors.orange.shade800,
          icon: Icons.warning,
        );
      case '90_days_late':
      case '90 days late':
        return _StatusConfig(
          label: '90+ Days Late',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.error,
        );
      case 'collection':
        return _StatusConfig(
          label: 'Collection',
          backgroundColor: Colors.red.shade100,
          borderColor: Colors.red.shade400,
          textColor: Colors.red.shade800,
          icon: Icons.gavel,
        );
      case 'charged_off':
      case 'charge off':
        return _StatusConfig(
          label: 'Charged Off',
          backgroundColor: Colors.red.shade100,
          borderColor: Colors.red.shade400,
          textColor: Colors.red.shade800,
          icon: Icons.money_off,
        );
      case 'closed':
        return _StatusConfig(
          label: 'Closed',
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.lock,
        );
      default:
        return _StatusConfig(
          label: _formatLabel(status),
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}

/// Status types supported by StatusChip
enum StatusType {
  consumer,
  dispute,
  letter,
  document,
  payment,
}

/// Size options for StatusChip
enum StatusChipSize {
  small,
  medium,
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
}

/// Priority chip for displaying dispute/letter priority levels
class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.priority,
    this.size = StatusChipSize.medium,
  });

  final String priority;
  final StatusChipSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StatusChipSize.small ? 8 : 12,
        vertical: size == StatusChipSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(size == StatusChipSize.small ? 4 : 6),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: size == StatusChipSize.small ? 12 : 14,
            color: config.textColor,
          ),
          SizedBox(width: size == StatusChipSize.small ? 4 : 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: size == StatusChipSize.small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getPriorityConfig() {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return _StatusConfig(
          label: 'High',
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade700,
          icon: Icons.priority_high,
        );
      case 'medium':
      case 'normal':
        return _StatusConfig(
          label: 'Medium',
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade800,
          icon: Icons.remove,
        );
      case 'low':
        return _StatusConfig(
          label: 'Low',
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade700,
          icon: Icons.arrow_downward,
        );
      default:
        return _StatusConfig(
          label: priority,
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.remove,
        );
    }
  }
}

/// Round badge for displaying dispute/letter round numbers
class RoundBadge extends StatelessWidget {
  const RoundBadge({
    super.key,
    required this.round,
    this.size = StatusChipSize.medium,
  });

  final int round;
  final StatusChipSize size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StatusChipSize.small ? 8 : 10,
        vertical: size == StatusChipSize.small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: _getRoundColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size == StatusChipSize.small ? 4 : 6),
        border: Border.all(
          color: _getRoundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Round $round',
        style: TextStyle(
          color: _getRoundColor(),
          fontSize: size == StatusChipSize.small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getRoundColor() {
    switch (round) {
      case 1:
        return Colors.blue.shade700;
      case 2:
        return Colors.purple.shade700;
      case 3:
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }
}

/// Bureau chip for displaying credit bureau names
class BureauChip extends StatelessWidget {
  const BureauChip({
    super.key,
    required this.bureau,
    this.size = StatusChipSize.medium,
  });

  final String bureau;
  final StatusChipSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getBureauConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StatusChipSize.small ? 8 : 10,
        vertical: size == StatusChipSize.small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(size == StatusChipSize.small ? 4 : 6),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: size == StatusChipSize.small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getBureauConfig() {
    switch (bureau.toLowerCase()) {
      case 'equifax':
        return _StatusConfig(
          label: 'Equifax',
          backgroundColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFF81C784),
          textColor: const Color(0xFF2E7D32),
          icon: Icons.shield,
        );
      case 'experian':
        return _StatusConfig(
          label: 'Experian',
          backgroundColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF64B5F6),
          textColor: const Color(0xFF1565C0),
          icon: Icons.security,
        );
      case 'transunion':
        return _StatusConfig(
          label: 'TransUnion',
          backgroundColor: const Color(0xFFF3E5F5),
          borderColor: const Color(0xFFBA68C8),
          textColor: const Color(0xFF7B1FA2),
          icon: Icons.verified_user,
        );
      default:
        return _StatusConfig(
          label: bureau,
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          icon: Icons.business,
        );
    }
  }
}
