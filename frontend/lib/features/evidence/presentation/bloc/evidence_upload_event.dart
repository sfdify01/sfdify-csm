import 'package:freezed_annotation/freezed_annotation.dart';

part 'evidence_upload_event.freezed.dart';

@freezed
sealed class EvidenceUploadEvent with _$EvidenceUploadEvent {
  const factory EvidenceUploadEvent.fileSelected({
    required String filename,
    required int fileSize,
    required String mimeType,
    required List<int> bytes,
  }) = EvidenceUploadFileSelected;

  const factory EvidenceUploadEvent.descriptionChanged(String description) =
      EvidenceUploadDescriptionChanged;

  const factory EvidenceUploadEvent.submitted({
    required String disputeId,
  }) = EvidenceUploadSubmitted;

  const factory EvidenceUploadEvent.cancelled() = EvidenceUploadCancelled;
}
