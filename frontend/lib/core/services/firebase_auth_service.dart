import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/services/cloud_functions_service.dart';

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

/// Result of Google Sign-In indicating if user needs company setup
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.needsSetup,
    this.authState,
    this.email,
    this.displayName,
  });

  /// True if the user needs to complete company setup
  final bool needsSetup;

  /// Auth state if user has completed setup
  final AuthState? authState;

  /// User's email (available even if setup incomplete)
  final String? email;

  /// User's display name from Google
  final String? displayName;
}

/// Service for Firebase Authentication operations.
///
/// Handles sign-in, sign-out, and user state management.
/// Extracts custom claims (tenantId, role, permissions) from Firebase tokens.
@singleton
class FirebaseAuthService {
  FirebaseAuthService(this._auth, this._cloudFunctions);

  final FirebaseAuth _auth;
  final CloudFunctionsService _cloudFunctions;

  /// Google Sign-In instance (v7.x singleton API)
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  /// Stream of authentication state changes
  Stream<AuthState?> get authStateChanges =>
      _auth.authStateChanges().asyncMap(_mapUserToAuthState);

  /// Current user's Firebase User object
  User? get currentUser => _auth.currentUser;

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
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final authState = await _mapUserToAuthState(credential.user);
    if (authState == null) {
      throw FirebaseAuthException(
        code: 'invalid-claims',
        message: 'User does not have valid tenant or role claims.',
      );
    }

    return authState;
  }

  /// Sign up with email and password, creating a new tenant
  Future<AuthState> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
    String plan = 'starter',
  }) async {
    // Call the backend to create the user, tenant, and set claims
    final response = await _cloudFunctions.authSignUp(
      email: email,
      password: password,
      displayName: displayName,
      companyName: companyName,
      plan: plan,
      fromJson: SignUpResult.fromJson,
    );

    if (!response.success || response.data == null) {
      throw FirebaseAuthException(
        code: response.error?.code ?? 'signup-failed',
        message: response.error?.message ?? 'Failed to create account',
      );
    }

    // Sign in the user immediately after signup
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Force refresh to get the new custom claims
    await credential.user?.getIdToken(true);

    final authState = await _mapUserToAuthState(credential.user);
    if (authState == null) {
      throw FirebaseAuthException(
        code: 'invalid-claims',
        message: 'Account created but claims not set. Please try signing in.',
      );
    }

    return authState;
  }

  /// Initialize Google Sign-In (required for v7.x API)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// Sign in with Google account
  ///
  /// Returns a [GoogleSignInResult] indicating whether:
  /// - User is fully authenticated (has tenant) -> needsSetup = false
  /// - User needs to complete company setup -> needsSetup = true
  Future<GoogleSignInResult> signInWithGoogle() async {
    User? user;

    if (kIsWeb) {
      // On web, use Firebase Auth's built-in popup sign-in
      // This properly handles Google Identity Services (GIS)
      final provider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithPopup(provider);
      user = userCredential.user;
    } else {
      // On mobile platforms, use google_sign_in package
      // Initialize Google Sign-In if not already done (v7.x requirement)
      await _ensureGoogleSignInInitialized();

      // Trigger the Google Sign-In flow (v7.x API uses authenticate())
      final googleAccount = await _googleSignIn.authenticate();

      // Get authentication tokens from the account
      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;

      // For Firebase, we primarily need the idToken
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-signin-failed',
          message: 'Failed to obtain Google ID token',
        );
      }

      // Create a credential from the Google auth tokens
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      user = userCredential.user;
    }

    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Failed to sign in with Google',
      );
    }

    // Check if user has a tenant set up
    final authState = await _mapUserToAuthState(user);

    if (authState != null) {
      // User has completed setup
      return GoogleSignInResult(
        needsSetup: false,
        authState: authState,
        email: user.email,
        displayName: user.displayName,
      );
    }

    // User needs to complete company setup
    return GoogleSignInResult(
      needsSetup: true,
      email: user.email,
      displayName: user.displayName,
    );
  }

  /// Complete Google Sign-In by setting up the company/tenant
  ///
  /// Call this after [signInWithGoogle] returns needsSetup = true
  Future<AuthState> completeGoogleSignUp({
    required String companyName,
    String plan = 'starter',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No signed-in user. Please sign in with Google first.',
      );
    }

    // Call backend to create tenant and set claims
    final response = await _cloudFunctions.authCompleteGoogleSignUp(
      companyName: companyName,
      plan: plan,
      fromJson: SignUpResult.fromJson,
    );

    if (!response.success || response.data == null) {
      throw FirebaseAuthException(
        code: response.error?.code ?? 'setup-failed',
        message: response.error?.message ?? 'Failed to complete account setup',
      );
    }

    // Force refresh the token to get the new claims
    await user.getIdToken(true);

    // Get the updated auth state
    final authState = await _mapUserToAuthState(user);
    if (authState == null) {
      throw FirebaseAuthException(
        code: 'invalid-claims',
        message: 'Setup completed but claims not set. Please try signing in again.',
      );
    }

    return authState;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    // Sign out from Google if initialized (v7.x API)
    if (_googleSignInInitialized) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  /// Get the current ID token for API calls
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  /// Force refresh the ID token (useful after claim changes)
  Future<void> refreshToken() async {
    await _auth.currentUser?.getIdToken(true);
  }

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
      if (tenantId == null || roleStr == null) {
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
      // Handle invalid refresh token by signing out
      if (e.code == 'invalid-refresh-token' ||
          e.code == 'network-request-failed') {
        await signOut();
      }
      return null;
    } catch (e) {
      // For any other errors, just return null
      return null;
    }
  }
}
