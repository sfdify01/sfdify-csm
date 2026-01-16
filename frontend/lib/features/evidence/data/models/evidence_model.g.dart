// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvidenceModel _$EvidenceModelFromJson(Map<String, dynamic> json) =>
    EvidenceModel(
      id: json['id'] as String,
      disputeId: json['disputeId'] as String,
      filename: json['filename'] as String,
      fileUrl: json['fileUrl'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      checksum: json['checksum'] as String,
      source: json['source'] as String,
      description: json['description'] as String?,
      scanned: json['scanned'] as bool? ?? false,
      scanResult: json['scanResult'] as String?,
      encrypted: json['encrypted'] as bool? ?? true,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      uploadedByUserId: json['uploadedByUserId'] as String?,
    );

Map<String, dynamic> _$EvidenceModelToJson(EvidenceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'disputeId': instance.disputeId,
      'filename': instance.filename,
      'fileUrl': instance.fileUrl,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'checksum': instance.checksum,
      'source': instance.source,
      'description': instance.description,
      'scanned': instance.scanned,
      'scanResult': instance.scanResult,
      'encrypted': instance.encrypted,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'uploadedByUserId': instance.uploadedByUserId,
    };
