class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired. Please login again.', statusCode: 401);
}

class NetworkException extends AppException {
  const NetworkException() : super('No internet connection. Please check your network.');
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class NotFoundException extends AppException {
  const NotFoundException([String msg = 'Resource not found'])
      : super(msg, statusCode: 404);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode});
}
