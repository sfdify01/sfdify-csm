import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';

enum LetterDetailStatus { initial, loading, success, failure }

enum LetterActionStatus { idle, processing, success, failure }

class LetterDetailState extends Equatable {
  const LetterDetailState({
    this.status = LetterDetailStatus.initial,
    this.actionStatus = LetterActionStatus.idle,
    this.letter,
    this.errorMessage,
  });

  final LetterDetailStatus status;
  final LetterActionStatus actionStatus;
  final LetterEntity? letter;
  final String? errorMessage;

  LetterDetailState copyWith({
    LetterDetailStatus? status,
    LetterActionStatus? actionStatus,
    LetterEntity? letter,
    String? errorMessage,
  }) {
    return LetterDetailState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      letter: letter ?? this.letter,
      errorMessage: errorMessage,
    );
  }

  /// Check if letter can be approved
  bool get canApprove => letter?.status == 'pending_approval';

  /// Check if letter can be sent
  bool get canSend =>
      letter?.status == 'approved' || letter?.status == 'ready';

  /// Check if letter has PDF available
  bool get hasPdf => letter?.pdfUrl != null && letter!.pdfUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        letter,
        errorMessage,
      ];
}
