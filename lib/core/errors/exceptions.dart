class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Server error. Please try again later.',
  ]);
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'Request timed out. Please try again.',
  ]);
}

class NoInternetException extends AppException {
  const NoInternetException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expired. Please login again.',
  ]);
}

class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Unexpected error occurred. Please try again.',
  ]);
}

class CacheException extends AppException {
  const CacheException([
    super.message = 'Local cache error. Please try again.',
  ]);
}
