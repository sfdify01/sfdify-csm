import 'package:json_annotation/json_annotation.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';
import 'package:ustaxx_csm/shared/domain/entities/address_entity.dart';

part 'letter_model.g.dart';

AddressEntity _addressFromJson(Map<String, dynamic> json) => AddressModel.fromJson(json);
Map<String, dynamic> _addressToJson(AddressEntity address) {
  return {
    'type': address.type,
    'street1': address.street1,
    'street2': address.street2,
    'city': address.city,
    'state': address.state,
    'zip': address.zip,
    'country': address.country,
    'isCurrent': address.isCurrent,
  };
}

@JsonSerializable(explicitToJson: true)
class LetterModel extends LetterEntity {
  @JsonKey(fromJson: _addressFromJson, toJson: _addressToJson)
  @override
  final AddressEntity recipientAddress;

  @JsonKey(fromJson: _addressFromJson, toJson: _addressToJson)
  @override
  final AddressEntity returnAddress;

  const LetterModel({
    required super.id,
    required super.disputeId,
    required super.type,
    super.templateId,
    required super.renderVersion,
    super.contentHtml,
    super.contentMarkdown,
    super.pdfUrl,
    super.pdfChecksum,
    super.lobId,
    super.lobUrl,
    required super.mailType,
    super.trackingCode,
    super.trackingUrl,
    super.expectedDeliveryDate,
    required this.recipientAddress,
    required this.returnAddress,
    required super.status,
    required super.createdAt,
    super.approvedAt,
    super.approvedByUserId,
    super.sentAt,
    super.inTransitAt,
    super.deliveredAt,
    super.returnedAt,
    super.cost,
    required super.updatedAt,
  }) : super(recipientAddress: recipientAddress, returnAddress: returnAddress);

  factory LetterModel.fromJson(Map<String, dynamic> json) {
    // Normalize the JSON before parsing
    final normalized = _normalizeJson(json);
    return _$LetterModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$LetterModelToJson(this);

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Convert timestamps
    final timestampKeys = [
      'createdAt', 'updatedAt', 'approvedAt', 'sentAt', 'inTransitAt',
      'deliveredAt', 'returnedAt', 'expectedDeliveryDate'
    ];

    for (final key in timestampKeys) {
      if (normalized[key] != null) {
        normalized[key] = _convertTimestamp(normalized[key]);
      }
    }

    // Normalize recipient address
    if (normalized['recipientAddress'] is Map) {
      normalized['recipientAddress'] = _normalizeAddress(
        normalized['recipientAddress'] as Map<String, dynamic>,
      );
    }

    // Normalize return address
    if (normalized['returnAddress'] is Map) {
      normalized['returnAddress'] = _normalizeAddress(
        normalized['returnAddress'] as Map<String, dynamic>,
      );
    }

    // Extract cost from nested cost object if present
    if (normalized['cost'] is Map) {
      final costObj = normalized['cost'] as Map<String, dynamic>;
      normalized['cost'] = costObj['total'];
    }

    // Map renderVersion from string if needed
    if (normalized['renderVersion'] is String) {
      normalized['renderVersion'] = int.tryParse(normalized['renderVersion'] as String) ?? 1;
    }

    return normalized;
  }

  static Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return {
      'type': address['type'] ?? 'mailing',
      'street1': address['addressLine1'] ?? address['street1'] ?? '',
      'street2': address['addressLine2'] ?? address['street2'],
      'city': address['city'] ?? '',
      'state': address['state'] ?? '',
      'zip': address['zipCode'] ?? address['zip'] ?? '',
      'country': address['country'] ?? 'US',
      'isCurrent': address['isCurrent'] ?? true,
    };
  }

  static String? _convertTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    if (value is Map) {
      if (value.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as int) * 1000,
        ).toIso8601String();
      }
      if (value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] as int) * 1000,
        ).toIso8601String();
      }
    }
    return null;
  }
}

@JsonSerializable()
class AddressModel extends AddressEntity {
  const AddressModel({
    required super.type,
    required super.street1,
    super.street2,
    required super.city,
    required super.state,
    required super.zip,
    super.country,
    super.isCurrent,
    super.movedInDate,
    super.movedOutDate,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}
