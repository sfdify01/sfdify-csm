import 'package:equatable/equatable.dart';

/// Tenant entity representing the organization/company
class TenantEntity extends Equatable {
  const TenantEntity({
    required this.id,
    required this.name,
    required this.plan,
    required this.status,
    this.logoUrl,
    this.primaryColor,
    this.companyName,
    this.tagline,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String plan;
  final String status;
  final String? logoUrl;
  final String? primaryColor;
  final String? companyName;
  final String? tagline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get plan display name
  String get planDisplayName {
    switch (plan) {
      case 'starter':
        return 'Starter';
      case 'professional':
        return 'Professional';
      case 'enterprise':
        return 'Enterprise';
      default:
        return plan;
    }
  }

  /// Check if tenant is active
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
        id,
        name,
        plan,
        status,
        logoUrl,
        primaryColor,
        companyName,
        tagline,
        createdAt,
        updatedAt,
      ];
}
