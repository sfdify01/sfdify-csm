import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
