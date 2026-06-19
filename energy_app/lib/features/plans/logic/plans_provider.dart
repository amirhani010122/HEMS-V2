import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plans_api.dart';
import '../../../shared/models/plan_model.dart';

final plansApiProvider = Provider((_) => PlansApi());

final availablePlansProvider = FutureProvider<List<PlanModel>>((ref) {
  return ref.watch(plansApiProvider).getAvailablePlans();
});

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, PlanSubscriptionModel?>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier
    extends AsyncNotifier<PlanSubscriptionModel?> {
  @override
  Future<PlanSubscriptionModel?> build() async {
    try {
      return await ref.watch(plansApiProvider).getSubscription();
    } catch (_) {
      return null;
    }
  }

  Future<void> subscribe(String planId) async {
    final sub = await ref.read(plansApiProvider).subscribe(planId);
    state = AsyncData(sub);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
