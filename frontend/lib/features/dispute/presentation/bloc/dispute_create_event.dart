import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_state.dart';

sealed class DisputeCreateEvent extends Equatable {
  const DisputeCreateEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial data (consumers and templates)
class DisputeCreateLoadRequested extends DisputeCreateEvent {
  final String? preselectedConsumerId;

  const DisputeCreateLoadRequested({this.preselectedConsumerId});

  @override
  List<Object?> get props => [preselectedConsumerId];
}

/// Consumer selection changed
class DisputeCreateConsumerChanged extends DisputeCreateEvent {
  final String? consumerId;

  const DisputeCreateConsumerChanged(this.consumerId);

  @override
  List<Object?> get props => [consumerId];
}

/// Toggle tradeline selection
class DisputeCreateTradelineToggled extends DisputeCreateEvent {
  final String tradelineId;

  const DisputeCreateTradelineToggled(this.tradelineId);

  @override
  List<Object?> get props => [tradelineId];
}

/// Select all tradelines from a specific bureau
class DisputeCreateSelectAllTradelines extends DisputeCreateEvent {
  final String? bureau;
  final bool selected;

  const DisputeCreateSelectAllTradelines({this.bureau, required this.selected});

  @override
  List<Object?> get props => [bureau, selected];
}

/// Template selection changed
class DisputeCreateTemplateChanged extends DisputeCreateEvent {
  final String? templateId;

  const DisputeCreateTemplateChanged(this.templateId);

  @override
  List<Object?> get props => [templateId];
}

/// Toggle bureau selection
class DisputeCreateBureauToggled extends DisputeCreateEvent {
  final String bureau;

  const DisputeCreateBureauToggled(this.bureau);

  @override
  List<Object?> get props => [bureau];
}

/// Change recipient type
class DisputeCreateRecipientTypeChanged extends DisputeCreateEvent {
  final RecipientType recipientType;

  const DisputeCreateRecipientTypeChanged(this.recipientType);

  @override
  List<Object?> get props => [recipientType];
}

/// Update creditor info
class DisputeCreateCreditorChanged extends DisputeCreateEvent {
  final String? name;
  final String? address;

  const DisputeCreateCreditorChanged({this.name, this.address});

  @override
  List<Object?> get props => [name, address];
}

/// Navigate to step
class DisputeCreateStepChanged extends DisputeCreateEvent {
  final int step;

  const DisputeCreateStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}

/// Submit the dispute
class DisputeCreateSubmitted extends DisputeCreateEvent {
  final String consumerId;
  final String bureau;
  final String type;
  final List<String> reasonCodes;
  final String? narrative;
  final String priority;
  final String? tradelineId;
  final List<String>? tradelineIds;
  final String? templateId;
  final RecipientType recipientType;
  final String? creditorName;
  final String? creditorAddress;

  const DisputeCreateSubmitted({
    required this.consumerId,
    required this.bureau,
    required this.type,
    required this.reasonCodes,
    this.narrative,
    required this.priority,
    this.tradelineId,
    this.tradelineIds,
    this.templateId,
    this.recipientType = RecipientType.bureau,
    this.creditorName,
    this.creditorAddress,
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
        tradelineIds,
        templateId,
        recipientType,
        creditorName,
        creditorAddress,
      ];
}
