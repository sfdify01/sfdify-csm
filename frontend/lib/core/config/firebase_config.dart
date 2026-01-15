/// Firebase configuration for different environments.
///
/// Provides environment-specific settings for:
/// - Cloud Functions URLs
/// - Emulator configuration
/// - Region settings
///
/// Environments:
/// - dev: Local Firebase emulators
/// - staging: Firebase staging project
/// - prod: Firebase production project
abstract class FirebaseConfig {
  /// Cloud Functions region.
  static const String region = 'us-central1';

  /// Cloud Functions base URL based on environment.
  static String get functionsUrl {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        return 'http://127.0.0.1:5001/sfdify-dev/us-central1';
      case Environment.staging:
        return 'https://us-central1-sfdify-staging.cloudfunctions.net';
      case Environment.prod:
        return 'https://us-central1-sfdify-production.cloudfunctions.net';
    }
  }

  /// Whether to use Firebase emulators.
  static bool get useEmulator => EnvironmentConfig.current == Environment.dev;

  /// Firebase emulator host.
  static const String emulatorHost = '127.0.0.1';

  /// Firebase Auth emulator port.
  static const int authEmulatorPort = 9099;

  /// Cloud Functions emulator port.
  static const int functionsEmulatorPort = 5001;

  /// Cloud Firestore emulator port.
  static const int firestoreEmulatorPort = 8080;

  /// Cloud Storage emulator port.
  static const int storageEmulatorPort = 9199;
}

/// Application environment.
enum Environment {
  /// Local development with Firebase emulators.
  dev,

  /// Staging environment (for testing before production).
  staging,

  /// Production environment (live users).
  prod,
}

/// Environment configuration.
///
/// Determines current environment from build-time constant.
/// Set via: flutter run --dart-define=ENV=staging
abstract class EnvironmentConfig {
  /// Current environment.
  ///
  /// Determined by --dart-define=ENV compile-time constant.
  /// Defaults to 'dev' if not specified.
  static Environment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env.toLowerCase()) {
      case 'staging':
      case 'stg':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.prod;
      case 'development':
      case 'dev':
      default:
        return Environment.dev;
    }
  }

  /// Environment name as string.
  static String get name {
    switch (current) {
      case Environment.dev:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.prod:
        return 'production';
    }
  }

  /// Whether running in development environment.
  static bool get isDevelopment => current == Environment.dev;

  /// Whether running in staging environment.
  static bool get isStaging => current == Environment.staging;

  /// Whether running in production environment.
  static bool get isProduction => current == Environment.prod;
}
