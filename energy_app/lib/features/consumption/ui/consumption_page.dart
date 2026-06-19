import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../logic/consumption_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/models/consumption_model.dart';

class ConsumptionPage extends ConsumerWidget {
  const ConsumptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(consumptionTabProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Consumption'),
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
              ref.invalidate(dailyConsumptionProvider);
              ref.invalidate(monthlyConsumptionProvider);
              ref.invalidate(perDeviceDailyProvider);
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
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                children: [
                  _Tab(label: 'Daily', selected: tab == 0,
                      onTap: () => ref.read(consumptionTabProvider.notifier).state = 0),
                  _Tab(label: 'Monthly', selected: tab == 1,
                      onTap: () => ref.read(consumptionTabProvider.notifier).state = 1),
                  _Tab(label: 'Per Device', selected: tab == 2,
                      onTap: () => ref.read(consumptionTabProvider.notifier).state = 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: IndexedStack(
              index: tab,
              children: const [
                _DailyChart(),
                _MonthlyChart(),
                _PerDeviceChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyChart extends ConsumerWidget {
  const _DailyChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyConsumptionProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonBox(height: 260, borderRadius: 16),
      ),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(dailyConsumptionProvider),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.bar_chart_outlined,
            title: 'No daily data',
            subtitle: 'Start sending consumption readings from your devices.',
          );
        }
        return _LineChartWidget(
          title: 'Daily Consumption (kWh)',
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.total))
              .toList(),
          labels: data.map((d) => d.date.length > 5 ? d.date.substring(5) : d.date).toList(),
          color: AppTheme.primary,
        );
      },
    );
  }
}

class _MonthlyChart extends ConsumerWidget {
  const _MonthlyChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyConsumptionProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonBox(height: 260, borderRadius: 16),
      ),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(monthlyConsumptionProvider),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_month_outlined,
            title: 'No monthly data',
            subtitle: 'Monthly summaries appear here after 30 days of usage.',
          );
        }
        return _LineChartWidget(
          title: 'Monthly Consumption (kWh)',
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.total))
              .toList(),
          labels: data.map((d) => d.month).toList(),
          color: AppTheme.secondary,
        );
      },
    );
  }
}

class _PerDeviceChart extends ConsumerWidget {
  const _PerDeviceChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(perDeviceDailyProvider);
    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonBox(height: 220, borderRadius: 16),
        ),
      ),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(perDeviceDailyProvider),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.devices_other,
            title: 'No per-device data',
            subtitle: 'Add devices and send readings to see per-device breakdowns.',
          );
        }

        // ⭐ تجميع البيانات حسب الجهاز
        final Map<String, List<DeviceDailyConsumption>> grouped = {};
        for (final item in data) {
          grouped.putIfAbsent(item.deviceName, () => []).add(item);
        }

        // ⭐ ألوان مميزة لكل جهاز
        final colors = [
          AppTheme.primary,
          AppTheme.secondary,
          AppTheme.warning,
          AppTheme.success,
          AppTheme.error,
          const Color(0xFF8B5CF6), // بنفسجي
          const Color(0xFF06B6D4), // سماوي
          const Color(0xFFF97316), // برتقالي
        ];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: grouped.length,
          itemBuilder: (_, index) {
            final entry = grouped.entries.elementAt(index);
            final deviceName = entry.key;
            final deviceData = entry.value;
            final color = colors[index % colors.length];
            final totalKwh = deviceData.fold(0.0, (s, d) => s + d.total);
            final avgKwh = totalKwh / deviceData.length;
            final peakKwh = deviceData.map((d) => d.total).reduce((a, b) => a > b ? a : b);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══ Header ═══
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getDeviceIcon(deviceName),
                              color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deviceName,
                                style: AppTextStyles.h4.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${deviceData.length} readings',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        // Total badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${totalKwh.toStringAsFixed(1)} kWh',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ═══ Bar Chart ═══
                    SizedBox(
                      height: 140,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: peakKwh * 1.3,
                          barGroups: deviceData.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.total,
                                  color: color,
                                  width: deviceData.length > 10 ? 6 : 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx >= 0 && idx < deviceData.length) {
                                    // نعرض كل 3 أيام عشان ما يزحمش
                                    if (deviceData.length > 7 && idx % 3 != 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final d = deviceData[idx].date;
                                    final label = d.length > 5 ? d.substring(8) : d;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(label,
                                          style: AppTextStyles.caption.copyWith(
                                              fontSize: 10)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppTheme.darkBorder.withOpacity(0.5),
                              strokeWidth: 1,
                            ),
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppTheme.darkCardAlt,
                              getTooltipItem: (group, _, __, ___) =>
                                  BarTooltipItem(
                                    '${deviceData[group.x].date}\n${group.barRods.first.toY.toStringAsFixed(2)} kWh',
                                    const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ═══ Stats Row ═══
                    Row(
                      children: [
                        _MiniStat(label: 'Avg', value: '${avgKwh.toStringAsFixed(1)} kWh', color: color),
                        const SizedBox(width: 10),
                        _MiniStat(label: 'Peak', value: '${peakKwh.toStringAsFixed(1)} kWh', color: AppTheme.warning),
                        const SizedBox(width: 10),
                        _MiniStat(label: 'Total', value: '${totalKwh.toStringAsFixed(1)} kWh', color: AppTheme.success),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('fridge') || lower.contains('refrig')) return Icons.kitchen_rounded;
    if (lower.contains('heat') || lower.contains('water')) return Icons.water_drop_rounded;
    if (lower.contains('light')) return Icons.lightbulb_rounded;
    if (lower.contains('meter') || lower.contains('smart')) return Icons.memory_rounded;
    return Icons.devices_other;
  }
}

// ⭐ إضافة ويدجت MiniStat
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final List<String> labels;
  final Color color;

  const _LineChartWidget({
    required this.title,
    required this.spots,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: AppTheme.darkBg,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
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
                      interval: (spots.length / 5).ceilToDouble(),
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(labels[idx], style: AppTextStyles.caption),
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.darkCardAlt,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(2)} kWh',
                              const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Summary stats
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Total',
                  value: '${spots.fold(0.0, (s, f) => s + f.y).toStringAsFixed(1)} kWh',
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Average',
                  value:
                      '${(spots.fold(0.0, (s, f) => s + f.y) / spots.length).toStringAsFixed(1)} kWh',
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Peak',
                  value:
                      '${spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} kWh',
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
