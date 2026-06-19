import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/plan_model.dart';

class PlansApi {
  final Dio _dio = DioClient.instance;

  Future<List<PlanModel>> getAvailablePlans() async {
    try {
      final response = await _dio.get(ApiConfig.plansAvailable);
      final list = response.data as List;
      return list.map((e) => PlanModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PlanSubscriptionModel> getSubscription() async {
    try {
      final response = await _dio.get(ApiConfig.plansSubscription);
      return PlanSubscriptionModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PlanSubscriptionModel> subscribe(String planId) async {
    try {
      final response = await _dio.post(ApiConfig.plansSubscribe, data: {
        'plan_id': planId,
      });
      return PlanSubscriptionModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PlanModel> createPlan(PlanCreate data) async {
    try {
      final response = await _dio.post(ApiConfig.plansCreate, data: {
        'plan_name': data.planName,
        'total_quota': data.totalQuota,
        'duration_days': data.durationDays,
      });
      return PlanModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
