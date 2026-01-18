import 'package:json_annotation/json_annotation.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/evidence_entity.dart';

part 'evidence_model.g.dart';

@JsonSerializable()
class EvidenceModel extends EvidenceEntity {
  const EvidenceModel({
    required super.id,
    required super.disputeId,
    required super.filename,
    required super.fileUrl,
    required super.mimeType,
    required super.fileSize,
    required super.checksum,
    required super.source,
    super.description,
    super.scanned,
    super.scanResult,
    super.encrypted,
    required super.uploadedAt,
    super.uploadedByUserId,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJson(json);
    return _$EvidenceModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$EvidenceModelToJson(this);

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Map backend field names to frontend
    if (normalized['originalFilename'] != null && normalized['filename'] == null) {
      normalized['filename'] = normalized['originalFilename'];
    }

    // Handle virus scan info
    if (normalized['virusScan'] is Map) {
      final virusScan = normalized['virusScan'] as Map<String, dynamic>;
      normalized['scanned'] = virusScan['status'] != 'pending';
      normalized['scanResult'] = virusScan['status'] == 'clean' ? 'clean' : virusScan['virusName'];
    }

    // Map uploadedAt from timestamp
    if (normalized['uploadedAt'] != null) {
      normalized['uploadedAt'] = _convertTimestamp(normalized['uploadedAt']);
    }

    // Map uploadedBy to uploadedByUserId
    if (normalized['uploadedBy'] != null && normalized['uploadedByUserId'] == null) {
      normalized['uploadedByUserId'] = normalized['uploadedBy'];
    }

    return normalized;
  }

  static String? _convertTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    if (value is Map) {
      if (value.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as int) * 1000,
        ).toIso8601String();
      }
      if (value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] as int) * 1000,
        ).toIso8601String();
      }
    }
    return null;
  }
}
