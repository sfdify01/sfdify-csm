import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Analytics service using Firebase Analytics.
///
/// Provides centralized event logging for tracking user behavior,
/// API performance, and migration metrics (Firebase vs Django comparison).
@singleton
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final Logger _logger;

  AnalyticsService(
    this._analytics,
    this._logger,
  );

  /// Logs an API call event with performance metrics.
  ///
  /// Used to compare Firebase vs Django backend performance during migration.
  ///
  /// [endpoint] The API endpoint or function name
  /// [success] Whether the call succeeded
  /// [responseTime] Response time in milliseconds
  /// [backend] Which backend was used ('firebase' or 'django')
  /// [statusCode] HTTP status code (optional)
  Future<void> logApiCall(
    String endpoint,
    bool success,
    int responseTime, {
    String backend = 'firebase',
    int? statusCode,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'api_call',
        parameters: {
          'endpoint': endpoint,
          'success': success,
          'response_time_ms': responseTime,
          'backend': backend,
          if (statusCode != null) 'status_code': statusCode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d(
        'Analytics: API call - $endpoint (backend: $backend, '
        'success: $success, ${responseTime}ms)',
      );
    } catch (e) {
      _logger.e('Failed to log API call analytics', error: e);
    }
  }

  /// Logs a screen view event.
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );

      _logger.d('Analytics: Screen view - $screenName');
    } catch (e) {
      _logger.e('Failed to log screen view', error: e);
    }
  }

  /// Logs user login event.
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(
        loginMethod: method ?? 'email',
      );

      _logger.d('Analytics: Login - method: $method');
    } catch (e) {
      _logger.e('Failed to log login', error: e);
    }
  }

  /// Logs user signup event.
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(
        signUpMethod: method ?? 'email',
      );

      _logger.d('Analytics: Sign up - method: $method');
    } catch (e) {
      _logger.e('Failed to log sign up', error: e);
    }
  }

  /// Logs a custom event with optional parameters.
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters?.cast<String, Object>(),
      );

      _logger.d('Analytics: Event - $eventName (params: $parameters)');
    } catch (e) {
      _logger.e('Failed to log custom event', error: e);
    }
  }

  /// Logs a dispute-related event.
  Future<void> logDisputeEvent(
    String action, {
    String? disputeId,
    String? bureau,
    String? status,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'dispute_$action',
        parameters: {
          if (disputeId != null) 'dispute_id': disputeId,
          if (bureau != null) 'bureau': bureau,
          if (status != null) 'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d('Analytics: Dispute $action - $disputeId');
    } catch (e) {
      _logger.e('Failed to log dispute event', error: e);
    }
  }

  /// Logs a consumer-related event.
  Future<void> logConsumerEvent(
    String action, {
    String? consumerId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'consumer_$action',
        parameters: {
          if (consumerId != null) 'consumer_id': consumerId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d('Analytics: Consumer $action - $consumerId');
    } catch (e) {
      _logger.e('Failed to log consumer event', error: e);
    }
  }

  /// Logs a letter generation event.
  Future<void> logLetterEvent(
    String action, {
    String? letterId,
    String? disputeId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'letter_$action',
        parameters: {
          if (letterId != null) 'letter_id': letterId,
          if (disputeId != null) 'dispute_id': disputeId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d('Analytics: Letter $action - $letterId');
    } catch (e) {
      _logger.e('Failed to log letter event', error: e);
    }
  }

  /// Sets user ID for analytics.
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logger.d('Analytics user ID set: $userId');
    } catch (e) {
      _logger.e('Failed to set analytics user ID', error: e);
    }
  }

  /// Sets user property.
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logger.d('Analytics user property set: $name = $value');
    } catch (e) {
      _logger.e('Failed to set user property', error: e);
    }
  }

  /// Logs an error event.
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    bool fatal = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          if (stackTrace != null) 'stack_trace': stackTrace,
          'fatal': fatal,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d('Analytics: Error - $errorType: $errorMessage');
    } catch (e) {
      _logger.e('Failed to log error event', error: e);
    }
  }

  /// Logs feature flag change event (for tracking migration rollout).
  Future<void> logFeatureFlagChange({
    required String flagName,
    required bool enabled,
    String? userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'feature_flag_change',
        parameters: {
          'flag_name': flagName,
          'enabled': enabled,
          if (userId != null) 'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.d('Analytics: Feature flag $flagName = $enabled');
    } catch (e) {
      _logger.e('Failed to log feature flag change', error: e);
    }
  }
}
