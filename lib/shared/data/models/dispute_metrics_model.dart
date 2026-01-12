import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

part 'dispute_metrics_model.g.dart';

@JsonSerializable()
class DisputeMetricsModel extends DisputeMetricsEntity {
  const DisputeMetricsModel({
    required super.totalDisputes,
    required super.percentageChange,
    required super.pendingApproval,
    required super.inTransitViaLob,
    required super.slaBreaches,
    required super.slaBreachesToday,
  });

  factory DisputeMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$DisputeMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DisputeMetricsModelToJson(this);

  factory DisputeMetricsModel.fromEntity(DisputeMetricsEntity entity) =>
      DisputeMetricsModel(
        totalDisputes: entity.totalDisputes,
        percentageChange: entity.percentageChange,
        pendingApproval: entity.pendingApproval,
        inTransitViaLob: entity.inTransitViaLob,
        slaBreaches: entity.slaBreaches,
        slaBreachesToday: entity.slaBreachesToday,
      );
}
