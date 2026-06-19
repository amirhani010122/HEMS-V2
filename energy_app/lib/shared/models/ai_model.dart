import 'json_utils.dart';

/// AI energy analysis (text + optional structured data).
class AiAnalysis {
  final String analysis;
  final Map<String, dynamic>? data;

  const AiAnalysis({required this.analysis, this.data});

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      analysis: asString(json['analysis']),
      data: asMapOrNull(json['data']),
    );
  }
}

/// AI consumption forecast (text + optional structured data).
class AiPrediction {
  final String prediction;
  final Map<String, dynamic>? data;

  const AiPrediction({required this.prediction, this.data});

  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    return AiPrediction(
      prediction: asString(json['prediction']),
      data: asMapOrNull(json['data']),
    );
  }
}

/// AI plan-exhaustion estimate (text + optional structured data).
class AiPlanExhaustion {
  final String exhaustionInfo;
  final Map<String, dynamic>? data;

  const AiPlanExhaustion({required this.exhaustionInfo, this.data});

  factory AiPlanExhaustion.fromJson(Map<String, dynamic> json) {
    return AiPlanExhaustion(
      exhaustionInfo:
          asString(pick(json, ['exhaustion_info', 'exhaustionInfo'])),
      data: asMapOrNull(json['data']),
    );
  }
}

/// AI smart-advisor recommendation (text + optional structured data).
class AiRecommendation {
  final String recommendation;
  final Map<String, dynamic>? data;

  const AiRecommendation({required this.recommendation, this.data});

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      recommendation: asString(json['recommendation']),
      data: asMapOrNull(json['data']),
    );
  }
}
