from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import logging

from beanie import PydanticObjectId

from app.consumption.models import ConsumptionRecord, DeviceType
from app.devices.models import Device, DeviceStatus, DeviceCommand, CommandStatus
from app.plans.models import Plan, Subscription

logger = logging.getLogger(__name__)


class ConsumptionService:

    @staticmethod
    async def get_active_subscription(user_id: str) -> Optional[Subscription]:
        """ترجع الباقة النشطة."""
        return await Subscription.find_one(
            Subscription.user_id == user_id,
            Subscription.billing.status == "active"
        )

    @staticmethod
    async def get_active_subscription_id(user_id: str) -> Optional[str]:
        sub = await ConsumptionService.get_active_subscription(user_id)
        return str(sub.id) if sub else None

    @staticmethod
    async def _check_quota(user_id: str, subscription_id: str) -> tuple:
        """
        التحقق من استهلاك الباقة.
        Returns: (quota: float, used: float, is_exceeded: bool)
        """
        if not subscription_id or subscription_id == "unknown":
            return 0.0, 0.0, False

        sub = await ConsumptionService.get_active_subscription(user_id)
        if not sub or not sub.plan_id:
            return 0.0, 0.0, False

        try:
            plan = await Plan.get(PydanticObjectId(sub.plan_id))
            if not plan:
                return 0.0, 0.0, False
        except:
            return 0.0, 0.0, False

        quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0))
        if quota <= 0:
            return 0.0, 0.0, False

        # حساب الاستهلاك الحالي
        records = await ConsumptionRecord.find(
            ConsumptionRecord.user_id == user_id,
            ConsumptionRecord.subscription_id == subscription_id,
        ).to_list()
        used = sum(r.consumption_value for r in records)

        return quota, used, used >= quota

    @staticmethod
    async def record_consumption(
        device_id: str,
        consumption_value: float,
        timestamp: Optional[datetime] = None,
        device_type: Optional[str] = "meter",
    ) -> dict:
        device = await Device.find_one(Device.device_id == device_id)
        if not device:
            raise ValueError(f"Device not found: {device_id}")

        subscription_id = await ConsumptionService.get_active_subscription_id(device.user_id)

        # ⭐ التحقق من الباقة قبل التسجيل
        if subscription_id and subscription_id != "unknown":
            quota, used, is_exceeded = await ConsumptionService._check_quota(
                device.user_id, subscription_id
            )
            if is_exceeded:
                # ⭐ إنشاء أمر إيقاف للجهاز
                command = DeviceCommand(
                    device_id=device_id,
                    user_id=device.user_id,
                    command="stop_meter",
                    parameters={
                        "reason": "quota_exceeded",
                        "quota": quota,
                        "used": used,
                        "timestamp": datetime.utcnow().isoformat(),
                    },
                )
                await command.save()
                logger.warning(f"QUOTA EXCEEDED: device={device_id}, used={used}/{quota}")
                raise ValueError(f"Plan quota exceeded ({used}/{quota} kWh). Please renew your plan.")

        record = ConsumptionRecord(
            user_id=device.user_id,
            device_id=device_id,
            subscription_id=subscription_id or "unknown",
            device_type=device.device_type,
            consumption_value=consumption_value,
            timestamp=timestamp or datetime.utcnow(),
        )
        await record.save()

        # ⭐ تحديث حالة الجهاز ووقت آخر بيانات
        device.status = DeviceStatus.ONLINE
        device.last_data_at = datetime.utcnow()
        device.last_heartbeat = datetime.utcnow()
        stats = device.statistics or {}
        stats["total_energy"] = float(stats.get("total_energy", 0.0)) + consumption_value
        device.statistics = stats
        device.updated_at = datetime.utcnow()
        await device.save()

        return {
            "id": str(record.id),
            "device_id": record.device_id,
            "user_id": record.user_id,
            "subscription_id": record.subscription_id,
            "consumption_value": record.consumption_value,
            "timestamp": record.timestamp,
            "recorded_at": record.recorded_at,
        }

    @staticmethod
    async def _get_records_for_current_plan(user_id: str, days: int = 30) -> List[ConsumptionRecord]:
        """سجلات الباقة النشطة فقط."""
        subscription_id = await ConsumptionService.get_active_subscription_id(user_id)
        start_date = datetime.utcnow() - timedelta(days=days)

        if not subscription_id:
            return []

        return await ConsumptionRecord.find(
            ConsumptionRecord.user_id == user_id,
            ConsumptionRecord.subscription_id == subscription_id,
            ConsumptionRecord.timestamp >= start_date,
        ).to_list()

    @staticmethod
    async def _get_records_all_time(user_id: str, days: int = 365) -> List[ConsumptionRecord]:
        start_date = datetime.utcnow() - timedelta(days=days)
        return await ConsumptionRecord.find(
            ConsumptionRecord.user_id == user_id,
            ConsumptionRecord.timestamp >= start_date,
        ).to_list()

    @staticmethod
    async def get_daily_consumption(user_id: str, days: int = 7, current_plan_only: bool = True) -> List[dict]:
        records = await ConsumptionService._get_records_for_current_plan(user_id, days) if current_plan_only else await ConsumptionService._get_records_all_time(user_id, days)

        daily_data: Dict[str, float] = {}
        for r in records:
            key = r.timestamp.date().isoformat()
            daily_data[key] = daily_data.get(key, 0.0) + r.consumption_value

        return [{"date": d, "consumption": v, "total": v, "avg_power": v/24, "peak_power": v/24} for d, v in sorted(daily_data.items())]

    @staticmethod
    async def get_monthly_consumption(user_id: str, months: int = 12) -> List[dict]:
        records = await ConsumptionService._get_records_all_time(user_id, months * 30)
        monthly: Dict[str, dict] = {}
        for r in records:
            key = r.timestamp.strftime("%Y-%m")
            if key not in monthly:
                monthly[key] = {"total": 0.0, "days": set()}
            monthly[key]["total"] += r.consumption_value
            monthly[key]["days"].add(r.timestamp.date())

        return [{"month": m, "consumption": d["total"], "total": d["total"], "avg_daily": d["total"]/len(d["days"]) if d["days"] else 0, "peak_daily": d["total"]/len(d["days"]) if d["days"] else 0} for m, d in sorted(monthly.items())]

    @staticmethod
    async def compute_current_plan_summary(user_id: str) -> dict:
        sub = await ConsumptionService.get_active_subscription(user_id)
        records = await ConsumptionService._get_records_for_current_plan(user_id, 30)

        total = sum(r.consumption_value for r in records)
        active_days = len(set(r.timestamp.date() for r in records)) or 1
        daily_avg = total / active_days
        peak = max((r.consumption_value for r in records), default=0.0)
        device_count = await Device.find(Device.user_id == user_id).count()

        quota = 0.0
        if sub and sub.plan_id:
            try:
                plan = await Plan.get(PydanticObjectId(sub.plan_id))
                quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0)) if plan else 0.0
            except:
                pass

        usage_pct = (total / quota * 100) if quota > 0 else 0.0

        return {
            "total_consumption": total,
            "average_daily": daily_avg,
            "daily_average": daily_avg,
            "monthly_average": total,
            "total_devices": device_count,
            "remaining_quota": max(quota - total, 0.0),
            "usage_percentage": usage_pct,
            "trend": "stable",
            "peak_hour": 12,
            "peak_consumption": peak,
            "estimated_cost": total * 0.15,
            "estimated_monthly_cost": total * 0.15,
        }

    @staticmethod
    async def compute_historical_summary(user_id: str) -> dict:
        records = await ConsumptionService._get_records_all_time(user_id, 365)
        total = sum(r.consumption_value for r in records)
        days = len(set(r.timestamp.date() for r in records)) or 1
        daily_avg = total / days
        peak = max((r.consumption_value for r in records), default=0.0)

        return {
            "total_consumption": total,
            "average_daily": daily_avg,
            "daily_average": daily_avg,
            "monthly_average": total/12 if total > 0 else 0,
            "total_devices": await Device.find(Device.user_id == user_id).count(),
            "trend": "stable",
            "peak_hour": 12,
            "peak_consumption": peak,
            "estimated_cost": total * 0.15,
            "estimated_monthly_cost": (total/12)*0.15 if total > 0 else 0,
        }

    @staticmethod
    async def get_per_device_daily(user_id: str, device_id: str = None, days: int = 7, current_plan_only: bool = True) -> List[dict]:
        records = await ConsumptionService._get_records_for_current_plan(user_id, days) if current_plan_only else await ConsumptionService._get_records_all_time(user_id, days)
        if device_id:
            records = [r for r in records if r.device_id == device_id]

        name_cache: Dict[str, str] = {}
        async def get_name(did: str) -> str:
            if did not in name_cache:
                d = await Device.find_one(Device.device_id == did)
                name_cache[did] = d.name if d else did
            return name_cache[did]

        grouped: Dict[tuple, float] = {}
        for r in records:
            key = (r.device_id, r.timestamp.date().isoformat())
            grouped[key] = grouped.get(key, 0.0) + r.consumption_value

        return [{"device_id": did, "device_name": await get_name(did), "date": day, "total": total, "consumption": total} for (did, day), total in sorted(grouped.items())]