from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional
from enum import Enum

class PlanTier(str, Enum):
    BASIC = "basic"
    PRO = "pro"
    ENTERPRISE = "enterprise"

class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    SUSPENDED = "suspended"

class Plan(Document):
    """Energy plan model."""
    name: str
    description: str
    tier: PlanTier
    
    pricing: dict = Field(
        default_factory=lambda: {
            "monthly_cost": 0.0,
            "currency": "USD",
            "billing_cycle": 30,
            "annual_discount": 0.0
        }
    )
    
    limits: dict = Field(
        default_factory=lambda: {
            "max_devices": 5,
            "max_daily_consumption_kwh": 100.0,
            "max_users": 1,
            "data_retention_days": 90,
            "api_requests_per_day": 1000
        }
    )
    
    features: dict = Field(
        default_factory=lambda: {
            "real_time_monitoring": True,
            "analytics": True,
            "ai_insights": False,
            "device_commands": False,
            "alerts": True,
            "multiple_locations": False,
            "api_access": False,
            "priority_support": False
        }
    )
    
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "plans"

class Subscription(Document):
    """User subscription to a plan."""
    user_id: str = Indexed(unique=True)
    plan_id: Optional[str] = None
    
    billing: dict = Field(
        default_factory=lambda: {
            "status": "active",
            "started_at": datetime.utcnow(),
            "current_period_start": datetime.utcnow(),
            "current_period_end": None,
            "renewal_date": None,
            "cancelled_at": None,
            "cancellation_reason": ""
        }
    )
    
    usage: dict = Field(
        default_factory=lambda: {
            "devices_used": 0,
            "daily_consumption_kwh": 0.0,
            "api_calls_today": 0,
            "api_calls_remaining": 1000
        }
    )
    
    payment: dict = Field(
        default_factory=lambda: {
            "method": "",
            "last_4_digits": "",
            "next_billing_date": None,
            "next_amount": 0.0,
            "auto_renew": True
        }
    )
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "subscriptions"
