import 'json_utils.dart';

/// An alert shown in the alerts list (stored or dynamically computed).
class AlertModel {
  final String id;
  final String userId;
  final String alertType;
  final String message;
  final double thresholdPercentage;
  final double currentUsagePercentage;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.message,
    required this.thresholdPercentage,
    required this.currentUsagePercentage,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: asString(pick(json, ['id', '_id'])),
      userId: asString(pick(json, ['user_id', 'userId'])),
      alertType: asString(pick(json, ['alert_type', 'alertType']), 'info'),
      message: asString(json['message']),
      thresholdPercentage: asDouble(
          pick(json, ['threshold_percentage', 'thresholdPercentage'])),
      currentUsagePercentage: asDouble(
          pick(json, ['current_usage_percentage', 'currentUsagePercentage'])),
      createdAt: asDate(pick(json, ['created_at', 'createdAt'])),
    );
  }
}
