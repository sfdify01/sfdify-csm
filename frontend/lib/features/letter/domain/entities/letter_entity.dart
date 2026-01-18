import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/shared/domain/entities/address_entity.dart';

/// Letter entity representing a generated and mailed dispute letter
class LetterEntity extends Equatable {
  final String id;
  final String disputeId;
  final String type;
  final String? templateId;
  final int renderVersion;
  final String? contentHtml;
  final String? contentMarkdown;
  final String? pdfUrl;
  final String? pdfChecksum;
  final String? lobId;
  final String? lobUrl;
  final String mailType;
  final String? trackingCode;
  final String? trackingUrl;
  final DateTime? expectedDeliveryDate;
  final AddressEntity recipientAddress;
  final AddressEntity returnAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final DateTime? sentAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? returnedAt;
  final double? cost;
  final DateTime updatedAt;

  const LetterEntity({
    required this.id,
    required this.disputeId,
    required this.type,
    this.templateId,
    required this.renderVersion,
    this.contentHtml,
    this.contentMarkdown,
    this.pdfUrl,
    this.pdfChecksum,
    this.lobId,
    this.lobUrl,
    required this.mailType,
    this.trackingCode,
    this.trackingUrl,
    this.expectedDeliveryDate,
    required this.recipientAddress,
    required this.returnAddress,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedByUserId,
    this.sentAt,
    this.inTransitAt,
    this.deliveredAt,
    this.returnedAt,
    this.cost,
    required this.updatedAt,
  });

  /// Get letter type display name
  String get typeDisplayName {
    switch (type) {
      case '609_request':
        return 'FCRA 609 Information Request';
      case '611_dispute':
        return 'FCRA 611 Dispute';
      case 'mov_request':
        return 'Method of Verification';
      case 'reinvestigation':
        return 'Reinvestigation Follow-up';
      case 'goodwill':
        return 'Goodwill Adjustment';
      case 'pay_for_delete':
        return 'Pay for Delete';
      case 'identity_theft_block':
        return 'Identity Theft Block';
      case 'cfpb_complaint':
        return 'CFPB Complaint';
      default:
        return type;
    }
  }

  /// Get mail type display name
  String get mailTypeDisplayName {
    switch (mailType) {
      case 'usps_first_class':
        return 'First Class Mail';
      case 'usps_certified':
        return 'Certified Mail';
      case 'usps_certified_return_receipt':
        return 'Certified Mail with Return Receipt';
      default:
        return mailType;
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending_approval':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rendering':
        return 'Rendering';
      case 'ready':
        return 'Ready to Send';
      case 'queued':
        return 'Queued';
      case 'sent':
        return 'Sent';
      case 'in_transit':
        return 'In Transit';
      case 'in_local_area':
        return 'In Local Area';
      case 'processed_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'returned_to_sender':
        return 'Returned to Sender';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'draft':
      case 'pending_approval':
        return 'gray';
      case 'approved':
      case 'rendering':
      case 'ready':
      case 'queued':
        return 'blue';
      case 'sent':
      case 'in_transit':
      case 'in_local_area':
      case 'processed_for_delivery':
        return 'orange';
      case 'delivered':
        return 'green';
      case 'returned_to_sender':
      case 'failed':
        return 'red';
      default:
        return 'gray';
    }
  }

  /// Check if letter is delivered
  bool get isDelivered => status == 'delivered' && deliveredAt != null;

  /// Check if letter is in transit
  bool get isInTransit => [
        'sent',
        'in_transit',
        'in_local_area',
        'processed_for_delivery',
      ].contains(status);

  /// Check if letter is returned
  bool get isReturned => status == 'returned_to_sender';

  /// Check if letter is pending approval
  bool get isPendingApproval => status == 'pending_approval';

  /// Check if letter is approved
  bool get isApproved => approvedAt != null && approvedByUserId != null;

  /// Check if letter has been sent
  bool get isSent => sentAt != null;

  /// Check if letter is certified mail
  bool get isCertified => mailType.contains('certified');

  /// Check if letter has tracking
  bool get hasTracking => trackingCode != null && trackingUrl != null;

  /// Get days since sent
  int? get daysSinceSent {
    if (sentAt == null) return null;
    return DateTime.now().difference(sentAt!).inDays;
  }

  /// Get estimated days until delivery
  int? get estimatedDaysUntilDelivery {
    if (expectedDeliveryDate == null) return null;
    return expectedDeliveryDate!.difference(DateTime.now()).inDays;
  }

  /// Get formatted cost
  String get formattedCost {
    if (cost == null) return 'N/A';
    return '\$${cost!.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        id,
        disputeId,
        type,
        templateId,
        renderVersion,
        contentHtml,
        contentMarkdown,
        pdfUrl,
        pdfChecksum,
        lobId,
        lobUrl,
        mailType,
        trackingCode,
        trackingUrl,
        expectedDeliveryDate,
        recipientAddress,
        returnAddress,
        status,
        createdAt,
        approvedAt,
        approvedByUserId,
        sentAt,
        inTransitAt,
        deliveredAt,
        returnedAt,
        cost,
        updatedAt,
      ];

  LetterEntity copyWith({
    String? id,
    String? disputeId,
    String? type,
    String? templateId,
    int? renderVersion,
    String? contentHtml,
    String? contentMarkdown,
    String? pdfUrl,
    String? pdfChecksum,
    String? lobId,
    String? lobUrl,
    String? mailType,
    String? trackingCode,
    String? trackingUrl,
    DateTime? expectedDeliveryDate,
    AddressEntity? recipientAddress,
    AddressEntity? returnAddress,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedByUserId,
    DateTime? sentAt,
    DateTime? inTransitAt,
    DateTime? deliveredAt,
    DateTime? returnedAt,
    double? cost,
    DateTime? updatedAt,
  }) {
    return LetterEntity(
      id: id ?? this.id,
      disputeId: disputeId ?? this.disputeId,
      type: type ?? this.type,
      templateId: templateId ?? this.templateId,
      renderVersion: renderVersion ?? this.renderVersion,
      contentHtml: contentHtml ?? this.contentHtml,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfChecksum: pdfChecksum ?? this.pdfChecksum,
      lobId: lobId ?? this.lobId,
      lobUrl: lobUrl ?? this.lobUrl,
      mailType: mailType ?? this.mailType,
      trackingCode: trackingCode ?? this.trackingCode,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      returnAddress: returnAddress ?? this.returnAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      sentAt: sentAt ?? this.sentAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      returnedAt: returnedAt ?? this.returnedAt,
      cost: cost ?? this.cost,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
