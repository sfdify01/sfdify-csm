// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LetterModel _$LetterModelFromJson(Map<String, dynamic> json) => LetterModel(
  id: json['id'] as String,
  disputeId: json['disputeId'] as String,
  type: json['type'] as String,
  templateId: json['templateId'] as String?,
  renderVersion: (json['renderVersion'] as num).toInt(),
  contentHtml: json['contentHtml'] as String?,
  contentMarkdown: json['contentMarkdown'] as String?,
  pdfUrl: json['pdfUrl'] as String?,
  pdfChecksum: json['pdfChecksum'] as String?,
  lobId: json['lobId'] as String?,
  lobUrl: json['lobUrl'] as String?,
  mailType: json['mailType'] as String,
  trackingCode: json['trackingCode'] as String?,
  trackingUrl: json['trackingUrl'] as String?,
  expectedDeliveryDate: json['expectedDeliveryDate'] == null
      ? null
      : DateTime.parse(json['expectedDeliveryDate'] as String),
  recipientAddress: _addressFromJson(
    json['recipientAddress'] as Map<String, dynamic>,
  ),
  returnAddress: _addressFromJson(
    json['returnAddress'] as Map<String, dynamic>,
  ),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  approvedAt: json['approvedAt'] == null
      ? null
      : DateTime.parse(json['approvedAt'] as String),
  approvedByUserId: json['approvedByUserId'] as String?,
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  inTransitAt: json['inTransitAt'] == null
      ? null
      : DateTime.parse(json['inTransitAt'] as String),
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
  returnedAt: json['returnedAt'] == null
      ? null
      : DateTime.parse(json['returnedAt'] as String),
  cost: (json['cost'] as num?)?.toDouble(),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$LetterModelToJson(LetterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'disputeId': instance.disputeId,
      'type': instance.type,
      'templateId': instance.templateId,
      'renderVersion': instance.renderVersion,
      'contentHtml': instance.contentHtml,
      'contentMarkdown': instance.contentMarkdown,
      'pdfUrl': instance.pdfUrl,
      'pdfChecksum': instance.pdfChecksum,
      'lobId': instance.lobId,
      'lobUrl': instance.lobUrl,
      'mailType': instance.mailType,
      'trackingCode': instance.trackingCode,
      'trackingUrl': instance.trackingUrl,
      'expectedDeliveryDate': instance.expectedDeliveryDate?.toIso8601String(),
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'approvedByUserId': instance.approvedByUserId,
      'sentAt': instance.sentAt?.toIso8601String(),
      'inTransitAt': instance.inTransitAt?.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'returnedAt': instance.returnedAt?.toIso8601String(),
      'cost': instance.cost,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'recipientAddress': _addressToJson(instance.recipientAddress),
      'returnAddress': _addressToJson(instance.returnAddress),
    };

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
