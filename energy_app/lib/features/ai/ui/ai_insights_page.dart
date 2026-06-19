import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/ai_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class AiInsightsPage extends ConsumerStatefulWidget {
  const AiInsightsPage({super.key});

  @override
  ConsumerState<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends ConsumerState<AiInsightsPage> {
  bool _isRefreshing = false;

  Future<void> _refreshAll() async {
    setState(() => _isRefreshing = true);
    ref.invalidate(aiRecommendationsProvider);
    ref.invalidate(aiAnalysisProvider);
    ref.invalidate(aiPredictionProvider);
    ref.invalidate(aiPlanExhaustionProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(aiRecommendationsProvider);
    final analysisAsync = ref.watch(aiAnalysisProvider);
    final predictionAsync = ref.watch(aiPredictionProvider);
    final exhaustionAsync = ref.watch(aiPlanExhaustionProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('AI Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondary.withOpacity(0.12), AppTheme.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Analysis Active', style: AppTextStyles.h4),
                          SizedBox(height: 2),
                          Text('Real-time insights from your consumption data', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionHeader(icon: Icons.lightbulb_outline, title: 'Smart Recommendations', color: AppTheme.warning),
              const SizedBox(height: 12),
              recommendationsAsync.when(
                loading: () => const SkeletonBox(height: 100, borderRadius: 14),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (data) => _SafeRecommendationCard(data: data),
              ),

              const SizedBox(height: 28),

              _SectionHeader(icon: Icons.warning_amber_rounded, title: 'Anomaly Detection', color: AppTheme.error),
              const SizedBox(height: 12),
              analysisAsync.when(
                loading: () => const SkeletonBox(height: 120, borderRadius: 14),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (data) => _SafeAnomalyCard(data: data),
              ),

              const SizedBox(height: 28),

              _SectionHeader(icon: Icons.trending_up_rounded, title: 'Consumption Forecast', color: AppTheme.secondary),
              const SizedBox(height: 12),
              predictionAsync.when(
                loading: () => const SkeletonBox(height: 140, borderRadius: 14),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (data) => _SafePredictionCard(data: data),
              ),

              const SizedBox(height: 28),

              _SectionHeader(icon: Icons.battery_alert_rounded, title: 'Plan Exhaustion', color: AppTheme.primary),
              const SizedBox(height: 12),
              exhaustionAsync.when(
                loading: () => const SkeletonBox(height: 100, borderRadius: 14),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (data) => _SafeExhaustionCard(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════

/// استخراج آمن لقيمة String من dynamic
String _safeStr(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  return val.toString();
}

/// استخراج آمن لقيمة double من dynamic
double _safeDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

/// استخراج آمن لقيمة int من dynamic
int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

/// استخراج آمن لـ Map من dynamic
Map _safeMap(dynamic val) {
  if (val is Map) return val;
  return {};
}

/// استخراج آمن لـ List من dynamic
List _safeList(dynamic val) {
  if (val is List) return val;
  return [];
}

// ═══════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.h3),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// ═══════════════════════════════════════════
// 💡 Smart Recommendation Card - Arabic Optimized
// ═══════════════════════════════════════════
class _SafeRecommendationCard extends StatelessWidget {
  final dynamic data;
  const _SafeRecommendationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _ErrorCard(message: 'لا توجد بيانات');

    final text = _safeStr(data.recommendation);
    final recsList = _safeList(data.data);

    // لو فيه recommendations مفصلة من المحرك
    if (recsList.isNotEmpty) {
      return Column(
        children: recsList.take(5).map((rec) {
          final recMap = _safeMap(rec);
          final title = _safeStr(recMap['title']);
          final desc = _safeStr(recMap['description']);
          final priority = _safeStr(recMap['priority'], 'medium');
          final actions = _safeList(recMap['actions']);
          final savings = _safeMap(recMap['potential_savings']);
          final savingsKwh = _safeDouble(savings['kwh_savings']);
          final savingsPct = _safeDouble(savings['percentage']);

          // الألوان حسب الأولوية
          final pColor = priority == 'critical'
              ? AppTheme.error
              : priority == 'high'
              ? AppTheme.warning
              : AppTheme.primary;

          final pIcon = priority == 'critical'
              ? Icons.priority_high_rounded
              : priority == 'high'
              ? Icons.arrow_circle_up_rounded
              : Icons.lightbulb_outline;

          final pLabel = priority == 'critical'
              ? 'حرج'
              : priority == 'high'
              ? 'مهم'
              : 'نصيحة';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pColor.withOpacity(0.3)),
                // ⭐ حدود جانبية للتعريف بالأولوية
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ العنوان + أيقونة + شارة الأولوية
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(pIcon, color: pColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.h4.copyWith(
                            color: pColor,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl, // ⭐ عربي
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pLabel,
                          style: TextStyle(
                            color: pColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ⭐ الوصف
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: AppTextStyles.bodySecondary.copyWith(height: 1.6),
                      textDirection: TextDirection.rtl, // ⭐ عربي
                    ),
                  ],

                  // ⭐ التوفير المتوقع
                  if (savingsKwh > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.success.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_rounded, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'توفير متوقع: ${savingsKwh.toStringAsFixed(1)} kWh (${savingsPct.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ⭐ الإجراءات المقترحة
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'الإجراءات المقترحة:',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 6),
                    ...actions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: pColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_safeStr(action)}',
                              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // ⭐ Fallback: نص عادي (عربي)
    if (text.isEmpty) return _ErrorCard(message: 'لا توجد توصيات');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: text
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                  style: AppTextStyles.body.copyWith(height: 1.5),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}
// ═══════════════════════════════════════════
class _SafeAnomalyCard extends StatelessWidget {
  final dynamic data;
  const _SafeAnomalyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _ErrorCard(message: 'No data');

    final analysisText = _safeStr(data.analysis, 'No analysis available.');
    final dataMap = _safeMap(data.data);
    final anomalies = _safeList(dataMap['anomalies']);
    final status = _safeStr(dataMap['status'], 'ok');

    final sColor = status == 'critical' ? AppTheme.error
        : status == 'warning' ? AppTheme.warning : AppTheme.success;
    final sIcon = status == 'critical' ? Icons.error_rounded
        : status == 'warning' ? Icons.warning_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sIcon, color: sColor, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text(analysisText, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
          if (anomalies.isNotEmpty) ...[
            const SizedBox(height: 14), const Divider(color: AppTheme.darkBorder), const SizedBox(height: 10),
            ...anomalies.take(3).map((a) {
              final am = _safeMap(a);
              final msg = _safeStr(am['message']);
              final sev = _safeStr(am['severity'], 'medium');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: sev == 'critical' || sev == 'high' ? AppTheme.error : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(msg, style: AppTextStyles.caption)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _SafePredictionCard extends StatelessWidget {
  final dynamic data;
  const _SafePredictionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _ErrorCard(message: 'No data');

    final text = _safeStr(data.prediction);
    final dataMap = _safeMap(data.data);
    final monthly = _safeDouble(dataMap['predicted_monthly_consumption']);
    final daily = _safeDouble(dataMap['predicted_daily_consumption']);
    final confidence = _safeDouble(dataMap['confidence_score']);
    final trend = _safeStr(dataMap['trend'], 'stable');

    final tIcon = trend == 'increasing' ? Icons.trending_up_rounded
        : trend == 'decreasing' ? Icons.trending_down_rounded : Icons.trending_flat_rounded;
    final tColor = trend == 'increasing' ? AppTheme.error
        : trend == 'decreasing' ? AppTheme.success : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(tIcon, color: tColor, size: 32), const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${monthly.toStringAsFixed(0)} kWh', style: AppTextStyles.h2.copyWith(color: tColor)),
                    Text('predicted this month', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'Daily', value: '${daily.toStringAsFixed(1)} kWh'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Confidence', value: '${(confidence * 100).toInt()}%'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Trend', value: trend),
            ],
          ),
          if (text.isNotEmpty) ...[const SizedBox(height: 12), Text(text, style: AppTextStyles.caption.copyWith(height: 1.4))],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _SafeExhaustionCard extends StatelessWidget {
  final dynamic data;
  const _SafeExhaustionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _ErrorCard(message: 'No data');

    final text = _safeStr(data.exhaustionInfo);
    final dataMap = _safeMap(data.data);
    final daysLeft = _safeInt(dataMap['days_until_exhaustion'], 999);
    final hasPlan = dataMap['has_plan'] == true;

    final cColor = !hasPlan ? AppTheme.textMuted
        : daysLeft <= 3 ? AppTheme.error
        : daysLeft <= 7 ? AppTheme.warning : AppTheme.success;
    final cIcon = !hasPlan ? Icons.help_outline
        : daysLeft <= 3 ? Icons.battery_alert_rounded
        : daysLeft <= 7 ? Icons.battery_charging_full_rounded : Icons.battery_full_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: cColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(cIcon, color: cColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasPlan ? '$daysLeft days remaining' : 'No active plan',
                    style: AppTextStyles.h3.copyWith(color: cColor)),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(color: AppTheme.darkBorder.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h4, textAlign: TextAlign.center),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
        ],
      ),
    );
  }
}