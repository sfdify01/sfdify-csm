import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/shared/domain/entities/address_entity.dart';

part 'address_model.g.dart';

@JsonSerializable()
class AddressModel extends AddressEntity {
  const AddressModel({
    required super.type,
    required super.street1,
    super.street2,
    required super.city,
    required super.state,
    required super.zip,
    super.country = 'US',
    super.isCurrent = false,
    super.movedInDate,
    super.movedOutDate,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  factory AddressModel.fromEntity(AddressEntity entity) => AddressModel(
        type: entity.type,
        street1: entity.street1,
        street2: entity.street2,
        city: entity.city,
        state: entity.state,
        zip: entity.zip,
        country: entity.country,
        isCurrent: entity.isCurrent,
        movedInDate: entity.movedInDate,
        movedOutDate: entity.movedOutDate,
      );
}
