from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional
from enum import Enum


class DeviceType(str, Enum):
    METER = "meter"
    BREAKER = "breaker"
    SENSOR = "sensor"


class ConsumptionRecord(Document):
    """Consumption record linked to both user and subscription."""
    user_id: str = Indexed()
    device_id: str = Indexed()
    subscription_id: str = Indexed()  # ⭐ الجديد - يربط الاستهلاك بالباقة

    # Simplified data format matching device send
    device_type: DeviceType
    consumption_value: float  # kWh

    timestamp: datetime
    recorded_at: datetime = Field(default_factory=datetime.utcnow)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "consumption_records"
        indexes = [
            "user_id",
            "device_id",
            "subscription_id",
            "timestamp",
            [("user_id", 1), ("timestamp", -1)],
            [("subscription_id", 1), ("timestamp", -1)],
        ]


class DailyAggregation(Document):
    """Pre-aggregated daily consumption data."""
    user_id: str = Indexed()
    device_id: str = Indexed()
    subscription_id: str = Indexed()  # ⭐ الجديد

    date: datetime  # YYYY-MM-DD

    statistics: dict = Field(
        default_factory=lambda: {
            "total_energy": 0.0,
            "avg_power": 0.0,
            "max_power": 0.0,
            "min_power": 0.0,
            "peak_hour": 0,
            "peak_power": 0.0,
            "hours": []  # hourly breakdown
        }
    )

    quality: dict = Field(
        default_factory=lambda: {
            "record_count": 0,
            "completeness": 0.0,
            "estimated_percentage": 0.0
        }
    )

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "daily_aggregations"


class MonthlyAggregation(Document):
    """Pre-aggregated monthly consumption data."""
    user_id: str = Indexed()
    device_id: str = Indexed()

    year_month: str  # YYYY-MM

    statistics: dict = Field(
        default_factory=lambda: {
            "total_energy": 0.0,
            "avg_daily_energy": 0.0,
            "max_daily_energy": 0.0,
            "min_daily_energy": 0.0,
            "avg_power": 0.0,
            "max_power": 0.0,
            "days": []
        }
    )

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "monthly_aggregations"