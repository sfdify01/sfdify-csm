// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeModel _$DisputeModelFromJson(Map<String, dynamic> json) => DisputeModel(
  id: json['id'] as String,
  consumerId: json['consumerId'] as String,
  consumer: DisputeModel._consumerFromJson(
    json['consumer'] as Map<String, dynamic>?,
  ),
  tradelineId: json['tradelineId'] as String?,
  bureau: json['bureau'] as String,
  type: json['type'] as String,
  reasonCodes: (json['reasonCodes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  narrative: json['narrative'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
  followedUpAt: json['followedUpAt'] == null
      ? null
      : DateTime.parse(json['followedUpAt'] as String),
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  outcome: json['outcome'] as String?,
  resolutionNotes: json['resolutionNotes'] as String?,
  bureauResponseReceivedAt: json['bureauResponseReceivedAt'] == null
      ? null
      : DateTime.parse(json['bureauResponseReceivedAt'] as String),
  assignedToUserId: json['assignedToUserId'] as String?,
  priority: json['priority'] as String? ?? 'medium',
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$DisputeModelToJson(DisputeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'consumerId': instance.consumerId,
      'tradelineId': instance.tradelineId,
      'bureau': instance.bureau,
      'type': instance.type,
      'reasonCodes': instance.reasonCodes,
      'narrative': instance.narrative,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'dueAt': instance.dueAt?.toIso8601String(),
      'followedUpAt': instance.followedUpAt?.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
      'outcome': instance.outcome,
      'resolutionNotes': instance.resolutionNotes,
      'bureauResponseReceivedAt': instance.bureauResponseReceivedAt
          ?.toIso8601String(),
      'assignedToUserId': instance.assignedToUserId,
      'priority': instance.priority,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'consumer': DisputeModel._consumerToJson(instance.consumer),
    };
