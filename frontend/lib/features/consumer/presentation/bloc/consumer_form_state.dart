import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

enum ConsumerFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

class ConsumerFormState extends Equatable {
  const ConsumerFormState({
    this.status = ConsumerFormStatus.initial,
    this.isEditMode = false,
    this.consumer,
    this.savedConsumer,
    this.errorMessage,
  });

  final ConsumerFormStatus status;
  final bool isEditMode;
  final ConsumerEntity? consumer; // existing consumer for edit mode
  final ConsumerEntity? savedConsumer; // newly saved consumer
  final String? errorMessage;

  ConsumerFormState copyWith({
    ConsumerFormStatus? status,
    bool? isEditMode,
    ConsumerEntity? consumer,
    ConsumerEntity? savedConsumer,
    String? errorMessage,
  }) {
    return ConsumerFormState(
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      consumer: consumer ?? this.consumer,
      savedConsumer: savedConsumer ?? this.savedConsumer,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEditMode,
        consumer,
        savedConsumer,
        errorMessage,
      ];
}
