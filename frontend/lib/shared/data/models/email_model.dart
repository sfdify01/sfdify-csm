import 'package:json_annotation/json_annotation.dart';
import 'package:ustaxx_csm/shared/domain/entities/email_entity.dart';

part 'email_model.g.dart';

@JsonSerializable()
class EmailModel extends EmailEntity {
  const EmailModel({
    required super.email,
    super.isPrimary = false,
    super.verified = false,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) =>
      _$EmailModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmailModelToJson(this);

  factory EmailModel.fromEntity(EmailEntity entity) => EmailModel(
        email: entity.email,
        isPrimary: entity.isPrimary,
        verified: entity.verified,
      );
}
