part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current authentication state on app startup
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User requested login with email/password
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User requested logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// User requested registration with email/password
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
    required this.companyName,
    this.plan = 'starter',
  });

  final String email;
  final String password;
  final String displayName;
  final String companyName;
  final String plan;

  @override
  List<Object?> get props => [email, password, displayName, companyName, plan];
}

/// Internal event when Firebase auth state changes
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.authState);

  final AuthState? authState;

  @override
  List<Object?> get props => [authState];
}
