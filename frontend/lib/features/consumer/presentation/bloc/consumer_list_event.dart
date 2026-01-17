import 'package:equatable/equatable.dart';

sealed class ConsumerListEvent extends Equatable {
  const ConsumerListEvent();

  @override
  List<Object?> get props => [];
}

class ConsumerListLoadRequested extends ConsumerListEvent {
  const ConsumerListLoadRequested();
}

class ConsumerListRefreshRequested extends ConsumerListEvent {
  const ConsumerListRefreshRequested();
}

class ConsumerListSearchChanged extends ConsumerListEvent {
  final String query;

  const ConsumerListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ConsumerListLoadMore extends ConsumerListEvent {
  const ConsumerListLoadMore();
}

class ConsumerListStatusFilterChanged extends ConsumerListEvent {
  final String? status; // null for "All"

  const ConsumerListStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}
