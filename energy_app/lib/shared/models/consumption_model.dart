import 'json_utils.dart';

/// A single recorded consumption entry (full record from the backend).
class ConsumptionResponse {
  final String id;
  final String deviceId;
  final String userId;
  final double consumptionValue;
  final DateTime timestamp;

  const ConsumptionResponse({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.consumptionValue,
    required this.timestamp,
  });

  factory ConsumptionResponse.fromJson(Map<String, dynamic> json) {
    return ConsumptionResponse(
      id: asString(pick(json, ['id', '_id'])),
      deviceId: asString(pick(json, ['device_id', 'deviceId'])),
      userId: asString(pick(json, ['user_id', 'userId'])),
      consumptionValue:
          asDouble(pick(json, ['consumption_value', 'consumptionValue'])),
      timestamp: asDate(pick(json, ['timestamp', 'recorded_at', 'recordedAt'])),
    );
  }
}

/// Consumption submission body. Sent as {device_id, consumption_value, timestamp}.
class ConsumptionCreate {
  final String deviceId;
  final double consumptionValue;
  final DateTime timestamp;

  const ConsumptionCreate({
    required this.deviceId,
    required this.consumptionValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'consumption_value': consumptionValue,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// One day of aggregated consumption.
class DailyConsumption {
  final String date;
  final double total;

  const DailyConsumption({required this.date, required this.total});

  factory DailyConsumption.fromJson(Map<String, dynamic> json) {
    return DailyConsumption(
      date: asString(json['date']),
      total: asDouble(pick(json, ['consumption', 'total'])),
    );
  }
}

/// One month of aggregated consumption.
class MonthlyConsumption {
  final String month;
  final double total;

  const MonthlyConsumption({required this.month, required this.total});

  factory MonthlyConsumption.fromJson(Map<String, dynamic> json) {
    return MonthlyConsumption(
      month: asString(json['month']),
      total: asDouble(pick(json, ['consumption', 'total'])),
    );
  }
}

/// Overall consumption summary for the dashboard.
class ConsumptionSummary {
  final double totalConsumption;
  final double averageDaily;
  final int totalDevices;
  final double remainingQuota;
  final double usagePercentage;

  const ConsumptionSummary({
    required this.totalConsumption,
    required this.averageDaily,
    required this.totalDevices,
    required this.remainingQuota,
    required this.usagePercentage,
  });

  factory ConsumptionSummary.fromJson(Map<String, dynamic> json) {
    return ConsumptionSummary(
      totalConsumption:
          asDouble(pick(json, ['total_consumption', 'totalConsumption'])),
      averageDaily: asDouble(
          pick(json, ['average_daily', 'daily_average', 'averageDaily'])),
      totalDevices: asInt(pick(json, ['total_devices', 'totalDevices'])),
      remainingQuota:
          asDouble(pick(json, ['remaining_quota', 'remainingQuota'])),
      usagePercentage:
          asDouble(pick(json, ['usage_percentage', 'usagePercentage'])),
    );
  }
}

/// Per-device daily consumption row.
class DeviceDailyConsumption {
  final String deviceId;
  final String deviceName;
  final String date;
  final double total;

  const DeviceDailyConsumption({
    required this.deviceId,
    required this.deviceName,
    required this.date,
    required this.total,
  });

  factory DeviceDailyConsumption.fromJson(Map<String, dynamic> json) {
    return DeviceDailyConsumption(
      deviceId: asString(pick(json, ['device_id', 'deviceId'])),
      deviceName:
          asString(pick(json, ['device_name', 'deviceName']), 'Device'),
      date: asString(json['date']),
      total: asDouble(pick(json, ['total', 'consumption'])),
    );
  }
}
