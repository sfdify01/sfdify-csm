import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/services/firebase_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@singleton
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc(this._authService) : super(const AuthBlocState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthStateChanged>(_onStateChanged);

    // Listen to auth state changes from Firebase
    _authSubscription = _authService.authStateChanges.listen((authState) {
      add(AuthStateChanged(authState));
    });
  }

  final FirebaseAuthService _authService;
  StreamSubscription<AuthState?>? _authSubscription;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final authState = await _authService.currentAuthState;
      if (authState != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: authState,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final authState = await _authService.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authState,
      ));
    } catch (e) {
      String errorMessage = 'An error occurred during sign in.';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = 'This account has been disabled.';
      } else if (e.toString().contains('invalid-claims')) {
        errorMessage = 'Account not properly configured. Please contact support.';
      }

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authService.signOut();
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to sign out.',
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final authState = await _authService.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        companyName: event.companyName,
        plan: event.plan,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authState,
      ));
    } catch (e) {
      String errorMessage = 'Failed to create account.';
      if (e.toString().contains('email-already-in-use') ||
          e.toString().contains('already exists')) {
        errorMessage = 'An account with this email already exists.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak.';
      } else if (e.toString().contains('VALIDATION_ERROR')) {
        // Extract validation message from backend
        final match = RegExp(r'message: ([^,\}]+)').firstMatch(e.toString());
        errorMessage = match?.group(1) ?? errorMessage;
      }

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    if (event.authState != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.authState,
      ));
    } else {
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
