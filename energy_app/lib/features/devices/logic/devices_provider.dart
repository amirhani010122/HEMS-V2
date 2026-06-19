import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/devices_api.dart';
import '../../../shared/models/device_model.dart';

final devicesApiProvider = Provider((_) => DevicesApi());

// All devices list
final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() => _fetch();

  Future<List<DeviceModel>> _fetch() =>
      ref.read(devicesApiProvider).getDevices();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addDevice(String deviceId, String deviceName) async {
    final api = ref.read(devicesApiProvider);
    final created = await api.createDevice(
      DeviceCreate(deviceId: deviceId, deviceName: deviceName),
    );
    state.whenData((devices) {
      state = AsyncData([...devices, created]);
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    await ref.read(devicesApiProvider).deleteDevice(deviceId);
    state.whenData((devices) {
      state = AsyncData(devices.where((d) => d.deviceId != deviceId).toList());
    });
  }
}

// Single device
final deviceDetailProvider =
    FutureProvider.family<DeviceModel, String>((ref, id) {
  return ref.read(devicesApiProvider).getDevice(id);
});

// Search filter
final deviceSearchProvider = StateProvider<String>((_) => '');

final filteredDevicesProvider = Provider<AsyncValue<List<DeviceModel>>>((ref) {
  final devices = ref.watch(devicesProvider);
  final search = ref.watch(deviceSearchProvider).toLowerCase();
  if (search.isEmpty) return devices;
  return devices.whenData((list) => list.where((d) =>
      d.deviceName.toLowerCase().contains(search) ||
      d.deviceId.toLowerCase().contains(search)).toList());
});
