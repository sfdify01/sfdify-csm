import 'package:equatable/equatable.dart';

/// Credit report entity representing a bureau credit report snapshot
class CreditReportEntity extends Equatable {
  final String id;
  final String consumerId;
  final String bureau; // 'equifax', 'experian', 'transunion'
  final DateTime pulledAt;
  final String hash; // SHA-256 hash for change detection
  final int? score;
  final String status; // 'current', 'superseded', 'failed'
  final String? smartCreditReportId;
  final DateTime createdAt;

  const CreditReportEntity({
    required this.id,
    required this.consumerId,
    required this.bureau,
    required this.pulledAt,
    required this.hash,
    this.score,
    required this.status,
    this.smartCreditReportId,
    required this.createdAt,
  });

  /// Check if report is current
  bool get isCurrent => status == 'current';

  /// Check if report is superseded
  bool get isSuperseded => status == 'superseded';

  /// Check if report pull failed
  bool get isFailed => status == 'failed';

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

  /// Get score color indicator (red, yellow, green)
  String get scoreColorIndicator {
    if (score == null) return 'gray';
    if (score! >= 700) return 'green';
    if (score! >= 600) return 'yellow';
    return 'red';
  }

  /// Get score category
  String get scoreCategory {
    if (score == null) return 'Unknown';
    if (score! >= 800) return 'Exceptional';
    if (score! >= 740) return 'Very Good';
    if (score! >= 670) return 'Good';
    if (score! >= 580) return 'Fair';
    return 'Poor';
  }

  /// Get days since pulled
  int get daysSincePulled {
    return DateTime.now().difference(pulledAt).inDays;
  }

  /// Check if report needs refresh (older than 30 days)
  bool get needsRefresh => daysSincePulled > 30;

  @override
  List<Object?> get props => [
        id,
        consumerId,
        bureau,
        pulledAt,
        hash,
        score,
        status,
        smartCreditReportId,
        createdAt,
      ];

  CreditReportEntity copyWith({
    String? id,
    String? consumerId,
    String? bureau,
    DateTime? pulledAt,
    String? hash,
    int? score,
    String? status,
    String? smartCreditReportId,
    DateTime? createdAt,
  }) {
    return CreditReportEntity(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      bureau: bureau ?? this.bureau,
      pulledAt: pulledAt ?? this.pulledAt,
      hash: hash ?? this.hash,
      score: score ?? this.score,
      status: status ?? this.status,
      smartCreditReportId: smartCreditReportId ?? this.smartCreditReportId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
