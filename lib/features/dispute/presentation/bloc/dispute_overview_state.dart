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
    this.currentPage = 1,
    this.totalPages = 1,
    this.errorMessage,
  });

  final DisputeOverviewStatus status;
  final DisputeMetricsEntity? metrics;
  final List<DisputeEntity> disputes;
  final String? selectedBureau;
  final int currentPage;
  final int totalPages;
  final String? errorMessage;

  DisputeOverviewState copyWith({
    DisputeOverviewStatus? status,
    DisputeMetricsEntity? metrics,
    List<DisputeEntity>? disputes,
    String? selectedBureau,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
  }) {
    return DisputeOverviewState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      disputes: disputes ?? this.disputes,
      selectedBureau: selectedBureau ?? this.selectedBureau,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        metrics,
        disputes,
        selectedBureau,
        currentPage,
        totalPages,
        errorMessage,
      ];
}
