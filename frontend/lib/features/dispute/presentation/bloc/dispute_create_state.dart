import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';

enum DisputeCreateStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

class DisputeCreateState extends Equatable {
  const DisputeCreateState({
    this.status = DisputeCreateStatus.initial,
    this.consumers = const [],
    this.selectedConsumerId,
    this.savedDispute,
    this.errorMessage,
  });

  final DisputeCreateStatus status;
  final List<ConsumerEntity> consumers;
  final String? selectedConsumerId;
  final DisputeEntity? savedDispute;
  final String? errorMessage;

  ConsumerEntity? get selectedConsumer {
    if (selectedConsumerId == null) return null;
    try {
      return consumers.firstWhere((c) => c.id == selectedConsumerId);
    } catch (_) {
      return null;
    }
  }

  DisputeCreateState copyWith({
    DisputeCreateStatus? status,
    List<ConsumerEntity>? consumers,
    String? selectedConsumerId,
    DisputeEntity? savedDispute,
    String? errorMessage,
  }) {
    return DisputeCreateState(
      status: status ?? this.status,
      consumers: consumers ?? this.consumers,
      selectedConsumerId: selectedConsumerId ?? this.selectedConsumerId,
      savedDispute: savedDispute ?? this.savedDispute,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        consumers,
        selectedConsumerId,
        savedDispute,
        errorMessage,
      ];
}
