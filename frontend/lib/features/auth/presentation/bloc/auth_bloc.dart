import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:ustaxx_csm/core/services/firebase_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@singleton
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc(
    this._authService,
    this._logger,
  ) : super(const AuthBlocState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthStateChanged>(_onStateChanged);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);
    on<AuthClearError>(_onClearError);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);

    // Listen to auth state changes from Firebase
    _authSubscription = _authService.authStateChanges.listen(
      (authState) {
        add(AuthStateChanged(authState));
      },
      onError: (error) {
        _logger.e('Auth state stream error', error: error);
        add(const AuthStateChanged(null));
      },
    );
  }

  final FirebaseAuthService _authService;
  final Logger _logger;
  StreamSubscription<AuthState?>? _authSubscription;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Checking authentication state');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final authState = await _authService.currentAuthState;
      if (authState != null) {
        _logger.i('User is authenticated: ${authState.userId}');
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: authState,
        ));
      } else {
        _logger.i('User is not authenticated');
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      _logger.e('Error checking auth state', error: e);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to check authentication status.',
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Login requested for: ${event.email}');
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final authState = await _authService.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      _logger.i('Login successful for: ${authState.userId}');
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authState,
      ));
    } on AuthServiceException catch (e) {
      _logger.w('Login failed: ${e.code} - ${e.message}');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      ));
    } catch (e) {
      _logger.e('Unexpected login error', error: e);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Logout requested');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authService.signOut();
      _logger.i('Logout successful');
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    } catch (e) {
      _logger.e('Logout error', error: e);
      // Even if there's an error, treat user as logged out
      emit(const AuthBlocState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signed out with errors.',
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Registration requested for: ${event.email}');
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final authState = await _authService.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        companyName: event.companyName,
        plan: event.plan,
      );

      _logger.i('Registration successful for: ${authState.userId}');
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authState,
      ));
    } on AuthServiceException catch (e) {
      _logger.w('Registration failed: ${e.code} - ${e.message}');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      ));
    } catch (e) {
      _logger.e('Unexpected registration error', error: e);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to create account. Please try again.',
      ));
    }
  }

  void _onStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    if (event.authState != null) {
      _logger.d('Auth state changed: authenticated');
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.authState,
      ));
    } else {
      _logger.d('Auth state changed: unauthenticated');
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Token refresh requested');
    try {
      await _authService.refreshToken();
      final authState = await _authService.currentAuthState;
      if (authState != null) {
        emit(state.copyWith(user: authState));
      }
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
      // If token refresh fails, sign out the user
      emit(const AuthBlocState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please sign in again.',
      ));
    }
  }

  void _onClearError(
    AuthClearError event,
    Emitter<AuthBlocState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    _logger.i('Password reset requested for: ${event.email}');
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authService.sendPasswordResetEmail(event.email);
      _logger.i('Password reset email sent');
      emit(state.copyWith(status: AuthStatus.passwordResetSent));
    } on AuthServiceException catch (e) {
      _logger.w('Password reset failed: ${e.code} - ${e.message}');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      ));
    } catch (e) {
      _logger.e('Unexpected password reset error', error: e);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to send password reset email. Please try again.',
      ));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
