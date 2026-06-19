import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/user_model.dart';

class AuthApi {
  final Dio _dio = DioClient.instance;

  Future<TokenResponse> login(UserLogin data) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': data.email,
          'password': data.password,
        },
      );
      return TokenResponse.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<UserModel> register(UserRegister data) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'email': data.email,
          'username': data.username,
          'password': data.password,
        },
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Best-effort backend logout. Sends the refresh token so the server can
  /// revoke it; the caller clears local storage regardless of the outcome.
  Future<void> logout(String? refreshToken) async {
    await _dio.post(
      ApiConfig.logout,
      data: refreshToken != null ? {'refresh_token': refreshToken} : {},
    );
  }
}
