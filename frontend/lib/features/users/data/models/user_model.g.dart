// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  role: json['role'] as String,
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
  disabled: json['disabled'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  lastLoginAt: json['lastLoginAt'] == null
      ? null
      : DateTime.parse(json['lastLoginAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'displayName': instance.displayName,
  'role': instance.role,
  'permissions': instance.permissions,
  'twoFactorEnabled': instance.twoFactorEnabled,
  'disabled': instance.disabled,
  'createdAt': instance.createdAt?.toIso8601String(),
  'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
};
