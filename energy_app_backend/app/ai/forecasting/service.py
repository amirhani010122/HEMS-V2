"""
خدمة التنبؤ - تجميع البيانات وتوليد التنبؤات.
"""
from typing import Dict, Any, Optional
import logging

from app.ai.forecasting.engine import ForecastingEngine
from app.consumption.service import ConsumptionService
from app.plans.models import Plan, Subscription
from beanie import PydanticObjectId

logger = logging.getLogger(__name__)


class ForecastingService:
    """خدمة التنبؤ بالاستهلاك."""

    def __init__(self):
        self.engine = ForecastingEngine()

    async def get_prediction(self, user_id: str) -> Dict[str, Any]:
        """
        توقع الاستهلاك الشهري للمستخدم.

        Args:
            user_id: معرف المستخدم

        Returns:
            تنبؤ كامل
        """
        # بيانات آخر 30 يوم
        daily_30 = await ConsumptionService.get_daily_consumption(
            user_id, days=30, current_plan_only=False  # كل التاريخ
        )

        # بيانات آخر 7 أيام (للتحليل)
        daily_7 = await ConsumptionService.get_daily_consumption(
            user_id, days=7, current_plan_only=False
        )

        # بيانات شهرية
        monthly = await ConsumptionService.get_monthly_consumption(user_id, months=6)

        # تنبؤ شهري
        monthly_prediction = self.engine.predict_monthly(daily_30)

        # اتجاه الاستهلاك
        trend = self.engine.predict_trend(daily_7, monthly)

        return {
            "predicted_daily_consumption": monthly_prediction["predicted_daily_kwh"],
            "predicted_monthly_consumption": monthly_prediction["predicted_monthly_kwh"],
            "confidence_score": monthly_prediction["confidence"],
            "trend": trend["trend"],
            "trend_change_percent": trend["change_percent"],
            "based_on_days": monthly_prediction["based_on_days"],
            "data_points": len(daily_30),
        }

    async def get_plan_exhaustion(self, user_id: str) -> Dict[str, Any]:
        """
        توقع متى الباقة هتخلص.

        Args:
            user_id: معرف المستخدم

        Returns:
            توقع النفاذ
        """
        # بيانات آخر 14 يوم (للباقة الحالية)
        daily = await ConsumptionService.get_daily_consumption(
            user_id, days=14, current_plan_only=True  # الباقة الحالية فقط
        )

        # لو مفيش بيانات كافية، نستخدم كل البيانات
        if not daily or len(daily) < 3:
            daily = await ConsumptionService.get_daily_consumption(
                user_id, days=30, current_plan_only=False
            )

        # تفاصيل الباقة
        remaining_quota = 0.0
        total_quota = 0.0
        has_plan = False

        sub = await Subscription.find_one(
            Subscription.user_id == user_id,
            Subscription.billing.status == "active",
        )
        if sub and sub.plan_id:
            try:
                plan = await Plan.get(PydanticObjectId(sub.plan_id))
                if plan:
                    total_quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0))
                    # حساب الاستهلاك الحالي
                    summary = await ConsumptionService.compute_current_plan_summary(user_id)
                    used = summary.get("total_consumption", 0)
                    remaining_quota = max(total_quota - used, 0)
                    has_plan = True
            except:
                pass

        if not has_plan:
            return {
                "has_plan": False,
                "message": "No active plan found. Subscribe to a plan to receive exhaustion forecasts.",
                "days_until_exhaustion": 999,
                "exhaustion_date": None,
                "will_exceed": False,
            }

        exhaustion = self.engine.predict_plan_exhaustion(
            daily_data=daily,
            remaining_quota=remaining_quota,
            total_quota=total_quota,
        )

        return {
            "has_plan": True,
            **exhaustion,
        }