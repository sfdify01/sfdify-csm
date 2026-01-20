// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantModel _$TenantModelFromJson(Map<String, dynamic> json) => TenantModel(
  id: json['id'] as String,
  name: json['name'] as String,
  status: json['status'] as String,
  logoUrl: json['logoUrl'] as String?,
  primaryColor: json['primaryColor'] as String?,
  companyName: json['companyName'] as String?,
  tagline: json['tagline'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TenantModelToJson(TenantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'logoUrl': instance.logoUrl,
      'primaryColor': instance.primaryColor,
      'companyName': instance.companyName,
      'tagline': instance.tagline,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
