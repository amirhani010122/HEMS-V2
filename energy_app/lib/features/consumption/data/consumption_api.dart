import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/consumption_model.dart';

class ConsumptionApi {
  final Dio _dio = DioClient.instance;

  Future<ConsumptionResponse> createConsumption(ConsumptionCreate data) async {
    try {
      final response = await _dio.post(ApiConfig.consumptionCreate, data: {
        'device_id': data.deviceId,
        'consumption_value': data.consumptionValue,
        'timestamp': data.timestamp.toIso8601String(),
      });
      return ConsumptionResponse.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<DailyConsumption>> getDaily() async {
    try {
      final response = await _dio.get(ApiConfig.consumptionDaily);
      final list = response.data as List;
      return list.map((e) => DailyConsumption.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<MonthlyConsumption>> getMonthly() async {
    try {
      final response = await _dio.get(ApiConfig.consumptionMonthly);
      final list = response.data as List;
      return list.map((e) => MonthlyConsumption.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ConsumptionSummary> getSummary() async {
    try {
      final response = await _dio.get(ApiConfig.consumptionSummary);
      return ConsumptionSummary.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<DeviceDailyConsumption>> getPerDeviceDaily() async {
    try {
      final response = await _dio.get(ApiConfig.consumptionPerDeviceDaily);
      final list = response.data as List;
      return list.map((e) => DeviceDailyConsumption.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
