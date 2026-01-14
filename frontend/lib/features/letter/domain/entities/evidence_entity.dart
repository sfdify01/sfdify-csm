import 'package:equatable/equatable.dart';

/// Evidence entity representing supporting documents for disputes
class EvidenceEntity extends Equatable {
  final String id;
  final String disputeId;
  final String filename;
  final String fileUrl;
  final String mimeType;
  final int fileSize; // in bytes
  final String checksum; // SHA-256
  final String source; // 'uploaded', 'smartcredit', 'generated'
  final String? description;
  final bool scanned;
  final String? scanResult;
  final bool encrypted;
  final DateTime uploadedAt;
  final String? uploadedByUserId;

  const EvidenceEntity({
    required this.id,
    required this.disputeId,
    required this.filename,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSize,
    required this.checksum,
    required this.source,
    this.description,
    this.scanned = false,
    this.scanResult,
    this.encrypted = true,
    required this.uploadedAt,
    this.uploadedByUserId,
  });

  /// Get file size in human-readable format
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file extension
  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  /// Get file type display name
  String get fileTypeDisplayName {
    switch (mimeType.toLowerCase()) {
      case 'application/pdf':
        return 'PDF Document';
      case 'image/jpeg':
      case 'image/jpg':
        return 'JPEG Image';
      case 'image/png':
        return 'PNG Image';
      case 'image/gif':
        return 'GIF Image';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'Word Document';
      default:
        return 'Document';
    }
  }

  /// Check if file is an image
  bool get isImage => mimeType.startsWith('image/');

  /// Check if file is a PDF
  bool get isPdf => mimeType == 'application/pdf';

  /// Check if file is a document
  bool get isDocument =>
      mimeType.contains('document') ||
      mimeType == 'application/pdf' ||
      mimeType.contains('word');

  /// Check if file passed virus scan
  bool get isClean => scanned && scanResult?.toLowerCase() == 'clean';

  /// Check if file has malware
  bool get hasMalware => scanned && scanResult?.toLowerCase() != 'clean';

  /// Get source display name
  String get sourceDisplayName {
    switch (source) {
      case 'uploaded':
        return 'Uploaded';
      case 'smartcredit':
        return 'SmartCredit';
      case 'generated':
        return 'System Generated';
      default:
        return source;
    }
  }

  /// Get icon based on file type
  String get fileIcon {
    if (isPdf) return '📄';
    if (isImage) return '🖼️';
    if (isDocument) return '📝';
    return '📎';
  }

  @override
  List<Object?> get props => [
        id,
        disputeId,
        filename,
        fileUrl,
        mimeType,
        fileSize,
        checksum,
        source,
        description,
        scanned,
        scanResult,
        encrypted,
        uploadedAt,
        uploadedByUserId,
      ];

  EvidenceEntity copyWith({
    String? id,
    String? disputeId,
    String? filename,
    String? fileUrl,
    String? mimeType,
    int? fileSize,
    String? checksum,
    String? source,
    String? description,
    bool? scanned,
    String? scanResult,
    bool? encrypted,
    DateTime? uploadedAt,
    String? uploadedByUserId,
  }) {
    return EvidenceEntity(
      id: id ?? this.id,
      disputeId: disputeId ?? this.disputeId,
      filename: filename ?? this.filename,
      fileUrl: fileUrl ?? this.fileUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      checksum: checksum ?? this.checksum,
      source: source ?? this.source,
      description: description ?? this.description,
      scanned: scanned ?? this.scanned,
      scanResult: scanResult ?? this.scanResult,
      encrypted: encrypted ?? this.encrypted,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
    );
  }
}
