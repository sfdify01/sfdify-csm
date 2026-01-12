// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) => AddressModel(
  type: json['type'] as String,
  street1: json['street1'] as String,
  street2: json['street2'] as String?,
  city: json['city'] as String,
  state: json['state'] as String,
  zip: json['zip'] as String,
  country: json['country'] as String? ?? 'US',
  isCurrent: json['isCurrent'] as bool? ?? false,
  movedInDate: json['movedInDate'] == null
      ? null
      : DateTime.parse(json['movedInDate'] as String),
  movedOutDate: json['movedOutDate'] == null
      ? null
      : DateTime.parse(json['movedOutDate'] as String),
);

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'street1': instance.street1,
      'street2': instance.street2,
      'city': instance.city,
      'state': instance.state,
      'zip': instance.zip,
      'country': instance.country,
      'isCurrent': instance.isCurrent,
      'movedInDate': instance.movedInDate?.toIso8601String(),
      'movedOutDate': instance.movedOutDate?.toIso8601String(),
    };
