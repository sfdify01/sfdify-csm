import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

enum DisputeDetailStatus { initial, loading, success, failure }

class DisputeDetailState extends Equatable {
  const DisputeDetailState({
    this.status = DisputeDetailStatus.initial,
    this.dispute,
    this.isSubmitting = false,
    this.errorMessage,
    this.actionSuccess,
  });

  final DisputeDetailStatus status;
  final DisputeEntity? dispute;
  final bool isSubmitting;
  final String? errorMessage;
  final String? actionSuccess; // Success message for actions

  DisputeDetailState copyWith({
    DisputeDetailStatus? status,
    DisputeEntity? dispute,
    bool? isSubmitting,
    String? errorMessage,
    String? actionSuccess,
  }) {
    return DisputeDetailState(
      status: status ?? this.status,
      dispute: dispute ?? this.dispute,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dispute,
        isSubmitting,
        errorMessage,
        actionSuccess,
      ];
}
