from fastapi import FastAPI, Depends, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timedelta
from typing import List, Optional
import logging
import uuid

from app.core.config import settings
from app.database.mongodb import connect_to_mongo, close_mongo_connection, init_db

logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="IoT Energy Monitoring and Device Management Platform",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.auth.service import AuthService
from app.auth.schemas import (
    UserRegister, UserLogin, TokenResponse, PasswordChange,
    RefreshTokenRequest, LogoutRequest,
)
from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.devices.models import Device, DeviceStatus, DeviceType, DeviceCommand, CommandStatus
from app.devices.schemas import DeviceCreate
from app.consumption.models import ConsumptionRecord
from app.consumption.schemas import ConsumptionCreate
from app.consumption.service import ConsumptionService
from app.plans.models import Plan, Subscription, PlanTier
from app.alerts.models import Alert
from app.ai.smart_advisor.recommendation_service import RecommendationService
from beanie import PydanticObjectId


async def seed_default_plans():
    if await Plan.count() > 0:
        return
    seeds = [
        ("Basic", "basic", 9.99, 20.0, 5),
        ("Pro", "pro", 24.99, 50.0, 20),
        ("Enterprise", "enterprise", 79.99, 100.0, 100),
    ]
    for name, tier, cost, quota, max_devices in seeds:
        plan = Plan(
            name=name, description=f"{name} energy monitoring plan",
            tier=PlanTier(tier),
            pricing={"monthly_cost": cost, "currency": "USD", "billing_cycle": 30, "annual_discount": 0.0},
            limits={"max_devices": max_devices, "max_daily_consumption_kwh": quota, "max_users": 1, "data_retention_days": 90, "api_requests_per_day": 1000},
            features={"real_time_monitoring": True, "analytics": True, "ai_insights": tier != "basic", "device_commands": tier != "basic", "alerts": True},
        )
        await plan.save()
    logger.info("Seeded default plans")


@app.on_event("startup")
async def startup_event():
    await connect_to_mongo()
    await init_db()
    await seed_default_plans()


@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()


def serialize_user(user: User) -> dict:
    return {"id": str(user.id), "username": user.username, "email": user.email, "first_name": user.first_name, "last_name": user.last_name, "phone": user.phone, "avatar_url": user.avatar_url, "role": user.role.value if hasattr(user.role, "value") else user.role, "is_active": user.is_active, "is_verified": user.is_verified, "created_at": user.created_at, "last_login": user.last_login}


def serialize_device(d: Device) -> dict:
    # ⭐ حساب الحالة تلقائياً بناءً على آخر بيانات
    if d.last_data_at:
        seconds_since_last_data = (datetime.utcnow() - d.last_data_at).total_seconds()
        is_active = seconds_since_last_data < 5
        status_str = "online" if is_active else "offline"
    else:
        is_active = False
        status_str = "offline"

    return {
        "id": str(d.id),
        "device_id": d.device_id,
        "device_name": d.name,
        "name": d.name,
        "user_id": d.user_id,
        "location": d.location,
        "device_type": d.device_type.value if hasattr(d.device_type, "value") else d.device_type,
        "model": d.model,
        "firmware_version": d.firmware_version,
        "is_active": is_active,
        "status": status_str,
        "last_seen": d.last_data_at or d.last_heartbeat,
        "last_heartbeat": d.last_heartbeat,
        "last_data_at": d.last_data_at,
        "specifications": d.specifications,
        "statistics": d.statistics,
        "created_at": d.created_at,
        "updated_at": d.updated_at,
    }


def serialize_plan(p: Plan) -> dict:
    return {"id": str(p.id), "plan_name": p.name, "name": p.name, "description": p.description, "tier": p.tier.value if hasattr(p.tier, "value") else p.tier, "total_quota": float(p.limits.get("max_daily_consumption_kwh", 0.0)), "limit": float(p.limits.get("max_daily_consumption_kwh", 0.0)), "duration_days": int(p.pricing.get("billing_cycle", 30)), "pricing": p.pricing, "limits": p.limits, "features": p.features, "created_at": p.created_at}

def serialize_alert(a: Alert) -> dict:
    cond = a.condition if isinstance(a.condition, dict) else {}
    return {"id": str(a.id), "user_id": a.user_id, "alert_type": a.alert_type.value if hasattr(a.alert_type, "value") else a.alert_type, "message": a.description or a.title, "threshold_percentage": float(cond.get("threshold", 0.0)), "current_usage_percentage": float(cond.get("actual_value", 0.0)), "created_at": a.created_at}


@app.get("/", tags=["Health"])
async def root():
    return {"name": settings.APP_NAME, "version": settings.APP_VERSION, "status": "running"}

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "environment": settings.ENVIRONMENT}


# ============= AUTH =============
@app.post("/api/v1/auth/register", tags=["Auth"])
async def register(user_data: UserRegister): return serialize_user(await AuthService.register(user_data))

@app.post("/api/v1/auth/login", response_model=TokenResponse, tags=["Auth"])
async def login(login_data: UserLogin):
    a, r = await AuthService.login(login_data)
    return TokenResponse(access_token=a, refresh_token=r, expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)

@app.post("/api/v1/auth/refresh", response_model=TokenResponse, tags=["Auth"])
async def refresh(body: RefreshTokenRequest):
    a = await AuthService.refresh_token(body.refresh_token)
    return TokenResponse(access_token=a, refresh_token=body.refresh_token, expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)

@app.post("/api/v1/auth/logout", tags=["Auth"])
async def logout(body: Optional[LogoutRequest] = None, current_user: User = Depends(get_current_user)):
    await AuthService.logout(str(current_user.id), body.refresh_token if body else None)
    return {"message": "Logged out"}

@app.get("/api/v1/users/me", tags=["Users"])
async def get_current_user_info(current_user: User = Depends(get_current_user)): return serialize_user(current_user)

@app.post("/api/v1/auth/change-password", tags=["Auth"])
async def change_password(password_data: PasswordChange, current_user: User = Depends(get_current_user)):
    await AuthService.change_password(str(current_user.id), password_data.old_password, password_data.new_password)
    return {"message": "Password changed"}


# ============= DEVICES =============
@app.get("/api/v1/devices", tags=["Devices"])
async def get_devices(current_user: User = Depends(get_current_user)):
    devices = await Device.find(Device.user_id == str(current_user.id)).to_list()
    return [serialize_device(d) for d in devices]

@app.post("/api/v1/devices", tags=["Devices"])
async def create_device(device_data: DeviceCreate, current_user: User = Depends(get_current_user)):
    did = device_data.device_id or f"dev-{uuid.uuid4().hex[:12]}"
    if await Device.find_one(Device.device_id == did): raise HTTPException(400, "Device exists")
    d = Device(user_id=str(current_user.id), device_id=did, name=device_data.resolved_name, location=device_data.location, device_type=device_data.device_type or DeviceType.METER, model=device_data.model, firmware_version=device_data.firmware_version)
    await d.save()
    return serialize_device(d)

@app.get("/api/v1/devices/{device_id}", tags=["Devices"])
async def get_device(device_id: str, current_user: User = Depends(get_current_user)):
    d = await Device.find_one(Device.device_id == device_id, Device.user_id == str(current_user.id))
    if not d: raise HTTPException(404, "Not found")
    return serialize_device(d)

@app.delete("/api/v1/devices/{device_id}", tags=["Devices"])
async def delete_device(device_id: str, current_user: User = Depends(get_current_user)):
    d = await Device.find_one(Device.device_id == device_id, Device.user_id == str(current_user.id))
    if not d: raise HTTPException(404, "Not found")
    await d.delete()
    return {"message": "Deleted"}

@app.post("/api/v1/devices/{device_id}/heartbeat", tags=["Devices"])
async def device_heartbeat(device_id: str):
    d = await Device.find_one(Device.device_id == device_id)
    if not d: raise HTTPException(404, "Not found")
    d.status = DeviceStatus.ONLINE
    d.last_heartbeat = datetime.utcnow()
    d.last_data_at = datetime.utcnow()  # ⭐ تحديث وقت آخر بيانات
    d.updated_at = datetime.utcnow()
    await d.save()
    return {"message": "Heartbeat", "status": d.status.value}

@app.post("/api/v1/devices/{device_id}/telemetry", tags=["Devices"])
async def device_telemetry(device_id: str, data: ConsumptionCreate):
    try:
        r = await ConsumptionService.record_consumption(device_id=device_id, consumption_value=data.consumption_value, timestamp=data.timestamp, device_type=data.device_type)
        return {"message": "Recorded", "id": r["id"]}
    except ValueError as e: raise HTTPException(404, str(e))
   

# ============= CONSUMPTION =============
@app.post("/api/v1/consumption", tags=["Consumption"])
async def record_consumption(c: ConsumptionCreate):
    try:
        r = await ConsumptionService.record_consumption(device_id=c.device_id, consumption_value=c.consumption_value, timestamp=c.timestamp, device_type=c.device_type)
        return r
    # except ValueError as e: raise HTTPException(404, str(e))
    except ValueError as e: raise HTTPException(status_code=403, detail=str(e))
@app.get("/api/v1/consumption/daily", tags=["Consumption"])
async def get_daily_consumption(current_user: User = Depends(get_current_user), days: int = 7):
    return await ConsumptionService.get_daily_consumption(user_id=str(current_user.id), days=days, current_plan_only=True)

@app.get("/api/v1/consumption/monthly", tags=["Consumption"])
async def get_monthly_consumption(current_user: User = Depends(get_current_user), months: int = 12):
    return await ConsumptionService.get_monthly_consumption(user_id=str(current_user.id), months=months)

@app.get("/api/v1/consumption/summary", tags=["Consumption"])
async def get_consumption_summary(current_user: User = Depends(get_current_user)):
    return await ConsumptionService.compute_current_plan_summary(user_id=str(current_user.id))

@app.get("/api/v1/consumption/per-device-daily", tags=["Consumption"])
async def get_per_device_daily_consumption(current_user: User = Depends(get_current_user), device_id: str = None, days: int = 7):
    return await ConsumptionService.get_per_device_daily(user_id=str(current_user.id), device_id=device_id, days=days, current_plan_only=True)


# ============= PLANS =============
@app.get("/api/v1/plans/available", tags=["Plans"])
async def get_available_plans(current_user: User = Depends(get_current_user)):
    return [serialize_plan(p) for p in await Plan.find(Plan.is_active == True).to_list()]


@app.post("/api/v1/plans/subscribe", tags=["Plans"])
async def subscribe_to_plan(body: dict, current_user: User = Depends(get_current_user)):
    plan_id = body.get("plan_id")
    if not plan_id: raise HTTPException(400, "plan_id required")
    try: plan = await Plan.get(PydanticObjectId(plan_id))
    except: plan = None
    if not plan: raise HTTPException(404, "Plan not found")

    # ⭐ عرف المتغيرات الأول قبل أي استخدام
    total_quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0))
    started = datetime.utcnow()
    duration = int(plan.pricing.get("billing_cycle", 30))

    # تعطيل الباقات القديمة
    for old in await Subscription.find(Subscription.user_id == str(current_user.id)).to_list():
        old.billing["status"] = "expired"
        old.updated_at = datetime.utcnow()
        await old.save()

    # إنشاء اشتراك جديد
    sub = Subscription(user_id=str(current_user.id), plan_id=str(plan.id))
    sub.billing = {"status": "active", "started_at": started}
    await sub.save()
    logger.info(f"NEW SUBSCRIPTION: {sub.id}")

    # ⭐ إرسال أمر استئناف لكل أجهزة المستخدم
    devices = await Device.find(Device.user_id == str(current_user.id)).to_list()
    for device in devices:
        resume_command = DeviceCommand(
            device_id=device.device_id,
            user_id=str(current_user.id),
            command="resume_meter",
            parameters={
                "reason": "plan_renewed",
                "plan_name": plan.name,
                "quota": total_quota,
                "timestamp": started.isoformat(),
            },
        )
        await resume_command.save()
    logger.info(f"Sent resume command to {len(devices)} devices")

    return {
        "id": str(sub.id),
        "user_id": sub.user_id,
        "plan_id": sub.plan_id,
        "start_date": started.isoformat(),
        "end_date": (started + timedelta(days=duration)).isoformat(),
        "remaining_quota": total_quota,
        "is_active": True,
        "created_at": sub.created_at,
        "updated_at": sub.updated_at,
        "plan_name": plan.name,
        "name": plan.name,
        "total_quota": total_quota,
        "limit": total_quota,
    }

@app.get("/api/v1/plans/subscription", tags=["Plans"])
async def get_subscription(current_user: User = Depends(get_current_user)):
    sub = await Subscription.find_one(
        Subscription.user_id == str(current_user.id),
        Subscription.billing.status == "active"
    )
    if not sub:
        sub = await Subscription.find_one(Subscription.user_id == str(current_user.id))
    if not sub: raise HTTPException(404, "No subscription")

    plan = None
    if sub.plan_id:
        try: plan = await Plan.get(PydanticObjectId(sub.plan_id))
        except: pass

    total_quota = float(plan.limits.get("max_daily_consumption_kwh", 0.0)) if plan else 0.0
    duration = int(plan.pricing.get("billing_cycle", 30)) if plan else 30
    started_at = sub.billing.get("started_at") if isinstance(sub.billing, dict) else datetime.utcnow()
    if isinstance(started_at, str):
        try: started_at = datetime.fromisoformat(started_at)
        except: started_at = datetime.utcnow()

    used = await _current_subscription_consumption(
        user_id=str(current_user.id),
        subscription_id=str(sub.id),
        days=duration
    )

    return {
        "id": str(sub.id),
        "user_id": sub.user_id,
        "plan_id": sub.plan_id or "",
        "start_date": started_at,
        "end_date": started_at + timedelta(days=duration),
        "remaining_quota": max(total_quota - used, 0.0),
        "is_active": sub.billing.get("status") == "active" if isinstance(sub.billing, dict) else True,
        "created_at": sub.created_at,
        "updated_at": sub.updated_at,
        "plan_name": plan.name if plan else None,
        "name": plan.name if plan else None,
        "total_quota": total_quota,
        "limit": total_quota,
    }



# ============= ALERTS =============
async def build_usage_alerts(current_user: User) -> List[dict]:
    """
    بناء تنبيهات الاستخدام - باستخدام ملخص الباقة الحالية فقط.
    """
    summary = await ConsumptionService.compute_current_plan_summary(
        user_id=str(current_user.id),
    )
    usage = summary["usage_percentage"]
    alerts = []
    now = datetime.utcnow()
    
    thresholds = [
        (100.0, "quota_exceeded", "🚨 Critical: You have used 100% of your energy quota!"),
        (95.0, "critical_usage", "🔴 Critical: You have used over 95% of your energy quota."),
        (90.0, "high_usage", "🟠 Warning: You have used over 90% of your energy quota."),
        (80.0, "moderate_usage", "🟡 Notice: You have used over 80% of your energy quota."),
    ]
    
    for thr, atype, msg in thresholds:
        if usage >= thr:
            alerts.append({
                "id": f"usage-{atype}-{int(usage)}",
                "user_id": str(current_user.id),
                "alert_type": atype,
                "message": msg,
                "threshold_percentage": thr,
                "current_usage_percentage": round(usage, 1),
                "created_at": now,
            })
            break  # بيرجع أعلى تنبيه واحد بس
    
    return alerts


@app.get("/api/v1/alerts", tags=["Alerts"])
async def get_alerts(current_user: User = Depends(get_current_user), limit: int = 20):
    # ⭐ التنبيهات المخزنة في قاعدة البيانات
    stored = (
        await Alert.find(Alert.user_id == str(current_user.id))
        .sort([("created_at", -1)])
        .limit(limit)
        .to_list()
    )
    result = [serialize_alert(a) for a in stored]
    
    # ⭐ إضافة تنبيهات الاستخدام الحي
    result.extend(await build_usage_alerts(current_user))
    
    return result[:limit]


# ============= AI =============
@app.get("/api/v1/ai/analysis", tags=["AI"])
async def get_ai_analysis(current_user: User = Depends(get_current_user)):
    """
    تحليل AI - اكتشاف anomalies في الاستهلاك.
    """
    from app.ai.anomaly_detection.service import AnomalyService

    service = AnomalyService()
    result = await service.analyze(str(current_user.id))

    return {
        "analysis": result["summary"],
        "data": result,
    }
    
    
@app.get("/api/v1/ai/prediction", tags=["AI"])
async def get_ai_prediction(current_user: User = Depends(get_current_user)):
    """
    تنبؤات AI - تستخدم بيانات الاستهلاك الفعلية.
    """
    from app.ai.forecasting.service import ForecastingService

    service = ForecastingService()
    prediction = await service.get_prediction(str(current_user.id))

    predicted_month = prediction["predicted_monthly_consumption"]
    predicted_daily = prediction["predicted_daily_consumption"]
    confidence = prediction["confidence_score"]
    trend = prediction["trend"]

    if predicted_daily <= 0:
        text = "Not enough data to make a prediction. Start sending consumption readings."
    else:
        trend_emoji = "📈" if trend == "increasing" else "📉" if trend == "decreasing" else "➡️"
        text = (
            f"{trend_emoji} Based on your last {prediction['based_on_days']} days, "
            f"your predicted consumption for the next 30 days is "
            f"~{predicted_month:.1f} kWh ({predicted_daily:.1f} kWh/day), "
            f"with {int(confidence * 100)}% confidence. Trend: {trend}."
        )

    return {
        "prediction": text,
        "data": {
            "predicted_daily_consumption": predicted_daily,
            "predicted_monthly_consumption": predicted_month,
            "confidence_score": confidence,
            "trend": trend,
            "trend_change_percent": prediction.get("trend_change_percent", 0),
            "based_on_days": prediction.get("based_on_days", 0),
        },
    }


@app.get("/api/v1/ai/plan-exhaustion", tags=["AI"])
async def get_plan_exhaustion(current_user: User = Depends(get_current_user)):
    """
    توقع نفاذ الباقة - يستخدم الباقة الحالية.
    """
    from app.ai.forecasting.service import ForecastingService

    service = ForecastingService()
    result = await service.get_plan_exhaustion(str(current_user.id))

    return {
        "exhaustion_info": result.get("message", ""),
        "data": result,
    }
# @app.get("/api/v1/ai/recommendations", tags=["AI"])
# async def get_ai_recommendations(current_user: User = Depends(get_current_user)):
#     return {"recommendation": "Turn off unused devices", "data": []}
@app.get("/api/v1/ai/recommendations", tags=["AI"])
async def get_ai_recommendations(current_user: User = Depends(get_current_user)):
    """
    توصيات AI ذكية - مبنية على بيانات المستخدم الحقيقية.
    """
    from app.ai.smart_advisor.recommendation_service import RecommendationService

    service = RecommendationService()

    # ⭐ توليد توصيات جديدة (أو جلب المخزنة)
    try:
        stored = await RecommendationService.get_active(str(current_user.id))
        if stored:
            # لو فيه توصيات مخزنة، نرجعها
            lines = []
            for i, rec in enumerate(stored, 1):
                title = rec.get("title", "Recommendation")
                desc = rec.get("description", "")
                lines.append(f"{i}. {title}: {desc}")
            text = "\n".join(lines)
            return {"recommendation": text, "data": stored}
        else:
            # نولد توصيات جديدة
            new_recs = await service.generate_and_save(str(current_user.id))
            lines = []
            for i, rec in enumerate(new_recs, 1):
                title = rec.get("title", "Recommendation")
                desc = rec.get("description", "")
                lines.append(f"{i}. {title}: {desc}")
            text = "\n".join(lines) if lines else "No specific recommendations at this time."
            return {"recommendation": text, "data": new_recs}
    except Exception as e:
        logger.error(f"Failed to generate recommendations: {e}")
        # Fallback لنصيحة عامة
        tips = [
            "Shift high-consumption activities to off-peak hours.",
            "Unplug idle devices to reduce standby power draw.",
            "Set air-conditioning to 24°C to balance comfort and savings.",
        ]
        text = "\n".join(f"{i}. {t}" for i, t in enumerate(tips, 1))
        return {"recommendation": text, "data": [{"title": t} for t in tips]}

# ============= HELPER =============
async def _current_subscription_consumption(user_id: str, subscription_id: str, days: int = 30) -> float:
    start_date = datetime.utcnow() - timedelta(days=days)
    records = await ConsumptionRecord.find(
        ConsumptionRecord.user_id == user_id,
        ConsumptionRecord.subscription_id == subscription_id,
        ConsumptionRecord.timestamp >= start_date,
    ).to_list()
    return sum(r.consumption_value for r in records)

if __name__ == "__main__":
    import uvicorn
    import os
    # هيقرا البورت اللي ريلواي بيفرضه أوتوماتيك، ولو مش موجود (لوكال) هيشتغل على 8000
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port)
