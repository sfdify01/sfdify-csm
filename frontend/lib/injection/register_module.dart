import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfdify_scm/core/config/firebase_config.dart';
import 'package:sfdify_scm/core/network/api_interceptor.dart';
import 'package:sfdify_scm/core/network/dio_client.dart';
import 'package:sfdify_scm/core/router/app_router.dart';

@module
abstract class RegisterModule {
  @singleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 75,
          colors: true,
          printEmojis: true,
        ),
      );

  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @singleton
  AppRouter get appRouter => AppRouter();

  @singleton
  Dio dio(Logger logger) {
    return DioClient.createDio(
      interceptors: [
        LoggingInterceptor(logger: logger),
        ApiInterceptor(logger: logger),
      ],
    );
  }

  @singleton
  DioClient dioClient(Dio dio) => DioClient(dio: dio);

  // Firebase Services (singletons)
  // Note: Firebase must be initialized in bootstrap.dart before DI setup

  @singleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @singleton
  FirebaseFunctions get firebaseFunctions =>
      FirebaseFunctions.instanceFor(region: FirebaseConfig.region);

  @singleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;

  @singleton
  FirebaseAnalytics get firebaseAnalytics => FirebaseAnalytics.instance;

  @singleton
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @singleton
  FirebaseRemoteConfig get remoteConfig => FirebaseRemoteConfig.instance;
}
