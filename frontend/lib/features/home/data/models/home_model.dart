import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/features/home/domain/entities/home_entity.dart';

part 'home_model.g.dart';

@JsonSerializable()
class HomeModel extends HomeEntity {
  const HomeModel({
    required super.title,
    required super.description,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeModelToJson(this);

  factory HomeModel.fromEntity(HomeEntity entity) {
    return HomeModel(
      title: entity.title,
      description: entity.description,
    );
  }
}
