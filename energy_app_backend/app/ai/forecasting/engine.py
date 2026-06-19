"""
محرك التنبؤ بالاستهلاك.
يستخدم بيانات المستخدم الفعلية لتوقع الاستهلاك المستقبلي.
"""
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class ForecastingEngine:
    """محرك تنبؤ مبني على بيانات حقيقية."""

    def predict_daily(
        self,
        daily_data: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        if not daily_data:
            return {"predicted_daily_kwh": 0.0, "confidence": 0.0, "based_on_days": 0}

        values = [d.get("total", d.get("consumption", 0)) for d in daily_data]
        total = sum(values)
        days = len(values)
        avg_daily = total / days if days > 0 else 0

        if days >= 3:
            variance = sum((v - avg_daily) ** 2 for v in values) / days
            std_dev = variance ** 0.5
            confidence = max(0.5, 1.0 - (std_dev / (avg_daily + 0.01)))
        else:
            confidence = 0.6

        return {
            "predicted_daily_kwh": round(avg_daily, 2),
            "confidence": round(confidence, 2),
            "based_on_days": days,
        }

    def predict_monthly(
        self,
        daily_data: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        daily = self.predict_daily(daily_data)
        return {
            "predicted_monthly_kwh": round(daily["predicted_daily_kwh"] * 30, 2),
            "predicted_daily_kwh": daily["predicted_daily_kwh"],
            "confidence": daily["confidence"],
            "based_on_days": daily["based_on_days"],
        }

    def predict_plan_exhaustion(
        self,
        daily_data: List[Dict[str, Any]],
        remaining_quota: float,
        total_quota: float = 0.0,
    ) -> Dict[str, Any]:
        daily = self.predict_daily(daily_data)
        avg_daily = daily["predicted_daily_kwh"]

        if avg_daily <= 0:
            return {
                "days_until_exhaustion": 999,
                "exhaustion_date": None,
                "will_exceed": False,
                "usage_percentage": 0.0,
                "message": "No consumption data to predict.",
            }

        days_left = int(remaining_quota / avg_daily) if avg_daily > 0 else 999
        exhaustion_date = datetime.utcnow() + timedelta(days=days_left)
        will_exceed = days_left < 30

        if days_left <= 0:
            message = "Plan already exhausted!"
        elif days_left <= 3:
            message = f"Critical: {days_left} days remaining!"
        elif days_left <= 7:
            message = f"Warning: ~{days_left} days remaining."
        else:
            message = f"~{days_left} days remaining."

        return {
            "days_until_exhaustion": days_left,
            "exhaustion_date": exhaustion_date.isoformat(),
            "will_exceed": will_exceed,
            "usage_percentage": round((total_quota - remaining_quota) / total_quota * 100, 1) if total_quota > 0 else 0,
            "daily_average": round(avg_daily, 2),
            "remaining_quota": round(remaining_quota, 2),
            "total_quota": round(total_quota, 2),
            "message": message,
            "confidence": daily["confidence"],
        }

    def predict_trend(
        self,
        daily_data: List[Dict[str, Any]],
        monthly_data: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        if len(daily_data) < 7:
            return {"trend": "stable", "change_percent": 0.0}

        values = [d.get("total", d.get("consumption", 0)) for d in daily_data]
        avg_first = sum(values[:3]) / 3 if len(values) >= 3 else 0
        avg_last = sum(values[-3:]) / 3 if len(values) >= 3 else 0

        if avg_first <= 0:
            return {"trend": "stable", "change_percent": 0.0}

        change_pct = ((avg_last - avg_first) / avg_first) * 100

        if change_pct >= 10:
            trend = "increasing"
        elif change_pct <= -10:
            trend = "decreasing"
        else:
            trend = "stable"

        return {"trend": trend, "change_percent": round(change_pct, 1)}