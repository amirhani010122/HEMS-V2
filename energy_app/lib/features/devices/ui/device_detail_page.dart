import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../logic/devices_provider.dart';
import '../../consumption/logic/consumption_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_error_widget.dart';

class DeviceDetailPage extends ConsumerWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceDetailProvider(deviceId));
    final perDeviceAsync = ref.watch(perDeviceDailyProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Device Details')),
      body: deviceAsync.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
        data: (device) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.secondary.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.memory_rounded,
                              color: AppTheme.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.deviceName,
                                  style: AppTextStyles.h2),
                              const SizedBox(height: 4),
                              Text(
                                device.deviceId,
                                style: AppTextStyles.caption.copyWith(
                                  fontFamily: 'monospace',
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(isActive: device.isActive),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.darkBorder),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.access_time,
                          label: device.lastSeen != null
                              ? 'Last: ${_fmt(device.lastSeen!)}'
                              : 'Never seen',
                        ),
                        const SizedBox(width: 8),
                        if (device.createdAt != null)
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label: 'Added ${_fmt(device.createdAt!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Per-device daily consumption chart
              const Text('Daily Consumption', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              perDeviceAsync.when(
                loading: () => const SkeletonBox(height: 200, borderRadius: 16),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  compact: true,
                ),
                data: (allData) {
                  final deviceData = allData
                      .where((d) => d.deviceId == deviceId)
                      .toList();

                  if (deviceData.isEmpty) {
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No consumption data yet',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: deviceData
                                .map((d) => d.total)
                                .reduce((a, b) => a > b ? a : b) *
                            1.3,
                        barGroups: deviceData
                            .asMap()
                            .entries
                            .map((e) => BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.total,
                                      color: AppTheme.primary,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ))
                            .toList(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < deviceData.length) {
                                  final d = deviceData[idx].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      d.length > 5 ? d.substring(5) : d,
                                      style: AppTextStyles.caption,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppTheme.darkBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Device Info
              const Text('Device Information', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _InfoRow(label: 'Device ID', value: device.deviceId),
              _InfoRow(label: 'Status',
                  value: device.isActive ? 'Active' : 'Offline'),
              _InfoRow(
                label: 'Last Seen',
                value: device.lastSeen != null
                    ? device.lastSeen.toString().substring(0, 19)
                    : 'Never',
              ),
              if (device.createdAt != null)
                _InfoRow(
                  label: 'Added On',
                  value: device.createdAt.toString().substring(0, 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withOpacity(0.12)
            : AppTheme.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Offline',
            style: TextStyle(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkCardAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
