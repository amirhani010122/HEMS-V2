import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/environment.dart';
import '../storage/secure_storage.dart';

/// Attaches the access token to every request and transparently refreshes it
/// on a 401, retrying the original request once before giving up.
class AuthInterceptor extends Interceptor {
  final Dio _dio;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  bool _isAuthPath(String path) {
    return path.contains(ApiConfig.login) ||
        path.contains(ApiConfig.register) ||
        path.contains(ApiConfig.refresh);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final shouldAttemptRefresh = response?.statusCode == 401 &&
        !_isAuthPath(requestOptions.path) &&
        requestOptions.extra['__retried__'] != true;

    if (!shouldAttemptRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await SecureStorage.clearAll();
      handler.next(err);
      return;
    }

    try {
      // Use a bare Dio (no interceptors) to avoid recursive refresh attempts.
      final bareDio = Dio(BaseOptions(baseUrl: EnvironmentConfig.baseUrl));
      final refreshResponse = await bareDio.post(
        ApiConfig.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = refreshResponse.data as Map<String, dynamic>;
      final newAccess =
          (data['access_token'] ?? data['accessToken'])?.toString();
      final newRefresh =
          (data['refresh_token'] ?? data['refreshToken'])?.toString();

      if (newAccess == null || newAccess.isEmpty) {
        await SecureStorage.clearAll();
        handler.next(err);
        return;
      }

      await SecureStorage.saveToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await SecureStorage.saveRefreshToken(newRefresh);
      }

      // Retry the original request once with the refreshed token.
      final retryOptions = Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $newAccess',
        },
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        extra: {...requestOptions.extra, '__retried__': true},
      );

      final retryResponse = await _dio.request(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: retryOptions,
      );

      handler.resolve(retryResponse);
    } catch (_) {
      await SecureStorage.clearAll();
      handler.next(err);
    }
  }
}
