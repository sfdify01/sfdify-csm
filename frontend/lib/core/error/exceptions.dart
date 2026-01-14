class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  const CacheException({required this.message});

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException({required this.message});

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException({this.message = 'Unauthorized'});

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}
