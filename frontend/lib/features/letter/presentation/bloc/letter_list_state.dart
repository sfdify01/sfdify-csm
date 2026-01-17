import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';

enum LetterListStatus { initial, loading, success, failure }

class LetterListState extends Equatable {
  const LetterListState({
    this.status = LetterListStatus.initial,
    this.letters = const [],
    this.filteredLetters = const [],
    this.statusFilter,
    this.searchQuery = '',
    this.cursor,
    this.hasMore = false,
    this.errorMessage,
  });

  final LetterListStatus status;
  final List<LetterEntity> letters;
  final List<LetterEntity> filteredLetters;
  final String? statusFilter;
  final String searchQuery;
  final String? cursor;
  final bool hasMore;
  final String? errorMessage;

  LetterListState copyWith({
    LetterListStatus? status,
    List<LetterEntity>? letters,
    List<LetterEntity>? filteredLetters,
    String? statusFilter,
    String? searchQuery,
    String? cursor,
    bool? hasMore,
    String? errorMessage,
  }) {
    return LetterListState(
      status: status ?? this.status,
      letters: letters ?? this.letters,
      filteredLetters: filteredLetters ?? this.filteredLetters,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      cursor: cursor,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  /// Get letter counts by status
  int get draftCount =>
      letters.where((l) => l.status == 'draft').length;

  int get pendingApprovalCount =>
      letters.where((l) => l.status == 'pending_approval').length;

  int get approvedCount =>
      letters.where((l) => l.status == 'approved' || l.status == 'ready').length;

  int get inTransitCount =>
      letters.where((l) => l.isInTransit).length;

  int get deliveredCount =>
      letters.where((l) => l.status == 'delivered').length;

  int get returnedCount =>
      letters.where((l) => l.status == 'returned_to_sender').length;

  /// Total cost of all letters
  double get totalCost =>
      letters.fold(0.0, (sum, l) => sum + (l.cost ?? 0.0));

  @override
  List<Object?> get props => [
        status,
        letters,
        filteredLetters,
        statusFilter,
        searchQuery,
        cursor,
        hasMore,
        errorMessage,
      ];
}
