import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:ustaxx_csm/features/dispute/domain/usecases/get_dispute.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_detail_event.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_detail_state.dart';

@injectable
class DisputeDetailBloc extends Bloc<DisputeDetailEvent, DisputeDetailState> {
  DisputeDetailBloc(this._getDispute, this._repository)
      : super(const DisputeDetailState()) {
    on<DisputeDetailLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<DisputeDetailRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<DisputeDetailSubmitRequested>(_onSubmitRequested);
    on<DisputeDetailApproveRequested>(_onApproveRequested);
    on<DisputeDetailCloseRequested>(_onCloseRequested);
    on<DisputeDetailGenerateLetterRequested>(_onGenerateLetterRequested);
  }

  final GetDispute _getDispute;
  final DisputeRepository _repository;
  String? _currentDisputeId;

  Future<void> _onLoadRequested(
    DisputeDetailLoadRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    _currentDisputeId = event.disputeId;
    emit(state.copyWith(status: DisputeDetailStatus.loading));

    final result = await _getDispute(event.disputeId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeDetailStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          status: DisputeDetailStatus.success,
          dispute: dispute,
        ));
      },
    );
  }

  Future<void> _onRefreshRequested(
    DisputeDetailRefreshRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    if (_currentDisputeId == null) return;

    final result = await _getDispute(_currentDisputeId!);

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (dispute) {
        emit(state.copyWith(
          status: DisputeDetailStatus.success,
          dispute: dispute,
        ));
      },
    );
  }

  Future<void> _onSubmitRequested(
    DisputeDetailSubmitRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    if (_currentDisputeId == null) return;

    emit(state.copyWith(isSubmitting: true));

    final result = await _repository.submitDispute(_currentDisputeId!);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          isSubmitting: false,
          dispute: dispute,
          actionSuccess: 'Dispute submitted for review',
        ));
      },
    );
  }

  Future<void> _onApproveRequested(
    DisputeDetailApproveRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    if (_currentDisputeId == null) return;

    emit(state.copyWith(isSubmitting: true));

    final result = await _repository.approveDispute(_currentDisputeId!);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          isSubmitting: false,
          dispute: dispute,
          actionSuccess: 'Dispute approved',
        ));
      },
    );
  }

  Future<void> _onCloseRequested(
    DisputeDetailCloseRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    if (_currentDisputeId == null) return;

    emit(state.copyWith(isSubmitting: true));

    final result = await _repository.closeDispute(
      _currentDisputeId!,
      event.resolution,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          isSubmitting: false,
          dispute: dispute,
          actionSuccess: 'Dispute closed',
        ));
      },
    );
  }

  Future<void> _onGenerateLetterRequested(
    DisputeDetailGenerateLetterRequested event,
    Emitter<DisputeDetailState> emit,
  ) async {
    // This will navigate to the letter generation page
    // The actual navigation is handled in the UI
  }
}
