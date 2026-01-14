// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_metrics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeMetricsModel _$DisputeMetricsModelFromJson(Map<String, dynamic> json) =>
    DisputeMetricsModel(
      totalDisputes: (json['totalDisputes'] as num).toInt(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      pendingApproval: (json['pendingApproval'] as num).toInt(),
      inTransitViaLob: (json['inTransitViaLob'] as num).toInt(),
      slaBreaches: (json['slaBreaches'] as num).toInt(),
      slaBreachesToday: (json['slaBreachesToday'] as num).toInt(),
    );

Map<String, dynamic> _$DisputeMetricsModelToJson(
  DisputeMetricsModel instance,
) => <String, dynamic>{
  'totalDisputes': instance.totalDisputes,
  'percentageChange': instance.percentageChange,
  'pendingApproval': instance.pendingApproval,
  'inTransitViaLob': instance.inTransitViaLob,
  'slaBreaches': instance.slaBreaches,
  'slaBreachesToday': instance.slaBreachesToday,
};
