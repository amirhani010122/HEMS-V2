import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/plans_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/models/plan_model.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final plansAsync = ref.watch(availablePlansProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Energy Plans'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          // ⭐ زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(subscriptionProvider);
              ref.invalidate(availablePlansProvider);
            },
          ),
          // ⭐ زر الإشعارات
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts',
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.darkCard,
        onRefresh: () => ref.read(subscriptionProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current subscription
              const Text('Current Plan', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              subscriptionAsync.when(
                loading: () => const SkeletonBox(height: 120, borderRadius: 16),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  compact: true,
                  onRetry: () => ref.read(subscriptionProvider.notifier).refresh(),
                ),
                data: (sub) {
                  if (sub == null) {
                    return _NoSubscriptionCard();
                  }
                  final planName = sub.planName ?? sub.name ?? 'Current Plan';
                  final total = sub.totalQuota ?? sub.limit ?? 0.0;
                  final used = total - sub.remainingQuota;
                  return QuotaProgressCard(
                    planName: planName,
                    used: used,
                    total: total,
                    endDate: sub.endDate,
                  );
                },
              ),
              const SizedBox(height: 28),

              // Available plans
              const Text('Available Plans', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              plansAsync.when(
                loading: () => Column(
                  children: List.generate(
                      3, (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonBox(height: 130, borderRadius: 16))),
                ),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(availablePlansProvider),
                ),
                data: (plans) {
                  if (plans.isEmpty) {
                    return const AppErrorWidget(
                      message: 'No plans available at this time.',
                      compact: true,
                    );
                  }
                  return Column(
                    children: plans
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PlanCard(
                                plan: p,
                                onSubscribe: () => _subscribe(context, ref, p),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe(
      BuildContext context, WidgetRef ref, PlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('Subscribe to ${plan.planName}', style: AppTextStyles.h3),
        content: Text(
          'You will get ${plan.totalQuota} kWh quota for ${plan.durationDays} days.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(subscriptionProvider.notifier).subscribe(plan.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscribed to ${plan.planName}!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

class _NoSubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.warning, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Active Plan', style: AppTextStyles.h4),
                SizedBox(height: 2),
                Text(
                  'Subscribe to a plan below to track your quota.',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final VoidCallback onSubscribe;

  const _PlanCard({required this.plan, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.planName, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppTheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${plan.totalQuota} kWh',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${plan.durationDays} days',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.darkBorder),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSubscribe,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Subscribe'),
            ),
          ),
        ],
      ),
    );
  }
}
