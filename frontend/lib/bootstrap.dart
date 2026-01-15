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
import 'package:sfdify_scm/core/config/feature_flags.dart';
import 'package:sfdify_scm/core/config/firebase_config.dart';
import 'package:sfdify_scm/firebase_options.dart';
import 'package:sfdify_scm/injection/injection.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase emulators for local development
  if (FirebaseConfig.useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.authEmulatorPort,
    );

    FirebaseFunctions.instance.useFunctionsEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.functionsEmulatorPort,
    );

    await FirebaseStorage.instance.useStorageEmulator(
      FirebaseConfig.emulatorHost,
      FirebaseConfig.storageEmulatorPort,
    );
  }

  // Initialize Crashlytics error handling
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
