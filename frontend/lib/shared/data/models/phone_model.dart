import 'package:json_annotation/json_annotation.dart';
import 'package:ustaxx_csm/shared/domain/entities/phone_entity.dart';

part 'phone_model.g.dart';

@JsonSerializable()
class PhoneModel extends PhoneEntity {
  const PhoneModel({
    required super.type,
    required super.number,
    super.isPrimary = false,
    super.verified = false,
  });

  factory PhoneModel.fromJson(Map<String, dynamic> json) =>
      _$PhoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneModelToJson(this);

  factory PhoneModel.fromEntity(PhoneEntity entity) => PhoneModel(
        type: entity.type,
        number: entity.number,
        isPrimary: entity.isPrimary,
        verified: entity.verified,
      );
}
