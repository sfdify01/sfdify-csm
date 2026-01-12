// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailModel _$EmailModelFromJson(Map<String, dynamic> json) => EmailModel(
  email: json['email'] as String,
  isPrimary: json['isPrimary'] as bool? ?? false,
  verified: json['verified'] as bool? ?? false,
);

Map<String, dynamic> _$EmailModelToJson(EmailModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'isPrimary': instance.isPrimary,
      'verified': instance.verified,
    };
