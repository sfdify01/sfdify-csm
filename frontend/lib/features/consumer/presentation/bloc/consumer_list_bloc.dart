import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/consumer/domain/usecases/get_consumers.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_list_event.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_list_state.dart';
import 'package:stream_transform/stream_transform.dart';

const _debounceDuration = Duration(milliseconds: 300);

EventTransformer<E> debounceDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.debounce(duration), mapper);
  };
}

@injectable
class ConsumerListBloc extends Bloc<ConsumerListEvent, ConsumerListState> {
  ConsumerListBloc(this._getConsumers) : super(const ConsumerListState()) {
    on<ConsumerListLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<ConsumerListRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<ConsumerListSearchChanged>(
      _onSearchChanged,
      transformer: debounceDroppable(_debounceDuration),
    );
    on<ConsumerListLoadMore>(_onLoadMore);
    on<ConsumerListStatusFilterChanged>(_onStatusFilterChanged);
  }

  final GetConsumers _getConsumers;

  Future<void> _onLoadRequested(
    ConsumerListLoadRequested event,
    Emitter<ConsumerListState> emit,
  ) async {
    emit(state.copyWith(status: ConsumerListStatus.loading));

    final result = await _getConsumers(
      limit: 20,
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ConsumerListStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumers) {
        emit(state.copyWith(
          status: ConsumerListStatus.success,
          consumers: consumers,
          hasMore: consumers.length >= 20,
        ));
      },
    );
  }

  Future<void> _onRefreshRequested(
    ConsumerListRefreshRequested event,
    Emitter<ConsumerListState> emit,
  ) async {
    final result = await _getConsumers(
      limit: 20,
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (consumers) {
        emit(state.copyWith(
          status: ConsumerListStatus.success,
          consumers: consumers,
          hasMore: consumers.length >= 20,
          cursor: null,
        ));
      },
    );
  }

  Future<void> _onSearchChanged(
    ConsumerListSearchChanged event,
    Emitter<ConsumerListState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      cursor: null,
    ));
    add(const ConsumerListLoadRequested());
  }

  Future<void> _onLoadMore(
    ConsumerListLoadMore event,
    Emitter<ConsumerListState> emit,
  ) async {
    if (!state.hasMore || state.status == ConsumerListStatus.loading) {
      return;
    }

    final result = await _getConsumers(
      limit: 20,
      cursor: state.cursor,
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (consumers) {
        emit(state.copyWith(
          consumers: [...state.consumers, ...consumers],
          hasMore: consumers.length >= 20,
        ));
      },
    );
  }

  Future<void> _onStatusFilterChanged(
    ConsumerListStatusFilterChanged event,
    Emitter<ConsumerListState> emit,
  ) async {
    emit(state.copyWith(
      selectedStatus: event.status,
      cursor: null,
    ));
    add(const ConsumerListLoadRequested());
  }
}
