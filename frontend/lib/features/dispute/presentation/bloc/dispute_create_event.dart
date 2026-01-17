import 'package:equatable/equatable.dart';

sealed class DisputeCreateEvent extends Equatable {
  const DisputeCreateEvent();

  @override
  List<Object?> get props => [];
}

class DisputeCreateLoadRequested extends DisputeCreateEvent {
  final String? preselectedConsumerId;

  const DisputeCreateLoadRequested({this.preselectedConsumerId});

  @override
  List<Object?> get props => [preselectedConsumerId];
}

class DisputeCreateConsumerChanged extends DisputeCreateEvent {
  final String? consumerId;

  const DisputeCreateConsumerChanged(this.consumerId);

  @override
  List<Object?> get props => [consumerId];
}

class DisputeCreateSubmitted extends DisputeCreateEvent {
  final String consumerId;
  final String bureau;
  final String type;
  final List<String> reasonCodes;
  final String? narrative;
  final String priority;
  final String? tradelineId;

  const DisputeCreateSubmitted({
    required this.consumerId,
    required this.bureau,
    required this.type,
    required this.reasonCodes,
    this.narrative,
    required this.priority,
    this.tradelineId,
  });

  @override
  List<Object?> get props => [
        consumerId,
        bureau,
        type,
        reasonCodes,
        narrative,
        priority,
        tradelineId,
      ];
}
