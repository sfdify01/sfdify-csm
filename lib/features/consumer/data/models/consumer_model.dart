import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';

part 'consumer_model.g.dart';

@JsonSerializable()
class ConsumerModel extends ConsumerEntity {
  const ConsumerModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phone,
  });

  factory ConsumerModel.fromJson(Map<String, dynamic> json) =>
      _$ConsumerModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConsumerModelToJson(this);

  factory ConsumerModel.fromEntity(ConsumerEntity entity) => ConsumerModel(
        id: entity.id,
        firstName: entity.firstName,
        lastName: entity.lastName,
        email: entity.email,
        phone: entity.phone,
      );
}
