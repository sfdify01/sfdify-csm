import 'package:flutter/material.dart';

class LetterStatusChip extends StatelessWidget {
  const LetterStatusChip({
    super.key,
    required this.status,
    this.size = LetterStatusChipSize.medium,
  });

  final String status;
  final LetterStatusChipSize size;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusInfo(status);

    final padding = switch (size) {
      LetterStatusChipSize.small =>
        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      LetterStatusChipSize.medium =>
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      LetterStatusChipSize.large =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    };

    final fontSize = switch (size) {
      LetterStatusChipSize.small => 10.0,
      LetterStatusChipSize.medium => 12.0,
      LetterStatusChipSize.large => 14.0,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getStatusInfo(String status) {
    return switch (status) {
      'draft' => (Colors.grey, 'Draft'),
      'pending_approval' => (Colors.amber, 'Pending Approval'),
      'approved' => (Colors.blue, 'Approved'),
      'rendering' => (Colors.blue, 'Rendering'),
      'ready' => (Colors.indigo, 'Ready'),
      'queued' => (Colors.indigo, 'Queued'),
      'sent' => (Colors.orange, 'Sent'),
      'in_transit' => (Colors.orange, 'In Transit'),
      'in_local_area' => (Colors.orange, 'In Local Area'),
      'processed_for_delivery' => (Colors.orange, 'Out for Delivery'),
      'delivered' => (Colors.green, 'Delivered'),
      'returned_to_sender' => (Colors.red, 'Returned'),
      'failed' => (Colors.red, 'Failed'),
      _ => (Colors.grey, status),
    };
  }
}

enum LetterStatusChipSize { small, medium, large }
