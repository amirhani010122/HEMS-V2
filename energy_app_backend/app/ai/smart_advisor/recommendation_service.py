"""
خدمة التوصيات - تجميع البيانات وتوليد التوصيات.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging

from app.ai.smart_advisor.engine import RecommendationEngine
from app.consumption.service import ConsumptionService
from app.devices.models import Device
from app.plans.models import Plan, Subscription
from app.ai.smart_advisor.models import Recommendation
from beanie import PydanticObjectId

logger = logging.getLogger(__name__)


class RecommendationService:
    """خدمة توليد وإدارة التوصيات."""

    def __init__(self):
        self.engine = RecommendationEngine()

    async def generate_and_save(self, user_id: str) -> List[Dict[str, Any]]:
        """
        تجميع بيانات المستخدم، توليد توصيات، تخزينها، وإرجاعها.

        Args:
            user_id: معرف المستخدم

        Returns:
            قائمة التوصيات
        """
        # ═══════════════════════════════════════
        # 1. تجميع البيانات من المصادر المختلفة
        # ═══════════════════════════════════════

        # ملخص الاستهلاك
        summary = await ConsumptionService.compute_current_plan_summary(user_id)

        # بيانات يومية
        daily = await ConsumptionService.get_daily_consumption(user_id, days=7)

        # بيانات شهرية
        monthly = await ConsumptionService.get_monthly_consumption(user_id, months=6)

        # بيانات لكل جهاز
        per_device = await ConsumptionService.get_per_device_daily(user_id, days=7)

        # قائمة الأجهزة
        devices_raw = await Device.find(Device.user_id == user_id).to_list()
        devices = [
            {
                "device_id": d.device_id,
                "name": d.name,
                "type": d.device_type.value if hasattr(d.device_type, "value") else str(d.device_type),
            }
            for d in devices_raw
        ]

        # تفاصيل الباقة (اختياري)
        subscription = None
        sub = await Subscription.find_one(
            Subscription.user_id == user_id,
            Subscription.billing.status == "active",
        )
        if sub and sub.plan_id:
            try:
                plan = await Plan.get(PydanticObjectId(sub.plan_id))
                if plan:
                    total_quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0))
                    used = summary.get("total_consumption", 0)
                    subscription = {
                        "remaining_quota": max(total_quota - used, 0),
                        "total_quota": total_quota,
                        "is_active": True,
                    }
            except:
                pass

        # ═══════════════════════════════════════
        # 2. توليد التوصيات
        # ═══════════════════════════════════════
        recommendations = self.engine.generate(
            user_id=user_id,
            consumption_summary=summary,
            daily_data=daily,
            monthly_data=monthly,
            per_device_data=per_device,
            devices=devices,
            subscription=subscription,
        )

        # ═══════════════════════════════════════
        # 3. تخزين التوصيات في MongoDB
        # ═══════════════════════════════════════
        # نحذف التوصيات القديمة
        await Recommendation.find(
            Recommendation.user_id == user_id,
            Recommendation.status == "active",
        ).delete()

        # نخزن الجديدة
        saved = []
        for rec in recommendations[:5]:  # الحد الأقصى 5 توصيات
            doc = Recommendation(
                user_id=user_id,
                device_id=rec.get("affected_device"),
                recommendation=rec,
                status="active",
            )
            await doc.save()
            saved.append(rec)

        logger.info(f"Generated {len(saved)} recommendations for user {user_id}")
        return saved

    @staticmethod
    async def get_active(user_id: str) -> List[Dict[str, Any]]:
        """جلب التوصيات النشطة للمستخدم."""
        stored = await Recommendation.find(
            Recommendation.user_id == user_id,
            Recommendation.status == "active",
        ).limit(5).to_list()

        if stored:
            return [
                r.recommendation if isinstance(r.recommendation, dict) else {}
                for r in stored
            ]
        return []