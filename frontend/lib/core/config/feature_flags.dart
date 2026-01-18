import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sfdify_scm/core/config/firebase_config.dart';

/// Feature flag service using Firebase Remote Config.
///
/// Controls gradual rollout of Firebase backend features during migration.
/// Allows instant rollback by toggling flags remotely (< 5 minutes).
///
/// Migration strategy:
/// - Start with all flags disabled (use Django backend)
/// - Enable per module with percentage-based rollout
/// - Increase rollout gradually: 5% → 25% → 50% → 100%
/// - Instant rollback by setting percentage to 0
///
/// Note: In emulator mode, all Firebase features are enabled by default
/// since Remote Config doesn't have an emulator.
@singleton
class FeatureFlags {
  final FirebaseRemoteConfig _remoteConfig;
  final Logger _logger;

  /// In emulator mode, bypass Remote Config and use hardcoded values
  final bool _isEmulatorMode = FirebaseConfig.useEmulator;

  FeatureFlags(
    this._remoteConfig,
    this._logger,
  );

  /// Initialize Remote Config with defaults and fetch latest values.
  Future<void> initialize() async {
    // In emulator mode, skip Remote Config (no emulator available)
    // All Firebase features are enabled by default
    if (_isEmulatorMode) {
      _logger.i('Feature flags: Emulator mode - all Firebase features enabled');
      _logCurrentFlags();
      return;
    }

    try {
      // Set configuration settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      // Set default values (used when Remote Config fetch fails)
      // In production, Firebase auth is enabled by default for reliability
      await _remoteConfig.setDefaults({
        'use_firebase_auth': true,
        'use_firebase_disputes': true,
        'use_firebase_consumers': true,
        'use_firebase_letters': true,
        'firebase_rollout_pct': 100,
        'firebase_user_whitelist': '',
      });

      // Fetch and activate latest values
      final activated = await _remoteConfig.fetchAndActivate();

      _logger.i('Feature flags initialized (activated: $activated)');
      _logCurrentFlags();
    } catch (e) {
      _logger.e('Failed to initialize feature flags', error: e);
      // Continue with defaults if fetch fails
    }
  }

  /// Whether to use Firebase Authentication instead of Django JWT.
  ///
  /// When false: Use existing Django JWT authentication
  /// When true: Use Firebase Authentication with custom claims
  bool get useFirebaseAuth {
    if (_isEmulatorMode) return true;
    return _remoteConfig.getBool('use_firebase_auth');
  }

  /// Whether to use Firebase backend for disputes module.
  ///
  /// When false: Use Django REST API endpoints
  /// When true: Use Firebase Cloud Functions
  bool get useFirebaseForDisputes {
    if (_isEmulatorMode) return true;
    return _remoteConfig.getBool('use_firebase_disputes');
  }

  /// Whether to use Firebase backend for consumers module.
  bool get useFirebaseForConsumers {
    if (_isEmulatorMode) return true;
    return _remoteConfig.getBool('use_firebase_consumers');
  }

  /// Whether to use Firebase backend for letters module.
  bool get useFirebaseForLetters {
    if (_isEmulatorMode) return true;
    return _remoteConfig.getBool('use_firebase_letters');
  }

  /// Percentage of users in Firebase rollout (0-100).
  ///
  /// Used for gradual canary deployment:
  /// - 0: No users on Firebase (all on Django)
  /// - 5: 5% of users on Firebase
  /// - 25: 25% of users on Firebase
  /// - 50: 50% of users on Firebase
  /// - 100: All users on Firebase
  int get firebaseRolloutPercentage {
    if (_isEmulatorMode) return 100;
    final value = _remoteConfig.getInt('firebase_rollout_pct');
    return value.clamp(0, 100);
  }

  /// Comma-separated list of user IDs to force into Firebase rollout.
  ///
  /// Used for testing specific users regardless of percentage.
  /// Format: "userId1,userId2,userId3"
  String get firebaseUserWhitelist {
    if (_isEmulatorMode) return '';
    return _remoteConfig.getString('firebase_user_whitelist');
  }

  /// Check if a specific user should use Firebase backend.
  ///
  /// Decision logic:
  /// 1. If user ID is in whitelist → use Firebase
  /// 2. Otherwise, use hash-based percentage check
  ///
  /// Hash-based approach ensures:
  /// - Same user always gets same result (consistent experience)
  /// - Even distribution across user base
  Future<bool> isUserInFirebaseRollout(String userId) async {
    try {
      // Refresh flags periodically
      await _refreshIfNeeded();

      // Check whitelist first
      final whitelist = firebaseUserWhitelist;
      if (whitelist.isNotEmpty) {
        final whitelistIds = whitelist.split(',').map((id) => id.trim());
        if (whitelistIds.contains(userId)) {
          _logger.d('User $userId in Firebase whitelist');
          return true;
        }
      }

      // Use percentage-based rollout
      final percentage = firebaseRolloutPercentage;
      if (percentage == 0) {
        return false;
      }
      if (percentage == 100) {
        return true;
      }

      // Hash user ID to get consistent but distributed result
      final hash = userId.hashCode.abs();
      final bucket = hash % 100;
      final inRollout = bucket < percentage;

      _logger.d(
        'User $userId rollout check: bucket=$bucket, percentage=$percentage, '
        'inRollout=$inRollout',
      );

      return inRollout;
    } catch (e) {
      _logger.e('Error checking Firebase rollout for user', error: e);
      // Default to false (use Django) on error
      return false;
    }
  }

  /// Manually refresh feature flags (respects minimum fetch interval).
  Future<void> refresh() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      _logger.i('Feature flags refreshed (activated: $activated)');
      _logCurrentFlags();
    } catch (e) {
      _logger.e('Failed to refresh feature flags', error: e);
    }
  }

  /// Internal: Refresh if minimum interval has passed.
  Future<void> _refreshIfNeeded() async {
    try {
      // This will respect the minimumFetchInterval setting
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
    } catch (e) {
      // Silently fail - not critical
      _logger.w('Feature flag refresh failed', error: e);
    }
  }

  /// Log current flag values for debugging.
  void _logCurrentFlags() {
    final mode = _isEmulatorMode ? ' (EMULATOR MODE)' : '';
    _logger.d('''
Feature Flags$mode:
  - use_firebase_auth: $useFirebaseAuth
  - use_firebase_disputes: $useFirebaseForDisputes
  - use_firebase_consumers: $useFirebaseForConsumers
  - use_firebase_letters: $useFirebaseForLetters
  - firebase_rollout_pct: $firebaseRolloutPercentage%
  - firebase_user_whitelist: ${firebaseUserWhitelist.isEmpty ? "(empty)" : firebaseUserWhitelist}
''');
  }

  /// Get all flag values as a map (for debugging).
  Map<String, dynamic> getAllFlags() {
    return {
      'use_firebase_auth': useFirebaseAuth,
      'use_firebase_disputes': useFirebaseForDisputes,
      'use_firebase_consumers': useFirebaseForConsumers,
      'use_firebase_letters': useFirebaseForLetters,
      'firebase_rollout_pct': firebaseRolloutPercentage,
      'firebase_user_whitelist': firebaseUserWhitelist,
    };
  }
}
