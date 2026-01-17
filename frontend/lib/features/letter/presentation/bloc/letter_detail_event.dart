import 'package:freezed_annotation/freezed_annotation.dart';

part 'letter_detail_event.freezed.dart';

@freezed
sealed class LetterDetailEvent with _$LetterDetailEvent {
  const factory LetterDetailEvent.loadRequested(String letterId) =
      LetterDetailLoadRequested;

  const factory LetterDetailEvent.refreshRequested() =
      LetterDetailRefreshRequested;

  const factory LetterDetailEvent.approveRequested() =
      LetterDetailApproveRequested;

  const factory LetterDetailEvent.sendRequested() =
      LetterDetailSendRequested;
}
