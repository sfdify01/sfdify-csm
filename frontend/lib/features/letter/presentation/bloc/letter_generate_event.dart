import 'package:freezed_annotation/freezed_annotation.dart';

part 'letter_generate_event.freezed.dart';

@freezed
sealed class LetterGenerateEvent with _$LetterGenerateEvent {
  const factory LetterGenerateEvent.loadRequested(String disputeId) =
      LetterGenerateLoadRequested;

  const factory LetterGenerateEvent.templateChanged(String templateId) =
      LetterGenerateTemplateChanged;

  const factory LetterGenerateEvent.mailTypeChanged(String mailType) =
      LetterGenerateMailTypeChanged;

  const factory LetterGenerateEvent.submitted() = LetterGenerateSubmitted;
}
