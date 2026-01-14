import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiInterceptor extends Interceptor {
  ApiInterceptor({
    required this.logger,
    this.getToken,
  });

  final Logger logger;
  final Future<String?> Function()? getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    if (getToken != null) {
      final token = await getToken!();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add common headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    logger.d(
      'REQUEST[${options.method}] => PATH: ${options.path}\n'
      'Headers: ${options.headers}\n'
      'Data: ${options.data}',
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logger.d(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n'
      'Data: ${response.data}',
    );

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n'
      'Message: ${err.message}',
    );

    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.logger});

  final Logger logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.i('🚀 Request: ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logger.i(
      '✅ Response: ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      '❌ Error: ${err.response?.statusCode} ${err.requestOptions.uri}',
    );
    handler.next(err);
  }
}
