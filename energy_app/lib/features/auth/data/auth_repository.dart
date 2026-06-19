import '../../../core/storage/secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api = AuthApi();

  Future<TokenResponse> login(String email, String password) async {
    final token = await _api.login(UserLogin(email: email, password: password));
    await SecureStorage.saveToken(token.accessToken);
    if (token.refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(token.refreshToken);
    }
    return token;
  }

  Future<UserModel> register(String email, String username, String password) {
    return _api.register(UserRegister(
      email: email,
      username: username,
      password: password,
    ));
  }

  Future<void> logout() async {
    // Best-effort: tell the backend to revoke the refresh token. Never let a
    // network/server error block the local sign-out.
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      await _api.logout(refreshToken);
    } catch (_) {
      // ignore
    }
    await SecureStorage.clearAll();
    DioClient.reset();
  }

  Future<bool> isAuthenticated() => SecureStorage.hasToken();
}
