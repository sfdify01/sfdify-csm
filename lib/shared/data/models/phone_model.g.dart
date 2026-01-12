// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneModel _$PhoneModelFromJson(Map<String, dynamic> json) => PhoneModel(
  type: json['type'] as String,
  number: json['number'] as String,
  isPrimary: json['isPrimary'] as bool? ?? false,
  verified: json['verified'] as bool? ?? false,
);

Map<String, dynamic> _$PhoneModelToJson(PhoneModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'number': instance.number,
      'isPrimary': instance.isPrimary,
      'verified': instance.verified,
    };
