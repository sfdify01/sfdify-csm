import 'package:equatable/equatable.dart';

/// User entity representing a team member
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.permissions = const [],
    this.twoFactorEnabled = false,
    this.disabled = false,
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final List<String> permissions;
  final bool twoFactorEnabled;
  final bool disabled;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'operator':
        return 'Operator';
      case 'viewer':
        return 'Viewer';
      case 'auditor':
        return 'Auditor';
      default:
        return role;
    }
  }

  /// Check if user is an admin (owner or operator)
  bool get isAdmin => role == 'owner' || role == 'operator';

  /// Check if user can manage team
  bool get canManageTeam => role == 'owner';

  /// Check if user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        permissions,
        twoFactorEnabled,
        disabled,
        createdAt,
        lastLoginAt,
      ];
}
