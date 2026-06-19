import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/consumption_api.dart';
import '../../../shared/models/consumption_model.dart';

final consumptionApiProvider = Provider((_) => ConsumptionApi());

final dailyConsumptionProvider =
    FutureProvider<List<DailyConsumption>>((ref) {
  return ref.watch(consumptionApiProvider).getDaily();
});

final monthlyConsumptionProvider =
    FutureProvider<List<MonthlyConsumption>>((ref) {
  return ref.watch(consumptionApiProvider).getMonthly();
});

final consumptionSummaryProvider =
    FutureProvider<ConsumptionSummary>((ref) {
  return ref.watch(consumptionApiProvider).getSummary();
});

final perDeviceDailyProvider =
    FutureProvider<List<DeviceDailyConsumption>>((ref) {
  return ref.watch(consumptionApiProvider).getPerDeviceDaily();
});

// Tab for consumption page
final consumptionTabProvider = StateProvider<int>((_) => 0);
