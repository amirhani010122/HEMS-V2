"""
محرك التوصيات الذكي.
يحلل بيانات المستخدم الفعلية ويولد توصيات مخصصة.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class RecommendationEngine:
    """محرك قواعد لتوليد توصيات ذكية مبنية على بيانات حقيقية."""

    def __init__(self):
        self.recommendations: List[Dict[str, Any]] = []

    def generate(
        self,
        user_id: str,
        consumption_summary: Dict[str, Any],
        daily_data: List[Dict[str, Any]],
        monthly_data: List[Dict[str, Any]],
        per_device_data: List[Dict[str, Any]],
        devices: List[Dict[str, Any]],
        subscription: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        توليد توصيات مخصصة للمستخدم.

        Args:
            user_id: معرف المستخدم
            consumption_summary: ملخص الاستهلاك (من /consumption/summary)
            daily_data: بيانات يومية (من /consumption/daily)
            monthly_data: بيانات شهرية (من /consumption/monthly)
            per_device_data: بيانات لكل جهاز (من /consumption/per-device-daily)
            devices: قائمة الأجهزة (من /devices)
            subscription: تفاصيل الباقة (من /plans/subscription) - اختياري

        Returns:
            قائمة توصيات
        """
        self.recommendations = []

        # ═══════════════════════════════════════
        # قاعدة 1: جهاز بيستهلك أكتر من 40%
        # ═══════════════════════════════════════
        self._check_high_consumption_device(user_id, per_device_data, devices, consumption_summary)

        # ═══════════════════════════════════════
        # قاعدة 2: الباقة قربت تخلص
        # ═══════════════════════════════════════
        if subscription:
            self._check_quota_warning(user_id, consumption_summary, subscription)

        # ═══════════════════════════════════════
        # قاعدة 3: استهلاك عالي في الذروة
        # ═══════════════════════════════════════
        self._check_peak_hours(user_id, daily_data)

        # ═══════════════════════════════════════
        # قاعدة 4: اتجاه الاستهلاك (زيادة/نقصان)
        # ═══════════════════════════════════════
        self._check_consumption_trend(user_id, daily_data)

        # ═══════════════════════════════════════
        # قاعدة 5: جهاز شغال 24 ساعة
        # ═══════════════════════════════════════
        self._check_always_on_device(user_id, per_device_data, devices)

        # ═══════════════════════════════════════
        # قاعدة 6: نصيحة عامة مفيدة
        # ═══════════════════════════════════════
        self._add_seasonal_tip(user_id, consumption_summary)

        return self.recommendations

    # ═══════════════════════════════════════════════════════
    # القواعد
    # ═══════════════════════════════════════════════════════

    def _check_high_consumption_device(
        self,
        user_id: str,
        per_device_data: List[Dict[str, Any]],
        devices: List[Dict[str, Any]],
        summary: Dict[str, Any],
    ):
        """اكتشاف جهاز بيستهلك نسبة كبيرة من الإجمالي."""
        if not per_device_data:
            return

        # تجميع الاستهلاك لكل جهاز
        device_totals: Dict[str, float] = {}
        for item in per_device_data:
            did = item.get("device_id", "unknown")
            name = item.get("device_name", did)
            consumption = item.get("total", item.get("consumption", 0))
            device_totals[name] = device_totals.get(name, 0) + consumption

        total_all = sum(device_totals.values())
        if total_all <= 0:
            return

        # البحث عن جهاز بيستهلك > 40%
        for name, consumption in device_totals.items():
            pct = (consumption / total_all) * 100
            if pct >= 40:
                savings_kwh = consumption * 0.15  # تقدير توفير 15%
                self.recommendations.append({
                    "title": f"جهاز {name} بيستهلك {pct:.0f}% من طاقتك",
                    "description": (
                        f"جهاز {name} استهلك {consumption:.1f} kWh من إجمالي {total_all:.1f} kWh. "
                        f"تقليل استخدامه أو تحسين كفاءته ممكن يوفر {savings_kwh:.1f} kWh شهرياً."
                    ),
                    "potential_savings": {
                        "kwh_savings": round(savings_kwh, 2),
                        "percentage": 15.0,
                        "estimated_cost_reduction": round(savings_kwh * 0.15, 2),
                    },
                    "affected_device": name,
                    "implementation_difficulty": "medium",
                    "estimated_time_to_implement": "1 week",
                    "actions": [
                        f"راقب استهلاك {name} أسبوعياً",
                        "ابحث عن بديل أكثر كفاءة",
                        "استخدم الجهاز في أوقات غير الذروة",
                    ],
                    "priority": "high",
                    "based_on": "real_data",
                })
                return  # نكتفي بواحد

    def _check_quota_warning(
        self,
        user_id: str,
        summary: Dict[str, Any],
        subscription: Dict[str, Any],
    ):
        """تحذير لو الباقة قربت تخلص."""
        usage_pct = summary.get("usage_percentage", 0)
        remaining = subscription.get("remaining_quota", 0)
        total = subscription.get("total_quota", 0)

        if usage_pct >= 90:
            self.recommendations.append({
                "title": f"🚨 باقتك خلصت تقريباً! ({usage_pct:.0f}%)",
                "description": (
                    f"استهلكت {usage_pct:.0f}% من باقتك. فاضل {remaining:.1f} kWh من {total:.0f} kWh. "
                    "جدد اشتراكك عشان ما تتقطعش عن المراقبة."
                ),
                "potential_savings": {
                    "kwh_savings": 0,
                    "percentage": 0,
                    "estimated_cost_reduction": 0,
                },
                "affected_device": None,
                "implementation_difficulty": "easy",
                "estimated_time_to_implement": "immediate",
                "actions": ["جدد باقتك دلوقتي", "أو قلل استهلاكك مؤقتاً"],
                "priority": "critical",
                "based_on": "real_data",
            })
        elif usage_pct >= 80:
            self.recommendations.append({
                "title": f"⚠️ استهلكت {usage_pct:.0f}% من باقتك",
                "description": (
                    f"فاضل {remaining:.1f} kWh من باقتك ({total:.0f} kWh). "
                    "قلل استهلاكك شوية عشان الباقة تكمل للشهر."
                ),
                "potential_savings": {
                    "kwh_savings": round(remaining * 0.1, 2),
                    "percentage": 10.0,
                    "estimated_cost_reduction": round(remaining * 0.015, 2),
                },
                "affected_device": None,
                "implementation_difficulty": "easy",
                "estimated_time_to_implement": "immediate",
                "actions": ["قلل استخدام الأجهزة العالية", "راجع استهلاكك اليومي"],
                "priority": "high",
                "based_on": "real_data",
            })

    def _check_peak_hours(self, user_id: str, daily_data: List[Dict[str, Any]]):
        """اكتشاف استهلاك عالي في ساعات الذروة."""
        if len(daily_data) < 2:
            return

        # لو الاستهلاك بيزيد عن المتوسط بأكتر من 30%، دي ذروة
        values = [d.get("total", d.get("consumption", 0)) for d in daily_data]
        if not values:
            return

        avg = sum(values) / len(values)
        peak_days = [v for v in values if v > avg * 1.3]

        if len(peak_days) >= 2:  # لو فيه يومين ذروة على الأقل
            self.recommendations.append({
                "title": "📈 فيه أيام استهلاك عالي عندك",
                "description": (
                    f"متوسط استهلاكك اليومي {avg:.1f} kWh، لكن فيه {len(peak_days)} أيام استهلاكها أعلى بكتير. "
                    "حاول توزع استهلاكك على مدار الأسبوع."
                ),
                "potential_savings": {
                    "kwh_savings": round(avg * 0.1, 2),
                    "percentage": 10.0,
                    "estimated_cost_reduction": round(avg * 0.015, 2),
                },
                "affected_device": None,
                "implementation_difficulty": "medium",
                "estimated_time_to_implement": "1 week",
                "actions": [
                    "حدد الأنشطة العالية وانقلها لأيام أقل استهلاكاً",
                    "استخدم المؤقتات الزمنية للأجهزة",
                ],
                "priority": "medium",
                "based_on": "real_data",
            })

    def _check_consumption_trend(self, user_id: str, daily_data: List[Dict[str, Any]]):
        """تحليل اتجاه الاستهلاك (زيادة ولا نقصان)."""
        if len(daily_data) < 7:
            return

        values = [d.get("total", d.get("consumption", 0)) for d in daily_data]

        # نقارن أول 3 أيام بآخر 3 أيام
        first_half = values[:3]
        second_half = values[-3:]

        avg_first = sum(first_half) / len(first_half) if first_half else 0
        avg_second = sum(second_half) / len(second_half) if second_half else 0

        if avg_first <= 0:
            return

        change_pct = ((avg_second - avg_first) / avg_first) * 100

        if change_pct >= 20:
            self.recommendations.append({
                "title": f"📈 استهلاكك زاد {change_pct:.0f}% مؤخراً",
                "description": (
                    f"متوسط استهلاكك اليومي زاد من {avg_first:.1f} kWh لـ {avg_second:.1f} kWh. "
                    "راجع الأجهزة اللي شغلتها الفترة دي."
                ),
                "potential_savings": {
                    "kwh_savings": round(avg_second * 0.15, 2),
                    "percentage": 15.0,
                    "estimated_cost_reduction": round(avg_second * 0.0225, 2),
                },
                "affected_device": None,
                "implementation_difficulty": "easy",
                "estimated_time_to_implement": "immediate",
                "actions": ["راجع الأجهزة المضافة حديثاً", "تأكد من إيقاف الأجهزة غير المستخدمة"],
                "priority": "medium",
                "based_on": "real_data",
            })
        elif change_pct <= -15:
            self.recommendations.append({
                "title": f"👏 استهلاكك قل {abs(change_pct):.0f}%! استمر كده!",
                "description": (
                    f"متوسط استهلاكك اليومي قل من {avg_first:.1f} kWh لـ {avg_second:.1f} kWh. "
                    "تحسن ملحوظ! استمر في عاداتك الجيدة."
                ),
                "potential_savings": {
                    "kwh_savings": round(avg_first - avg_second, 2),
                    "percentage": abs(round(change_pct, 1)),
                    "estimated_cost_reduction": round((avg_first - avg_second) * 0.15, 2),
                },
                "affected_device": None,
                "implementation_difficulty": "easy",
                "estimated_time_to_implement": "immediate",
                "actions": ["استمر في عاداتك الحالية", "شارك نتيجتك مع العيلة"],
                "priority": "low",
                "based_on": "real_data",
            })

    def _check_always_on_device(
        self,
        user_id: str,
        per_device_data: List[Dict[str, Any]],
        devices: List[Dict[str, Any]],
    ):
        """اكتشاف جهاز شغال 24 ساعة."""
        if not per_device_data:
            return

        # تجميع عدد مرات ظهور كل جهاز
        device_appearances: Dict[str, int] = {}
        device_totals: Dict[str, float] = {}
        for item in per_device_data:
            name = item.get("device_name", item.get("device_id", "unknown"))
            device_appearances[name] = device_appearances.get(name, 0) + 1
            device_totals[name] = device_totals.get(name, 0) + item.get("total", item.get("consumption", 0))

        # لو جهاز ظهر في كل الأيام (7 أيام)
        max_days = max(device_appearances.values()) if device_appearances else 0
        for name, count in device_appearances.items():
            if count >= 7 and device_totals.get(name, 0) > 0:
                self.recommendations.append({
                    "title": f"جهاز {name} شغال كل يوم",
                    "description": (
                        f"جهاز {name} سجل استهلاك كل يوم في الأسبوع ده ({count} أيام). "
                        "لو مش محتاج يكون شغال طول الوقت، جرب توقفه شوية."
                    ),
                    "potential_savings": {
                        "kwh_savings": round(device_totals[name] * 0.1, 2),
                        "percentage": 10.0,
                        "estimated_cost_reduction": round(device_totals[name] * 0.015, 2),
                    },
                    "affected_device": name,
                    "implementation_difficulty": "easy",
                    "estimated_time_to_implement": "immediate",
                    "actions": [
                        f"راجع جدول تشغيل {name}",
                        "استخدم مؤقت زمني لو أمكن",
                    ],
                    "priority": "medium",
                    "based_on": "real_data",
                })
                return  # نكتفي بواحد

    def _add_seasonal_tip(self, user_id: str, summary: Dict[str, Any]):
        """إضافة نصيحة عامة مفيدة."""
        total = summary.get("total_consumption", 0)
        month = datetime.utcnow().month

        # نصائح موسمية
        if month in [6, 7, 8]:  # صيف
            tip = {
                "title": "☀️ نصيحة الصيف: حافظ على برودة البيت",
                "description": (
                    "في الصيف، المكيفات بتستهلك لحد 60% من طاقة البيت. "
                    "اغلق الستاير وقت الظهر، ونضف فلاتر المكيف كل أسبوعين."
                ),
                "actions": ["اغلق الستاير وقت الظهر", "نضف فلاتر المكيف", "اضبط الحرارة على 24°C"],
            }
        elif month in [12, 1, 2]:  # شتا
            tip = {
                "title": "❄️ نصيحة الشتا: دفّي البيت بكفاءة",
                "description": (
                    "في الشتا، السخانات بتستهلك طاقة كبيرة. "
                    "اضبط السخان على 50°C واستخدم العزل الحراري."
                ),
                "actions": ["اضبط السخان على 50°C", "استخدم عزل للأنابيب", "استحم بمية دافية مش سخنة"],
            }
        else:
            tip = {
                "title": "💡 نصيحة عامة لتوفير الطاقة",
                "description": (
                    "افصل الأجهزة الإلكترونية من الفيشة لو مش بتستخدمها. "
                    "الأجهزة في وضع الاستعداد (Standby) بتستهلك لحد 10% من طاقة البيت."
                ),
                "actions": ["افصل الشواحن بعد الاستخدام", "استخدم مشترك كهرباء بفيشة", "أوقف التلفزيون بدل standby"],
            }

        self.recommendations.append({
            "title": tip["title"],
            "description": tip["description"],
            "potential_savings": {
                "kwh_savings": round(total * 0.05, 2),
                "percentage": 5.0,
                "estimated_cost_reduction": round(total * 0.0075, 2),
            },
            "affected_device": None,
            "implementation_difficulty": "easy",
            "estimated_time_to_implement": "immediate",
            "actions": tip["actions"],
            "priority": "low",
            "based_on": "rule_based",
        })