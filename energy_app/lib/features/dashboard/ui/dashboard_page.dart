import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../consumption/logic/consumption_provider.dart';
import '../../devices/logic/devices_provider.dart';
import '../../alerts/data/alerts_api.dart';
import '../../plans/logic/plans_provider.dart';
import '../../profile/logic/profile_provider.dart';
import '../../ai/data/ai_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/app_drawer.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isRefreshing = false;

  Future<void> _refreshAll() async {
    setState(() => _isRefreshing = true);

    // ⭐ إعادة تحميل كل البيانات
    ref.invalidate(consumptionSummaryProvider);
    ref.invalidate(devicesProvider);
    ref.invalidate(alertsProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(userProvider);
    ref.invalidate(aiRecommendationsProvider);

    // انتظار بسيط عشان الـ loading يظهر
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(consumptionSummaryProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final userAsync = ref.watch(userProvider);
    final aiAsync = ref.watch(aiRecommendationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('EnergyIQ Dashboard'),
        elevation: 0,
        actions: [
          // ⭐ زر إعادة التحميل
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _refreshAll,
          ),
          const SizedBox(width: 4),
          // زر الإشعارات
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.darkCard,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting
              userAsync.when(
                data: (user) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Welcome back, ',
                        style: AppTextStyles.h2.copyWith(color: AppTheme.textSecondary),
                        children: [
                          TextSpan(
                            text: user.username,
                            style: AppTextStyles.h2.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's your energy overview",
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SkeletonBox(width: 200, height: 30),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),

              // 2. AI Insight Card
              aiAsync.when(
                data: (ai) => GestureDetector(
                  onTap: () => context.push('/ai-insights'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondary.withOpacity(0.15),
                          AppTheme.primary.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AI RECOMMENDATION',
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  )),
                              const SizedBox(height: 6),
                              Text(
                                ai.recommendation,
                                style: AppTextStyles.body.copyWith(height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: SkeletonBox(height: 90, borderRadius: 16),
                ),
                error: (e, _) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Text(
                    'AI Insights temporarily unavailable',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 3. KPI Cards
              summaryAsync.when(
                loading: () => _buildKpiSkeletons(),
                error: (e, _) => const SizedBox.shrink(),
                data: (summary) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Total Usage',
                            value: '${summary.totalConsumption.toStringAsFixed(1)} kWh',
                            subtitle: summary.usagePercentage > 0
                                ? '${summary.usagePercentage.toStringAsFixed(0)}% of quota'
                                : null,
                            icon: Icons.bolt_rounded,
                            color: AppTheme.primary,
                            onTap: () => context.push('/consumption'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Daily Average',
                            value: '${summary.averageDaily.toStringAsFixed(1)} kWh',
                            icon: Icons.trending_down_rounded,
                            color: AppTheme.secondary,
                            onTap: () => context.push('/consumption'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Devices',
                            value: '${summary.totalDevices}',
                            icon: Icons.memory_rounded,
                            color: AppTheme.warning,
                            onTap: () => context.push('/devices'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Remaining',
                            value: '${summary.remainingQuota.toStringAsFixed(1)} kWh',
                            color: summary.remainingQuota > 0 ? AppTheme.success : AppTheme.error,
                            icon: Icons.battery_charging_full_rounded,
                            onTap: () => context.push('/plans'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 4. Plan Status
              const Text('Plan Status', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              subscriptionAsync.when(
                loading: () => const SkeletonBox(height: 120, borderRadius: 16),
                error: (e, _) => const SizedBox.shrink(),
                data: (sub) {
                  if (sub == null) return _NoPlanCard(onTap: () => context.push('/plans'));
                  return QuotaProgressCard(
                    planName: sub.planName ?? sub.name ?? 'Current Plan',
                    used: (sub.totalQuota ?? sub.limit ?? 0) - sub.remainingQuota,
                    total: sub.totalQuota ?? sub.limit ?? 0,
                    endDate: sub.endDate,
                  );
                },
              ),
              const SizedBox(height: 24),

              // 5. Recent Alerts
              Row(
                children: [
                  const Text('Recent Alerts', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/alerts'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              alertsAsync.when(
                data: (alerts) => alerts.isEmpty
                    ? _buildEmptySection('No active alerts')
                    : Column(children: alerts.take(2).map((a) => _AlertPreviewCard(alert: a)).toList()),
                loading: () => const SkeletonBox(height: 60, borderRadius: 12),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: AppTextStyles.caption, textAlign: TextAlign.center),
    );
  }

  Widget _buildKpiSkeletons() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 100)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 100)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 100)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 100)),
          ],
        ),
      ],
    );
  }
}

// ── Support Widgets ──────────────────────────────

class _NoPlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoPlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        children: [
          const Text('No active subscription', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onTap, child: const Text('View Plans')),
        ],
      ),
    );
  }
}

class _AlertPreviewCard extends StatelessWidget {
  final dynamic alert;
  const _AlertPreviewCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    String alertMessage = '';
    bool isHighSeverity = false;

    try {
      alertMessage = alert.message ?? '';
      final severity = alert.severity ?? alert.type ?? 'info';
      isHighSeverity = severity == 'high' || severity == 'error';
    } catch (e) {
      alertMessage = alert.toString();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isHighSeverity ? AppTheme.error : AppTheme.warning,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(alertMessage, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}