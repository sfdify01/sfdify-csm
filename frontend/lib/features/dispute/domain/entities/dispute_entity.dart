import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

/// Dispute entity representing a consumer dispute case
class DisputeEntity extends Equatable {
  final String id;
  final String consumerId;
  final ConsumerEntity? consumer; // Optional consumer details
  final String? tradelineId;
  final String bureau;
  final String type;
  final List<String> reasonCodes;
  final String? narrative;
  final String status;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? dueAt;
  final DateTime? followedUpAt;
  final DateTime? closedAt;
  final String? outcome;
  final String? resolutionNotes;
  final DateTime? bureauResponseReceivedAt;
  final String? assignedToUserId;
  final String priority;
  final DateTime updatedAt;

  const DisputeEntity({
    required this.id,
    required this.consumerId,
    this.consumer,
    this.tradelineId,
    required this.bureau,
    required this.type,
    required this.reasonCodes,
    this.narrative,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    this.dueAt,
    this.followedUpAt,
    this.closedAt,
    this.outcome,
    this.resolutionNotes,
    this.bureauResponseReceivedAt,
    this.assignedToUserId,
    this.priority = 'medium',
    required this.updatedAt,
  });

  /// Get display name for dispute type
  String get typeDisplayName {
    switch (type) {
      case '609_request':
        return 'FCRA 609 Information Request';
      case '611_dispute':
        return 'FCRA 611 Dispute';
      case 'mov_request':
        return 'Method of Verification Request';
      case 'reinvestigation':
        return 'Reinvestigation Follow-up';
      case 'goodwill':
        return 'Goodwill Adjustment Request';
      case 'pay_for_delete':
        return 'Pay for Delete Offer';
      case 'identity_theft_block':
        return 'Identity Theft Block (605B)';
      case 'cfpb_complaint':
        return 'CFPB Complaint';
      default:
        return type;
    }
  }

  /// Get bureau display name
  String get bureauDisplayName {
    switch (bureau) {
      case 'equifax':
        return 'Equifax';
      case 'experian':
        return 'Experian';
      case 'transunion':
        return 'TransUnion';
      default:
        return bureau.toUpperCase();
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending_review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'mailed':
        return 'Mailed';
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'bureau_investigating':
        return 'Bureau Investigating';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'draft':
      case 'pending_review':
        return 'gray';
      case 'approved':
      case 'mailed':
      case 'in_transit':
        return 'blue';
      case 'delivered':
      case 'bureau_investigating':
        return 'orange';
      case 'resolved':
      case 'closed':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'gray';
    }
  }

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'blue';
      case 'low':
        return 'gray';
      default:
        return 'blue';
    }
  }

  /// Check if dispute is active
  bool get isActive =>
      status != 'closed' && status != 'cancelled' && status != 'resolved';

  /// Check if dispute is overdue
  bool get isOverdue {
    if (dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!) && isActive;
  }

  /// Check if SLA is approaching (within 5 days)
  bool get isSlaApproaching {
    if (dueAt == null) return false;
    final daysRemaining = dueAt!.difference(DateTime.now()).inDays;
    return daysRemaining <= 5 && daysRemaining >= 0 && isActive;
  }

  /// Get days remaining until due date
  int? get daysRemaining {
    if (dueAt == null) return null;
    return dueAt!.difference(DateTime.now()).inDays;
  }

  /// Check if dispute is waiting for bureau response
  bool get isWaitingForBureauResponse =>
      status == 'delivered' || status == 'bureau_investigating';

  /// Check if dispute has been submitted
  bool get isSubmitted => submittedAt != null;

  @override
  List<Object?> get props => [
        id,
        consumerId,
        tradelineId,
        bureau,
        type,
        reasonCodes,
        narrative,
        status,
        createdAt,
        submittedAt,
        dueAt,
        followedUpAt,
        closedAt,
        outcome,
        resolutionNotes,
        bureauResponseReceivedAt,
        assignedToUserId,
        priority,
        updatedAt,
      ];

  DisputeEntity copyWith({
    String? id,
    String? consumerId,
    String? tradelineId,
    String? bureau,
    String? type,
    List<String>? reasonCodes,
    String? narrative,
    String? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? dueAt,
    DateTime? followedUpAt,
    DateTime? closedAt,
    String? outcome,
    String? resolutionNotes,
    DateTime? bureauResponseReceivedAt,
    String? assignedToUserId,
    String? priority,
    DateTime? updatedAt,
  }) {
    return DisputeEntity(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      tradelineId: tradelineId ?? this.tradelineId,
      bureau: bureau ?? this.bureau,
      type: type ?? this.type,
      reasonCodes: reasonCodes ?? this.reasonCodes,
      narrative: narrative ?? this.narrative,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      dueAt: dueAt ?? this.dueAt,
      followedUpAt: followedUpAt ?? this.followedUpAt,
      closedAt: closedAt ?? this.closedAt,
      outcome: outcome ?? this.outcome,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      bureauResponseReceivedAt:
          bureauResponseReceivedAt ?? this.bureauResponseReceivedAt,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      priority: priority ?? this.priority,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
