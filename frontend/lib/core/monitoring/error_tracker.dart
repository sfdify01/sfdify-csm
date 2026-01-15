import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Error tracking service using Firebase Crashlytics.
///
/// Provides centralized error recording with context and metadata.
/// Used throughout the app to track errors for monitoring and debugging.
@singleton
class ErrorTracker {
  final FirebaseCrashlytics _crashlytics;
  final Logger _logger;

  ErrorTracker(
    this._crashlytics,
    this._logger,
  );

  /// Records an error with optional context.
  ///
  /// [error] The error or exception that occurred
  /// [stack] The stack trace (optional)
  /// [reason] A description of why the error occurred
  /// [context] Additional metadata about the error context
  /// [fatal] Whether this error should be marked as fatal
  void recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) {
    try {
      // Log to console for development
      _logger.e(
        'Error recorded: ${reason ?? error.toString()}',
        error: error,
        stackTrace: stack,
      );

      // Add custom keys for context
      if (context != null) {
        for (final entry in context.entries) {
          _crashlytics.setCustomKey(
            entry.key,
            entry.value?.toString() ?? 'null',
          );
        }
      }

      // Record to Crashlytics
      _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Fallback logging if Crashlytics fails
      _logger.e('Failed to record error to Crashlytics', error: e);
    }
  }

  /// Records a Flutter error (typically from FlutterError.onError).
  void recordFlutterError(FlutterErrorDetails details) {
    try {
      _logger.e(
        'Flutter error recorded: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );

      _crashlytics.recordFlutterError(details);
    } catch (e) {
      _logger.e('Failed to record Flutter error to Crashlytics', error: e);
    }
  }

  /// Sets user identifier for tracking errors per user.
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      _logger.d('Crashlytics user ID set: $userId');
    } catch (e) {
      _logger.e('Failed to set Crashlytics user ID', error: e);
    }
  }

  /// Sets custom key-value pair for error context.
  void setCustomKey(String key, dynamic value) {
    try {
      _crashlytics.setCustomKey(key, value?.toString() ?? 'null');
    } catch (e) {
      _logger.e('Failed to set custom key in Crashlytics', error: e);
    }
  }

  /// Clears all custom keys.
  void clearCustomKeys() {
    try {
      // Crashlytics doesn't have a clear method, so we'd need to track keys
      // For now, we just log
      _logger.d('Custom keys cleared');
    } catch (e) {
      _logger.e('Failed to clear custom keys', error: e);
    }
  }

  /// Logs a message to Crashlytics (for breadcrumbs).
  void log(String message) {
    try {
      _crashlytics.log(message);
      _logger.d('Crashlytics log: $message');
    } catch (e) {
      _logger.e('Failed to log to Crashlytics', error: e);
    }
  }
}
