import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/consumer/domain/usecases/get_consumers.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_event.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_state.dart';

@injectable
class DisputeCreateBloc extends Bloc<DisputeCreateEvent, DisputeCreateState> {
  DisputeCreateBloc(this._getConsumers, this._repository)
      : super(const DisputeCreateState()) {
    on<DisputeCreateLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<DisputeCreateConsumerChanged>(_onConsumerChanged);
    on<DisputeCreateSubmitted>(
      _onSubmitted,
      transformer: droppable(),
    );
  }

  final GetConsumers _getConsumers;
  final DisputeRepository _repository;

  Future<void> _onLoadRequested(
    DisputeCreateLoadRequested event,
    Emitter<DisputeCreateState> emit,
  ) async {
    emit(state.copyWith(status: DisputeCreateStatus.loading));

    final result = await _getConsumers(limit: 100);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeCreateStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumers) {
        emit(state.copyWith(
          status: DisputeCreateStatus.ready,
          consumers: consumers,
          selectedConsumerId: event.preselectedConsumerId,
        ));
      },
    );
  }

  void _onConsumerChanged(
    DisputeCreateConsumerChanged event,
    Emitter<DisputeCreateState> emit,
  ) {
    emit(state.copyWith(selectedConsumerId: event.consumerId));
  }

  Future<void> _onSubmitted(
    DisputeCreateSubmitted event,
    Emitter<DisputeCreateState> emit,
  ) async {
    emit(state.copyWith(status: DisputeCreateStatus.submitting));

    final data = {
      'consumerId': event.consumerId,
      'bureau': event.bureau,
      'type': event.type,
      'reasonCodes': event.reasonCodes,
      if (event.narrative != null && event.narrative!.isNotEmpty)
        'narrative': event.narrative,
      'priority': event.priority,
      if (event.tradelineId != null) 'tradelineId': event.tradelineId,
    };

    final result = await _repository.createDispute(data);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeCreateStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          status: DisputeCreateStatus.success,
          savedDispute: dispute,
        ));
      },
    );
  }
}
