import 'package:equatable/equatable.dart';

sealed class DisputeOverviewEvent extends Equatable {
  const DisputeOverviewEvent();

  @override
  List<Object?> get props => [];
}

class DisputeOverviewLoadRequested extends DisputeOverviewEvent {
  const DisputeOverviewLoadRequested();
}

class DisputeOverviewRefreshRequested extends DisputeOverviewEvent {
  const DisputeOverviewRefreshRequested();
}

class DisputeOverviewBureauFilterChanged extends DisputeOverviewEvent {
  final String? bureau; // null for "All Bureaus"

  const DisputeOverviewBureauFilterChanged(this.bureau);

  @override
  List<Object?> get props => [bureau];
}

class DisputeOverviewPageChanged extends DisputeOverviewEvent {
  final int page;

  const DisputeOverviewPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}
