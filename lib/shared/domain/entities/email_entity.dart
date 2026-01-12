import 'package:equatable/equatable.dart';

/// Email value object
class EmailEntity extends Equatable {
  final String email;
  final bool isPrimary;
  final bool verified;

  const EmailEntity({
    required this.email,
    this.isPrimary = false,
    this.verified = false,
  });

  /// Get domain from email
  String get domain {
    final parts = email.split('@');
    return parts.length == 2 ? parts[1] : '';
  }

  /// Get username from email
  String get username {
    final parts = email.split('@');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Check if email format is valid
  bool get isValid {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  List<Object?> get props => [email, isPrimary, verified];

  EmailEntity copyWith({
    String? email,
    bool? isPrimary,
    bool? verified,
  }) {
    return EmailEntity(
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      verified: verified ?? this.verified,
    );
  }
}
