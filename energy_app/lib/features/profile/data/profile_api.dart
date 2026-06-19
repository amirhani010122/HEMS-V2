import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/user_model.dart';

class ProfileApi {
  final Dio _dio = DioClient.instance;

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.me);
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
