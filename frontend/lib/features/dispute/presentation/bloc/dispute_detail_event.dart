import 'package:equatable/equatable.dart';

sealed class DisputeDetailEvent extends Equatable {
  const DisputeDetailEvent();

  @override
  List<Object?> get props => [];
}

class DisputeDetailLoadRequested extends DisputeDetailEvent {
  final String disputeId;

  const DisputeDetailLoadRequested(this.disputeId);

  @override
  List<Object?> get props => [disputeId];
}

class DisputeDetailRefreshRequested extends DisputeDetailEvent {
  const DisputeDetailRefreshRequested();
}

class DisputeDetailSubmitRequested extends DisputeDetailEvent {
  const DisputeDetailSubmitRequested();
}

class DisputeDetailApproveRequested extends DisputeDetailEvent {
  const DisputeDetailApproveRequested();
}

class DisputeDetailCloseRequested extends DisputeDetailEvent {
  final String resolution;

  const DisputeDetailCloseRequested(this.resolution);

  @override
  List<Object?> get props => [resolution];
}

class DisputeDetailGenerateLetterRequested extends DisputeDetailEvent {
  const DisputeDetailGenerateLetterRequested();
}
