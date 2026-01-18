part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  passwordResetSent,
}

class AuthBlocState extends Equatable {
  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthState? user;
  final String? errorMessage;

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
  }) {
    return AuthBlocState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
      ];
}
