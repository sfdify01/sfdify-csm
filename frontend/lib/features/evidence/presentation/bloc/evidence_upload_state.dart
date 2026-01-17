import 'package:equatable/equatable.dart';
import 'package:sfdify_scm/features/letter/domain/entities/evidence_entity.dart';

enum EvidenceUploadStatus { initial, fileSelected, uploading, success, failure }

class EvidenceUploadState extends Equatable {
  const EvidenceUploadState({
    this.status = EvidenceUploadStatus.initial,
    this.filename,
    this.fileSize,
    this.mimeType,
    this.bytes,
    this.description = '',
    this.progress = 0.0,
    this.uploadedEvidence,
    this.errorMessage,
  });

  final EvidenceUploadStatus status;
  final String? filename;
  final int? fileSize;
  final String? mimeType;
  final List<int>? bytes;
  final String description;
  final double progress;
  final EvidenceEntity? uploadedEvidence;
  final String? errorMessage;

  EvidenceUploadState copyWith({
    EvidenceUploadStatus? status,
    String? filename,
    int? fileSize,
    String? mimeType,
    List<int>? bytes,
    String? description,
    double? progress,
    EvidenceEntity? uploadedEvidence,
    String? errorMessage,
  }) {
    return EvidenceUploadState(
      status: status ?? this.status,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
      description: description ?? this.description,
      progress: progress ?? this.progress,
      uploadedEvidence: uploadedEvidence ?? this.uploadedEvidence,
      errorMessage: errorMessage,
    );
  }

  /// Check if file is selected and ready for upload
  bool get canUpload =>
      status == EvidenceUploadStatus.fileSelected &&
      filename != null &&
      bytes != null;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file extension
  String get fileExtension {
    if (filename == null) return '';
    final parts = filename!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  @override
  List<Object?> get props => [
        status,
        filename,
        fileSize,
        mimeType,
        bytes,
        description,
        progress,
        uploadedEvidence,
        errorMessage,
      ];
}
