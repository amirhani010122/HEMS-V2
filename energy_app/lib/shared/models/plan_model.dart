import 'json_utils.dart';

/// An available energy-saving plan (serialize_plan dict).
class PlanModel {
  final String id;
  final String planName;
  final double totalQuota;
  final int durationDays;
  final DateTime? createdAt;

  const PlanModel({
    required this.id,
    required this.planName,
    required this.totalQuota,
    required this.durationDays,
    this.createdAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: asString(pick(json, ['id', '_id'])),
      planName: asString(pick(json, ['plan_name', 'planName', 'name'])),
      totalQuota:
          asDouble(pick(json, ['total_quota', 'totalQuota', 'limit'])),
      durationDays: asInt(pick(json, ['duration_days', 'durationDays']), 30),
      createdAt: asDateOrNull(pick(json, ['created_at', 'createdAt'])),
    );
  }
}

/// Plan creation request body.
class PlanCreate {
  final String planName;
  final double totalQuota;
  final int durationDays;

  const PlanCreate({
    required this.planName,
    required this.totalQuota,
    required this.durationDays,
  });

  Map<String, dynamic> toJson() => {
        'plan_name': planName,
        'total_quota': totalQuota,
        'duration_days': durationDays,
      };
}

/// Plan subscription request body. Sent as {plan_id}.
class PlanSubscriptionCreate {
  final String planId;

  const PlanSubscriptionCreate({required this.planId});

  Map<String, dynamic> toJson() => {'plan_id': planId};
}

/// The user's active subscription (serialize_subscription dict).
///
/// The backend flattens selected plan fields onto the subscription, so the
/// UI can read [planName] / [totalQuota] directly with [name] / [limit] as
/// fallbacks.
class PlanSubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double remainingQuota;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? planName;
  final double? totalQuota;
  final String? name;
  final double? limit;

  const PlanSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    this.startDate,
    this.endDate,
    this.remainingQuota = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.planName,
    this.totalQuota,
    this.name,
    this.limit,
  });

  /// Convenience: resolved display name (planName -> name -> '').
  String get displayName => planName ?? name ?? '';

  /// Convenience: resolved total quota (totalQuota -> limit -> 0).
  double get quota => totalQuota ?? limit ?? 0.0;

  factory PlanSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return PlanSubscriptionModel(
      id: asString(pick(json, ['id', '_id'])),
      userId: asString(pick(json, ['user_id', 'userId'])),
      planId: asString(pick(json, ['plan_id', 'planId'])),
      startDate: asDateOrNull(pick(json, ['start_date', 'startDate'])),
      endDate: asDateOrNull(pick(json, ['end_date', 'endDate'])),
      remainingQuota:
          asDouble(pick(json, ['remaining_quota', 'remainingQuota'])),
      isActive: asBool(pick(json, ['is_active', 'isActive']), true),
      createdAt: asDateOrNull(pick(json, ['created_at', 'createdAt'])),
      updatedAt: asDateOrNull(pick(json, ['updated_at', 'updatedAt'])),
      planName: asStringOrNull(pick(json, ['plan_name', 'planName'])),
      totalQuota: asDoubleOrNull(pick(json, ['total_quota', 'totalQuota'])),
      name: asStringOrNull(json['name']),
      limit: asDoubleOrNull(json['limit']),
    );
  }
}
