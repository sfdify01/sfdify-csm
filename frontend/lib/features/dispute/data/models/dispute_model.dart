import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/features/consumer/data/models/consumer_model.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';

part 'dispute_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DisputeModel extends DisputeEntity {
  @JsonKey(
    fromJson: _consumerFromJson,
    toJson: _consumerToJson,
  )
  @override
  final ConsumerModel? consumer;

  const DisputeModel({
    required super.id,
    required super.consumerId,
    this.consumer,
    super.tradelineId,
    required super.bureau,
    required super.type,
    required super.reasonCodes,
    super.narrative,
    required super.status,
    required super.createdAt,
    super.submittedAt,
    super.dueAt,
    super.followedUpAt,
    super.closedAt,
    super.outcome,
    super.resolutionNotes,
    super.bureauResponseReceivedAt,
    super.assignedToUserId,
    super.priority = 'medium',
    required super.updatedAt,
  }) : super(consumer: consumer);

  static ConsumerModel? _consumerFromJson(Map<String, dynamic>? json) =>
      json == null ? null : ConsumerModel.fromJson(json);

  static Map<String, dynamic>? _consumerToJson(ConsumerModel? consumer) =>
      consumer?.toJson();

  factory DisputeModel.fromJson(Map<String, dynamic> json) =>
      _$DisputeModelFromJson(json);

  Map<String, dynamic> toJson() => _$DisputeModelToJson(this);

  factory DisputeModel.fromEntity(DisputeEntity entity) => DisputeModel(
        id: entity.id,
        consumerId: entity.consumerId,
        consumer: entity.consumer != null
            ? ConsumerModel.fromEntity(entity.consumer!)
            : null,
        tradelineId: entity.tradelineId,
        bureau: entity.bureau,
        type: entity.type,
        reasonCodes: entity.reasonCodes,
        narrative: entity.narrative,
        status: entity.status,
        createdAt: entity.createdAt,
        submittedAt: entity.submittedAt,
        dueAt: entity.dueAt,
        followedUpAt: entity.followedUpAt,
        closedAt: entity.closedAt,
        outcome: entity.outcome,
        resolutionNotes: entity.resolutionNotes,
        bureauResponseReceivedAt: entity.bureauResponseReceivedAt,
        assignedToUserId: entity.assignedToUserId,
        priority: entity.priority,
        updatedAt: entity.updatedAt,
      );
}
