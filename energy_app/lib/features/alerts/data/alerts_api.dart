import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/alert_model.dart';

class AlertsApi {
  final Dio _dio = DioClient.instance;

  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await _dio.get(ApiConfig.alerts);
      final list = response.data as List;
      return list.map((e) => AlertModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final alertsApiProvider = Provider((_) => AlertsApi());

final alertsProvider = FutureProvider<List<AlertModel>>((ref) {
  return ref.watch(alertsApiProvider).getAlerts();
});
