import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/device_model.dart';

class DevicesApi {
  final Dio _dio = DioClient.instance;

  Future<List<DeviceModel>> getDevices() async {
    try {
      final response = await _dio.get(ApiConfig.devices);
      final list = response.data as List;
      return list.map((e) => DeviceModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<DeviceModel> getDevice(String deviceId) async {
    try {
      final response = await _dio.get(ApiConfig.deviceById(deviceId));
      return DeviceModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<DeviceModel> createDevice(DeviceCreate data) async {
    try {
      final response = await _dio.post(ApiConfig.devices, data: {
        'device_id': data.deviceId,
        'device_name': data.deviceName,
      });
      return DeviceModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _dio.delete(ApiConfig.deviceById(deviceId));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
