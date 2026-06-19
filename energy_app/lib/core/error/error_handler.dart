import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (error is AppException) return error;
    return AppException(error.toString());
  }

  static AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'An error occurred';

        if (data is Map) {
          message = data['detail']?.toString() ??
              data['message']?.toString() ??
              message;
        }

        if (statusCode == 401) return const UnauthorizedException();
        if (statusCode == 404) return NotFoundException(message);
        if (statusCode == 422) return ValidationException(message, statusCode: statusCode);
        return ServerException(message, statusCode: statusCode);
      default:
        return const AppException('Unexpected error occurred');
    }
  }
}
