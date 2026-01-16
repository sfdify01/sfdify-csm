part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  /// Google user signed in but needs company setup
  needsCompanySetup,
}

class AuthBlocState extends Equatable {
  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.googleUserEmail,
    this.googleUserDisplayName,
  });

  final AuthStatus status;
  final AuthState? user;
  final String? errorMessage;

  /// Email of Google user who needs company setup
  final String? googleUserEmail;

  /// Display name of Google user who needs company setup
  final String? googleUserDisplayName;

  /// Check if user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Get current user's tenant ID
  String? get tenantId => user?.tenantId;

  /// Get current user's role
  UserRole? get role => user?.role;

  /// Get current user's permissions
  List<String> get permissions => user?.permissions ?? [];

  /// Check if user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  AuthBlocState copyWith({
    AuthStatus? status,
    AuthState? user,
    String? errorMessage,
    String? googleUserEmail,
    String? googleUserDisplayName,
  }) {
    return AuthBlocState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      googleUserEmail: googleUserEmail ?? this.googleUserEmail,
      googleUserDisplayName: googleUserDisplayName ?? this.googleUserDisplayName,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        googleUserEmail,
        googleUserDisplayName,
      ];
}
