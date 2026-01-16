import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

enum DisputeOverviewStatus { initial, loading, success, failure }

class DisputeOverviewState extends Equatable {
  const DisputeOverviewState({
    this.status = DisputeOverviewStatus.initial,
    this.metrics,
    this.disputes = const [],
    this.selectedBureau,
    this.cursor,
    this.hasMore = false,
    this.errorMessage,
  });

  final DisputeOverviewStatus status;
  final DisputeMetricsEntity? metrics;
  final List<DisputeEntity> disputes;
  final String? selectedBureau;
  final String? cursor;
  final bool hasMore;
  final String? errorMessage;

  DisputeOverviewState copyWith({
    DisputeOverviewStatus? status,
    DisputeMetricsEntity? metrics,
    List<DisputeEntity>? disputes,
    String? selectedBureau,
    String? cursor,
    bool? hasMore,
    String? errorMessage,
  }) {
    return DisputeOverviewState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      disputes: disputes ?? this.disputes,
      selectedBureau: selectedBureau ?? this.selectedBureau,
      cursor: cursor,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        metrics,
        disputes,
        selectedBureau,
        cursor,
        hasMore,
        errorMessage,
      ];
}
