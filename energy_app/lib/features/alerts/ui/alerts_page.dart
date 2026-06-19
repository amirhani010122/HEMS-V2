import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/alerts_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/models/alert_model.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          // ⭐ زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(alertsProvider),
          ),
          // عداد التنبيهات (الموجود أصلاً)
          alertsAsync.whenOrNull(
            data: (alerts) => alerts.isNotEmpty
                ? Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${alerts.length}',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            )
                : const SizedBox.shrink(),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: alertsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBox(height: 90, borderRadius: 16),
          ),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(alertsProvider),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No alerts',
              subtitle: 'You\'re all good! Alerts appear here when consumption exceeds thresholds.',
            );
          }

          // Sort by date desc
          final sorted = [...alerts]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.darkCard,
            onRefresh: () async => ref.invalidate(alertsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AlertCard(alert: sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severity = _getSeverity(alert.currentUsagePercentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severity.color.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            severity.color.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: severity.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(severity.icon, color: severity.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatAlertType(alert.alertType),
                        style: AppTextStyles.h4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: severity.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        severity.label,
                        style: TextStyle(
                          color: severity.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MetricChip(
                      label: 'Usage',
                      value: '${alert.currentUsagePercentage.toStringAsFixed(1)}%',
                      color: severity.color,
                    ),
                    const SizedBox(width: 8),
                    _MetricChip(
                      label: 'Threshold',
                      value: '${alert.thresholdPercentage.toStringAsFixed(1)}%',
                      color: AppTheme.textSecondary,
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(alert.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AlertSeverity _getSeverity(double usage) {
    if (usage >= 95) {
      return _AlertSeverity(
        AppTheme.error, Icons.error_rounded, 'CRITICAL');
    } else if (usage >= 80) {
      return _AlertSeverity(
          AppTheme.warning, Icons.warning_rounded, 'HIGH');
    } else {
      return _AlertSeverity(
          AppTheme.primary, Icons.info_rounded, 'INFO');
    }
  }

  String _formatAlertType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AlertSeverity {
  final Color color;
  final IconData icon;
  final String label;
  _AlertSeverity(this.color, this.icon, this.label);
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
