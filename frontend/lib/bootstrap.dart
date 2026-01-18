import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ustaxx_csm/core/config/feature_flags.dart';
import 'package:ustaxx_csm/core/config/firebase_config.dart';
import 'package:ustaxx_csm/firebase_options.dart';
import 'package:ustaxx_csm/injection/injection.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase emulators for local development
  debugPrint('[Bootstrap] Environment: ${EnvironmentConfig.name}, useEmulator: ${FirebaseConfig.useEmulator}');
  if (FirebaseConfig.useEmulator) {
    debugPrint('[Bootstrap] Configuring Firebase emulators...');
    debugPrint('[Bootstrap] Auth emulator: ${FirebaseConfig.emulatorHost}:${FirebaseConfig.authEmulatorPort}');
    await FirebaseAuth.instance.useAuthEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.authEmulatorPort,
    );

    // Configure the regional instance (same as used in register_module.dart)
    debugPrint('[Bootstrap] Functions emulator: ${FirebaseConfig.emulatorHost}:${FirebaseConfig.functionsEmulatorPort} (region: ${FirebaseConfig.region})');
    FirebaseFunctions.instanceFor(region: FirebaseConfig.region)
        .useFunctionsEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.functionsEmulatorPort,
    );

    debugPrint('[Bootstrap] Storage emulator: ${FirebaseConfig.emulatorHost}:${FirebaseConfig.storageEmulatorPort}');
    await FirebaseStorage.instance.useStorageEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.storageEmulatorPort,
    );
    debugPrint('[Bootstrap] All emulators configured successfully');
  }

  // Initialize Crashlytics error handling (only on supported platforms)
  // Crashlytics is not supported on web or in emulator mode
  if (!kIsWeb && !FirebaseConfig.useEmulator) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // For web and emulator, just log errors to console
    FlutterError.onError = (errorDetails) {
      // Filter out known Flutter web trackpad gesture assertion errors
      final errorString = errorDetails.exception.toString();
      if (errorString.contains('PointerDeviceKind.trackpad') ||
          errorString.contains('isCrashlyticsCollectionEnabled')) {
        // Ignore known development/web platform issues
        return;
      }
      debugPrint('Flutter error: ${errorDetails.exception}');
      debugPrint('Stack trace: ${errorDetails.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // Filter out known Flutter web trackpad gesture assertion errors
      final errorString = error.toString();
      if (errorString.contains('PointerDeviceKind.trackpad') ||
          errorString.contains('isCrashlyticsCollectionEnabled')) {
        // Ignore known development/web platform issues
        return true;
      }
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
      return true;
    };
  }

  // Initialize Hive for web
  await Hive.initFlutter();

  // Initialize HydratedBloc storage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory.web,
  );

  // Configure dependencies
  await configureDependencies();

  // Initialize Remote Config feature flags (after DI setup)
  try {
    final featureFlags = getIt<FeatureFlags>();
    await featureFlags.initialize();
  } catch (e) {
    // Log but don't fail - feature flags are not critical for startup
    debugPrint('Failed to initialize feature flags: $e');
  }

  runApp(await builder());
}
