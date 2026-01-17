import 'package:freezed_annotation/freezed_annotation.dart';

part 'letter_list_event.freezed.dart';

@freezed
sealed class LetterListEvent with _$LetterListEvent {
  const factory LetterListEvent.loadRequested() = LetterListLoadRequested;

  const factory LetterListEvent.refreshRequested() = LetterListRefreshRequested;

  const factory LetterListEvent.loadMoreRequested() = LetterListLoadMoreRequested;

  const factory LetterListEvent.statusFilterChanged(String? status) =
      LetterListStatusFilterChanged;

  const factory LetterListEvent.searchChanged(String query) =
      LetterListSearchChanged;
}
