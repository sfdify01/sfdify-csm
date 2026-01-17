import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';

enum ConsumerListStatus { initial, loading, success, failure }

class ConsumerListState extends Equatable {
  const ConsumerListState({
    this.status = ConsumerListStatus.initial,
    this.consumers = const [],
    this.searchQuery = '',
    this.selectedStatus,
    this.cursor,
    this.hasMore = false,
    this.errorMessage,
  });

  final ConsumerListStatus status;
  final List<ConsumerEntity> consumers;
  final String searchQuery;
  final String? selectedStatus;
  final String? cursor;
  final bool hasMore;
  final String? errorMessage;

  ConsumerListState copyWith({
    ConsumerListStatus? status,
    List<ConsumerEntity>? consumers,
    String? searchQuery,
    String? selectedStatus,
    String? cursor,
    bool? hasMore,
    String? errorMessage,
  }) {
    return ConsumerListState(
      status: status ?? this.status,
      consumers: consumers ?? this.consumers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      cursor: cursor,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        consumers,
        searchQuery,
        selectedStatus,
        cursor,
        hasMore,
        errorMessage,
      ];
}
