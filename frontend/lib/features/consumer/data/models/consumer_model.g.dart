// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsumerModel _$ConsumerModelFromJson(Map<String, dynamic> json) =>
    ConsumerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$ConsumerModelToJson(ConsumerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
    };
