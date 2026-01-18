import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/evidence/domain/repositories/evidence_repository.dart';
import 'package:ustaxx_csm/features/evidence/presentation/bloc/evidence_upload_event.dart';
import 'package:ustaxx_csm/features/evidence/presentation/bloc/evidence_upload_state.dart';

@injectable
class EvidenceUploadBloc
    extends Bloc<EvidenceUploadEvent, EvidenceUploadState> {
  EvidenceUploadBloc(this._evidenceRepository)
      : super(const EvidenceUploadState()) {
    on<EvidenceUploadFileSelected>(_onFileSelected);
    on<EvidenceUploadDescriptionChanged>(_onDescriptionChanged);
    on<EvidenceUploadSubmitted>(_onSubmitted);
    on<EvidenceUploadCancelled>(_onCancelled);
  }

  final EvidenceRepository _evidenceRepository;

  void _onFileSelected(
    EvidenceUploadFileSelected event,
    Emitter<EvidenceUploadState> emit,
  ) {
    emit(state.copyWith(
      status: EvidenceUploadStatus.fileSelected,
      filename: event.filename,
      fileSize: event.fileSize,
      mimeType: event.mimeType,
      bytes: event.bytes,
    ));
  }

  void _onDescriptionChanged(
    EvidenceUploadDescriptionChanged event,
    Emitter<EvidenceUploadState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onSubmitted(
    EvidenceUploadSubmitted event,
    Emitter<EvidenceUploadState> emit,
  ) async {
    if (!state.canUpload) return;

    emit(state.copyWith(
      status: EvidenceUploadStatus.uploading,
      progress: 0.0,
    ));

    // Simulate upload progress
    for (var i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(progress: i / 10));
    }

    final result = await _evidenceRepository.uploadEvidence({
      'disputeId': event.disputeId,
      'filename': state.filename,
      'mimeType': state.mimeType,
      'fileSize': state.fileSize,
      'description': state.description,
      // In a real implementation, bytes would be uploaded to Cloud Storage
    });

    result.fold(
      (failure) => emit(state.copyWith(
        status: EvidenceUploadStatus.failure,
        errorMessage: failure.message,
      )),
      (evidence) => emit(state.copyWith(
        status: EvidenceUploadStatus.success,
        uploadedEvidence: evidence,
      )),
    );
  }

  void _onCancelled(
    EvidenceUploadCancelled event,
    Emitter<EvidenceUploadState> emit,
  ) {
    emit(const EvidenceUploadState());
  }
}
