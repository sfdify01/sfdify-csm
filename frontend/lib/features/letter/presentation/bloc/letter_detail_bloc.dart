import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/letter/domain/repositories/letter_repository.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_detail_event.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_detail_state.dart';

@injectable
class LetterDetailBloc extends Bloc<LetterDetailEvent, LetterDetailState> {
  LetterDetailBloc(this._letterRepository) : super(const LetterDetailState()) {
    on<LetterDetailLoadRequested>(_onLoadRequested, transformer: droppable());
    on<LetterDetailRefreshRequested>(_onRefreshRequested, transformer: droppable());
    on<LetterDetailApproveRequested>(_onApproveRequested, transformer: droppable());
    on<LetterDetailSendRequested>(_onSendRequested, transformer: droppable());
  }

  final LetterRepository _letterRepository;
  String? _letterId;

  Future<void> _onLoadRequested(
    LetterDetailLoadRequested event,
    Emitter<LetterDetailState> emit,
  ) async {
    _letterId = event.letterId;
    emit(state.copyWith(status: LetterDetailStatus.loading));

    final result = await _letterRepository.getLetter(event.letterId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LetterDetailStatus.failure,
        errorMessage: failure.message,
      )),
      (letter) => emit(state.copyWith(
        status: LetterDetailStatus.success,
        letter: letter,
      )),
    );
  }

  Future<void> _onRefreshRequested(
    LetterDetailRefreshRequested event,
    Emitter<LetterDetailState> emit,
  ) async {
    if (_letterId == null) return;

    final result = await _letterRepository.getLetter(_letterId!);

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (letter) => emit(state.copyWith(
        letter: letter,
      )),
    );
  }

  Future<void> _onApproveRequested(
    LetterDetailApproveRequested event,
    Emitter<LetterDetailState> emit,
  ) async {
    if (_letterId == null || !state.canApprove) return;

    emit(state.copyWith(actionStatus: LetterActionStatus.processing));

    final result = await _letterRepository.approveLetter(_letterId!);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: LetterActionStatus.failure,
        errorMessage: failure.message,
      )),
      (letter) => emit(state.copyWith(
        actionStatus: LetterActionStatus.success,
        letter: letter,
      )),
    );
  }

  Future<void> _onSendRequested(
    LetterDetailSendRequested event,
    Emitter<LetterDetailState> emit,
  ) async {
    if (_letterId == null || !state.canSend) return;

    emit(state.copyWith(actionStatus: LetterActionStatus.processing));

    final result = await _letterRepository.sendLetter(_letterId!);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: LetterActionStatus.failure,
        errorMessage: failure.message,
      )),
      (letter) => emit(state.copyWith(
        actionStatus: LetterActionStatus.success,
        letter: letter,
      )),
    );
  }
}
