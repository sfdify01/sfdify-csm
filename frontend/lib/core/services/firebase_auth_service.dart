import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';

/// User role types matching backend
enum UserRole { owner, operator, viewer, auditor }

/// Authentication state representing the current user
class AuthState {
  const AuthState({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.permissions,
    this.displayName,
  });

  final String userId;
  final String tenantId;
  final String email;
  final UserRole role;
  final List<String> permissions;
  final String? displayName;

  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  String toString() => 'AuthState(userId: $userId, tenantId: $tenantId, role: $role)';
}

/// Result of signup operations
class SignUpResult {
  const SignUpResult({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String tenantId;
  final String email;
  final String displayName;
  final String role;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      userId: json['userId'] as String,
      tenantId: json['tenantId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }
}

/// Custom exception for auth-related errors
class AuthServiceException implements Exception {
  const AuthServiceException({
    required this.code,
    required this.message,
    this.originalError,
  });

  final String code;
  final String message;
  final Object? originalError;

  @override
  String toString() => 'AuthServiceException($code): $message';
}

/// Service for Firebase Authentication operations.
///
/// Handles sign-in, sign-out, and user state management.
/// Extracts custom claims (tenantId, role, permissions) from Firebase tokens.
@singleton
class FirebaseAuthService {
  FirebaseAuthService(
    this._auth,
    this._cloudFunctions,
    this._logger,
  );

  final FirebaseAuth _auth;
  final CloudFunctionsService _cloudFunctions;
  final Logger _logger;

  /// Maximum retries for token operations
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff (milliseconds)
  static const int _baseDelayMs = 500;

  /// Stream of authentication state changes
  Stream<AuthState?> get authStateChanges =>
      _auth.authStateChanges().asyncMap(_mapUserToAuthState);

  /// Stream of ID token changes (fires when token is refreshed)
  Stream<AuthState?> get idTokenChanges =>
      _auth.idTokenChanges().asyncMap(_mapUserToAuthState);

  /// Current user's Firebase User object
  User? get currentUser => _auth.currentUser;

  /// Check if user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Current authentication state
  Future<AuthState?> get currentAuthState async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapUserToAuthState(user);
  }

  /// Sign in with email and password
  Future<AuthState> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _logger.i('Attempting sign in for: $email');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthServiceException(
          code: 'user-null',
          message: 'Sign in succeeded but user is null.',
        );
      }

      // Force refresh token to get latest claims
      await credential.user!.getIdToken(true);

      final authState = await _mapUserToAuthState(credential.user);
      if (authState == null) {
        _logger.w('User signed in but missing custom claims');
        throw const AuthServiceException(
          code: 'invalid-claims',
          message:
              'Your account is not properly configured. Please contact support.',
        );
      }

      _logger.i('Sign in successful for user: ${authState.userId}');
      return authState;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase auth error during sign in', error: e);
      throw _mapFirebaseAuthException(e);
    } on AuthServiceException {
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during sign in', error: e);
      throw AuthServiceException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  /// Sign up with email and password, creating a new tenant
  Future<AuthState> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
  }) async {
    _logger.i('Attempting signup for: $email, company: $companyName');

    try {
      // Call the backend to create the user, tenant, and set claims
      final response = await _cloudFunctions.authSignUp(
        email: email.trim().toLowerCase(),
        password: password,
        displayName: displayName.trim(),
        companyName: companyName.trim(),
        fromJson: SignUpResult.fromJson,
      );

      if (!response.success || response.data == null) {
        _logger.e('Signup failed: ${response.error?.message}');
        throw AuthServiceException(
          code: response.error?.code ?? 'signup-failed',
          message: response.error?.message ?? 'Failed to create account.',
        );
      }

      _logger.i('Signup backend call succeeded, signing in user');

      // Sign in the user immediately after signup
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Force refresh to get the new custom claims with retry
      await _refreshTokenWithRetry(credential.user);

      final authState = await _mapUserToAuthState(credential.user);
      if (authState == null) {
        _logger.w('User created but claims not properly set');
        // Claims might not have propagated yet, try one more time after delay
        await Future.delayed(const Duration(seconds: 1));
        await credential.user?.getIdToken(true);
        final retryState = await _mapUserToAuthState(credential.user);
        if (retryState == null) {
          throw const AuthServiceException(
            code: 'claims-not-set',
            message:
                'Account created but setup is incomplete. Please try signing in.',
          );
        }
        return retryState;
      }

      _logger.i('Signup complete for user: ${authState.userId}');
      return authState;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase auth error during signup', error: e);
      throw _mapFirebaseAuthException(e);
    } on AuthServiceException {
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during signup', error: e);
      throw AuthServiceException(
        code: 'unknown',
        message: 'Failed to create account. Please try again.',
        originalError: e,
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _logger.i('Signing out user');
    try {
      await _auth.signOut();
      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Error during sign out', error: e);
      // Still throw to let UI know, but user is effectively signed out
      rethrow;
    }
  }

  /// Get the current ID token for API calls
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      _logger.e('Error getting ID token', error: e);
      if (forceRefresh) {
        // If force refresh fails, try without refresh
        try {
          return await _auth.currentUser?.getIdToken(false);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  /// Force refresh the ID token with retry logic
  Future<void> refreshToken() async {
    await _refreshTokenWithRetry(_auth.currentUser);
  }

  /// Refresh token with exponential backoff retry
  Future<void> _refreshTokenWithRetry(User? user) async {
    if (user == null) return;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await user.getIdToken(true);
        return;
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          _logger.e('Token refresh failed after $_maxRetries attempts', error: e);
          rethrow;
        }
        final delay = _baseDelayMs * (1 << attempt); // Exponential backoff
        _logger.w('Token refresh attempt ${attempt + 1} failed, retrying in ${delay}ms');
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _logger.i('Sending password reset email to: $email');
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      _logger.i('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      _logger.e('Error sending password reset email', error: e);
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Reload the current user's data from Firebase
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _logger.w('Error reloading user', error: e);
    }
  }

  /// Check if the current user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Map Firebase User to AuthState with custom claims
  Future<AuthState?> _mapUserToAuthState(User? user) async {
    if (user == null) return null;

    try {
      // Get the ID token result to access custom claims
      final tokenResult = await user.getIdTokenResult();
      final claims = tokenResult.claims;

      final tenantId = claims?['tenantId'] as String?;
      final roleStr = claims?['role'] as String?;
      final permissionsList = claims?['permissions'] as List<dynamic>?;

      // User must have tenantId and role claims
      if (tenantId == null || tenantId.isEmpty) {
        _logger.w('User ${user.uid} missing tenantId claim');
        return null;
      }

      if (roleStr == null || roleStr.isEmpty) {
        _logger.w('User ${user.uid} missing role claim');
        return null;
      }

      // Parse role
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.viewer,
      );

      // Parse permissions
      final permissions =
          permissionsList?.map((p) => p.toString()).toList() ?? [];

      return AuthState(
        userId: user.uid,
        tenantId: tenantId,
        email: user.email ?? '',
        role: role,
        permissions: permissions,
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Error mapping user to auth state', error: e);
      // Handle invalid refresh token by signing out
      if (e.code == 'invalid-refresh-token' ||
          e.code == 'user-token-expired' ||
          e.code == 'user-disabled') {
        await signOut();
      }
      return null;
    } catch (e) {
      _logger.e('Unexpected error mapping user to auth state', error: e);
      return null;
    }
  }

  /// Map Firebase auth exceptions to user-friendly AuthServiceException
  AuthServiceException _mapFirebaseAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      // Sign in errors
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Invalid email or password. Please try again.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      'too-many-requests' => 'Too many failed attempts. Please try again later.',

      // Sign up errors
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password is too weak. Please use a stronger password.',
      'operation-not-allowed' => 'Email/password sign up is not enabled.',

      // Token/session errors
      'invalid-refresh-token' => 'Your session has expired. Please sign in again.',
      'user-token-expired' => 'Your session has expired. Please sign in again.',
      'requires-recent-login' => 'Please sign in again to complete this action.',

      // Network errors
      'network-request-failed' => 'Network error. Please check your connection and try again.',

      // Default
      _ => e.message ?? 'An authentication error occurred. Please try again.',
    };

    return AuthServiceException(
      code: e.code,
      message: message,
      originalError: e,
    );
  }
}
