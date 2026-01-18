import 'package:json_annotation/json_annotation.dart';
import 'package:ustaxx_csm/features/users/domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
    super.permissions,
    super.twoFactorEnabled,
    super.disabled,
    super.createdAt,
    super.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJson(json);
    return _$UserModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Convert timestamps
    for (final key in ['createdAt', 'lastLoginAt']) {
      if (normalized[key] != null) {
        normalized[key] = _convertTimestamp(normalized[key]);
      }
    }

    return normalized;
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
