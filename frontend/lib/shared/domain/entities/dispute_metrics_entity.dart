import 'package:equatable/equatable.dart';

/// Dispute metrics entity for dashboard overview
class DisputeMetricsEntity extends Equatable {
  final int totalDisputes;
  final double percentageChange;
  final int pendingApproval;
  final int inTransitViaLob;
  final int slaBreaches;
  final int slaBreachesToday;

  const DisputeMetricsEntity({
    required this.totalDisputes,
    required this.percentageChange,
    required this.pendingApproval,
    required this.inTransitViaLob,
    required this.slaBreaches,
    required this.slaBreachesToday,
  });

  /// Format percentage change for display
  String get formattedPercentageChange {
    final sign = percentageChange >= 0 ? '+' : '';
    return '$sign${percentageChange.toStringAsFixed(1)}%';
  }

  /// Format SLA breaches today for display
  String get formattedSlaBreachesToday {
    return '+$slaBreachesToday today';
  }

  @override
  List<Object?> get props => [
        totalDisputes,
        percentageChange,
        pendingApproval,
        inTransitViaLob,
        slaBreaches,
        slaBreachesToday,
      ];

  DisputeMetricsEntity copyWith({
    int? totalDisputes,
    double? percentageChange,
    int? pendingApproval,
    int? inTransitViaLob,
    int? slaBreaches,
    int? slaBreachesToday,
  }) {
    return DisputeMetricsEntity(
      totalDisputes: totalDisputes ?? this.totalDisputes,
      percentageChange: percentageChange ?? this.percentageChange,
      pendingApproval: pendingApproval ?? this.pendingApproval,
      inTransitViaLob: inTransitViaLob ?? this.inTransitViaLob,
      slaBreaches: slaBreaches ?? this.slaBreaches,
      slaBreachesToday: slaBreachesToday ?? this.slaBreachesToday,
    );
  }
}
