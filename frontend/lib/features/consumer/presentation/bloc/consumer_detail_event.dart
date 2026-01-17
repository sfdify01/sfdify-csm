import 'package:equatable/equatable.dart';

sealed class ConsumerDetailEvent extends Equatable {
  const ConsumerDetailEvent();

  @override
  List<Object?> get props => [];
}

class ConsumerDetailLoadRequested extends ConsumerDetailEvent {
  final String consumerId;

  const ConsumerDetailLoadRequested(this.consumerId);

  @override
  List<Object?> get props => [consumerId];
}

class ConsumerDetailRefreshRequested extends ConsumerDetailEvent {
  const ConsumerDetailRefreshRequested();
}

class ConsumerDetailSmartCreditConnectRequested extends ConsumerDetailEvent {
  const ConsumerDetailSmartCreditConnectRequested();
}

class ConsumerDetailCreditReportRefreshRequested extends ConsumerDetailEvent {
  const ConsumerDetailCreditReportRefreshRequested();
}
