import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

enum ConsumerDetailStatus { initial, loading, success, failure }

class ConsumerDetailState extends Equatable {
  const ConsumerDetailState({
    this.status = ConsumerDetailStatus.initial,
    this.consumer,
    this.disputes = const [],
    this.isSmartCreditConnected = false,
    this.creditScore,
    this.errorMessage,
  });

  final ConsumerDetailStatus status;
  final ConsumerEntity? consumer;
  final List<DisputeEntity> disputes;
  final bool isSmartCreditConnected;
  final int? creditScore;
  final String? errorMessage;

  ConsumerDetailState copyWith({
    ConsumerDetailStatus? status,
    ConsumerEntity? consumer,
    List<DisputeEntity>? disputes,
    bool? isSmartCreditConnected,
    int? creditScore,
    String? errorMessage,
  }) {
    return ConsumerDetailState(
      status: status ?? this.status,
      consumer: consumer ?? this.consumer,
      disputes: disputes ?? this.disputes,
      isSmartCreditConnected: isSmartCreditConnected ?? this.isSmartCreditConnected,
      creditScore: creditScore ?? this.creditScore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        consumer,
        disputes,
        isSmartCreditConnected,
        creditScore,
        errorMessage,
      ];
}
