import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';
import 'package:ustaxx_csm/features/letter/domain/repositories/letter_repository.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_list_event.dart';
import 'package:ustaxx_csm/features/letter/presentation/bloc/letter_list_state.dart';
import 'package:stream_transform/stream_transform.dart';

EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

@injectable
class LetterListBloc extends Bloc<LetterListEvent, LetterListState> {
  LetterListBloc(this._letterRepository) : super(const LetterListState()) {
    on<LetterListLoadRequested>(_onLoadRequested, transformer: droppable());
    on<LetterListRefreshRequested>(_onRefreshRequested, transformer: droppable());
    on<LetterListLoadMoreRequested>(_onLoadMoreRequested, transformer: droppable());
    on<LetterListStatusFilterChanged>(_onStatusFilterChanged);
    on<LetterListSearchChanged>(
      _onSearchChanged,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
  }

  final LetterRepository _letterRepository;

  Future<void> _onLoadRequested(
    LetterListLoadRequested event,
    Emitter<LetterListState> emit,
  ) async {
    emit(state.copyWith(status: LetterListStatus.loading));

    final result = await _letterRepository.getLetters(
      limit: 50,
      status: state.statusFilter,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: LetterListStatus.failure,
        errorMessage: failure.message,
      )),
      (letters) {
        final filtered = _filterLetters(letters, state.searchQuery);
        emit(state.copyWith(
          status: LetterListStatus.success,
          letters: letters,
          filteredLetters: filtered,
          hasMore: letters.length >= 50,
          cursor: letters.isNotEmpty ? letters.last.id : null,
        ));
      },
    );
  }

  Future<void> _onRefreshRequested(
    LetterListRefreshRequested event,
    Emitter<LetterListState> emit,
  ) async {
    final result = await _letterRepository.getLetters(
      limit: 50,
      status: state.statusFilter,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: LetterListStatus.failure,
        errorMessage: failure.message,
      )),
      (letters) {
        final filtered = _filterLetters(letters, state.searchQuery);
        emit(state.copyWith(
          status: LetterListStatus.success,
          letters: letters,
          filteredLetters: filtered,
          hasMore: letters.length >= 50,
          cursor: letters.isNotEmpty ? letters.last.id : null,
        ));
      },
    );
  }

  Future<void> _onLoadMoreRequested(
    LetterListLoadMoreRequested event,
    Emitter<LetterListState> emit,
  ) async {
    if (!state.hasMore || state.cursor == null) return;

    final result = await _letterRepository.getLetters(
      limit: 50,
      cursor: state.cursor,
      status: state.statusFilter,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (newLetters) {
        final allLetters = [...state.letters, ...newLetters];
        final filtered = _filterLetters(allLetters, state.searchQuery);
        emit(state.copyWith(
          letters: allLetters,
          filteredLetters: filtered,
          hasMore: newLetters.length >= 50,
          cursor: newLetters.isNotEmpty ? newLetters.last.id : null,
        ));
      },
    );
  }

  void _onStatusFilterChanged(
    LetterListStatusFilterChanged event,
    Emitter<LetterListState> emit,
  ) {
    emit(state.copyWith(statusFilter: event.status));
    add(const LetterListRefreshRequested());
  }

  void _onSearchChanged(
    LetterListSearchChanged event,
    Emitter<LetterListState> emit,
  ) {
    final filtered = _filterLetters(state.letters, event.query);
    emit(state.copyWith(
      searchQuery: event.query,
      filteredLetters: filtered,
    ));
  }

  List<LetterEntity> _filterLetters(List<LetterEntity> letters, String query) {
    if (query.isEmpty) return letters;
    final lowerQuery = query.toLowerCase();
    return letters.where((letter) {
      return letter.typeDisplayName.toLowerCase().contains(lowerQuery) ||
          letter.statusDisplayName.toLowerCase().contains(lowerQuery) ||
          letter.id.toLowerCase().contains(lowerQuery) ||
          (letter.trackingCode?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
