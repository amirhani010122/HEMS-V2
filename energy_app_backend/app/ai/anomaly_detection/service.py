"""
خدمة اكتشاف anomalies.
"""
from typing import Dict, Any
import logging

from app.ai.anomaly_detection.engine import AnomalyEngine
from app.consumption.service import ConsumptionService

logger = logging.getLogger(__name__)


class AnomalyService:
    """خدمة اكتشاف الحالات الشاذة."""

    def __init__(self):
        self.engine = AnomalyEngine()

    async def analyze(self, user_id: str) -> Dict[str, Any]:
        """
        تحليل استهلاك المستخدم واكتشاف anomalies.

        Args:
            user_id: معرف المستخدم

        Returns:
            تقرير anomalies
        """
        # بيانات يومية (آخر 30 يوم)
        daily = await ConsumptionService.get_daily_consumption(
            user_id, days=30, current_plan_only=False
        )

        # بيانات لكل جهاز (آخر 7 أيام)
        per_device = await ConsumptionService.get_per_device_daily(
            user_id, days=7, current_plan_only=False
        )

        # تحليل
        result = self.engine.detect(daily_data=daily, per_device_data=per_device)

        return result