import 'package:json_annotation/json_annotation.dart';
import 'package:sfdify_scm/features/tenant/domain/entities/tenant_entity.dart';

part 'tenant_model.g.dart';

@JsonSerializable()
class TenantModel extends TenantEntity {
  const TenantModel({
    required super.id,
    required super.name,
    required super.plan,
    required super.status,
    super.logoUrl,
    super.primaryColor,
    super.companyName,
    super.tagline,
    super.createdAt,
    super.updatedAt,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJson(json);
    return _$TenantModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$TenantModelToJson(this);

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Flatten branding fields
    if (normalized['branding'] is Map) {
      final branding = normalized['branding'] as Map<String, dynamic>;
      normalized['logoUrl'] = branding['logoUrl'];
      normalized['primaryColor'] = branding['primaryColor'];
      normalized['companyName'] = branding['companyName'];
      normalized['tagline'] = branding['tagline'];
    }

    // Convert timestamps
    for (final key in ['createdAt', 'updatedAt']) {
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
