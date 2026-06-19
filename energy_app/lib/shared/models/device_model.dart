import 'json_utils.dart';

/// Device as returned by the backend (serialize_device dict).
class DeviceModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String userId;
  final bool isActive;
  final String status;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final String? location;
  final String? deviceType;

  const DeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.userId = '',
    this.isActive = true,
    this.status = 'offline',
    this.lastSeen,
    this.createdAt,
    this.location,
    this.deviceType,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: asString(pick(json, ['id', '_id'])),
      deviceId: asString(pick(json, ['device_id', 'deviceId'])),
      deviceName:
          asString(pick(json, ['device_name', 'deviceName', 'name']), 'Device'),
      userId: asString(pick(json, ['user_id', 'userId'])),
      isActive: asBool(pick(json, ['is_active', 'isActive']), true),
      status: asString(json['status'], 'offline'),
      lastSeen: asDateOrNull(pick(json, ['last_seen', 'lastSeen'])),
      createdAt: asDateOrNull(pick(json, ['created_at', 'createdAt'])),
      location: asStringOrNull(json['location']),
      deviceType: asStringOrNull(pick(json, ['device_type', 'deviceType'])),
    );
  }
}

/// Device creation request body. Sent as {device_id, device_name}.
class DeviceCreate {
  final String deviceId;
  final String deviceName;

  const DeviceCreate({required this.deviceId, required this.deviceName});

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
      };
}
