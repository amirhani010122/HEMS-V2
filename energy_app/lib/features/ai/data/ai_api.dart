import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/ai_model.dart';

class AiApi {
  final Dio _dio = DioClient.instance;

  Future<AiAnalysis> getAnalysis() async {
    try {
      final r = await _dio.get(ApiConfig.aiAnalysis);
      return AiAnalysis.fromJson(r.data is Map ? r.data : {'analysis': r.data.toString()});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AiPrediction> getPrediction() async {
    try {
      final r = await _dio.get(ApiConfig.aiPrediction);
      return AiPrediction.fromJson(r.data is Map ? r.data : {'prediction': r.data.toString()});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AiPlanExhaustion> getPlanExhaustion() async {
    try {
      final r = await _dio.get(ApiConfig.aiPlanExhaustion);
      return AiPlanExhaustion.fromJson(
          r.data is Map ? r.data : {'exhaustionInfo': r.data.toString()});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AiRecommendation> getRecommendations() async {
    try {
      final r = await _dio.get(ApiConfig.aiRecommendations);
      return AiRecommendation.fromJson(
          r.data is Map ? r.data : {'recommendation': r.data.toString()});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final aiApiProvider = Provider((_) => AiApi());

final aiAnalysisProvider = FutureProvider<AiAnalysis>((ref) {
  return ref.watch(aiApiProvider).getAnalysis();
});

final aiPredictionProvider = FutureProvider<AiPrediction>((ref) {
  return ref.watch(aiApiProvider).getPrediction();
});

final aiPlanExhaustionProvider = FutureProvider<AiPlanExhaustion>((ref) {
  return ref.watch(aiApiProvider).getPlanExhaustion();
});

final aiRecommendationsProvider = FutureProvider<AiRecommendation>((ref) {
  return ref.watch(aiApiProvider).getRecommendations();
});

// ⭐ Provider موحد للكل
final aiAllInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final results = await Future.wait([
    ref.watch(aiApiProvider).getRecommendations(),
    ref.watch(aiApiProvider).getAnalysis(),
    ref.watch(aiApiProvider).getPrediction(),
    ref.watch(aiApiProvider).getPlanExhaustion(),
  ]);

  return {
    'recommendations': results[0],
    'analysis': results[1],
    'prediction': results[2],
    'plan_exhaustion': results[3],
  };
});