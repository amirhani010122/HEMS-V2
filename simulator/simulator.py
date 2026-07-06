"""
IoT Simulator - نسخة بسيطة.
5 أجهزة منزلية، تتحكم فيهم، لو الباقة خلصت كلهم يقفوا.
"""
import asyncio
import random
import time
from datetime import datetime
from typing import Dict, List, Optional
from datetime import datetime, timedelta 
import httpx


# ═══════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════
BASE_URL = "https://hems-v2-production.up.railway.app/api/v1"
EMAIL = "amir@test.com"
PASSWORD = "1234567"

# DEVICES = [
#     {"id": "sim-meter",  "name": "Smart Meter",      "location": "Main Panel",   "base_kwh": 10.8,  "max_kwh": 30.0},
#     {"id": "sim-ac",     "name": "Air Conditioner",   "location": "Living Room",  "base_kwh": 20.0,  "max_kwh": 40.0},
#     {"id": "sim-fridge", "name": "Refrigerator",      "location": "Kitchen",      "base_kwh": 10.15, "max_kwh": 10.3},
#     {"id": "sim-heater", "name": "Water Heater",      "location": "Bathroom",     "base_kwh": 20.5,  "max_kwh": 50.0},
#     {"id": "sim-light",  "name": "Lighting",          "location": "Whole House",  "base_kwh": 10.1,  "max_kwh": 20.5},
# ]

DEVICES = [
    {"id": "sim-meter",  "name": "Smart Meter",      "location": "Main Panel",   "base_kwh": 0.8,  "max_kwh": 3.0},
    {"id": "sim-ac",     "name": "Air Conditioner",   "location": "Living Room",  "base_kwh": 1.5,  "max_kwh": 3.5},
    {"id": "sim-fridge", "name": "Refrigerator",      "location": "Kitchen",      "base_kwh": 0.12, "max_kwh": 0.25},
    {"id": "sim-heater", "name": "Water Heater",      "location": "Bathroom",     "base_kwh": 2.0,  "max_kwh": 4.5},
    {"id": "sim-light",  "name": "Lighting",          "location": "Whole House",  "base_kwh": 0.08, "max_kwh": 0.4},
]


TELEMETRY_INTERVAL = 2      # ثواني
HEARTBEAT_INTERVAL = 30     # ثواني
PLAN_CHECK_INTERVAL = 5     # ثواني


# ═══════════════════════════════════════════════════════════
# SIMULATOR
# ═══════════════════════════════════════════════════════════
class SmartHomeSimulator:
    def __init__(self):
        self.token: Optional[str] = None
        self.client: Optional[httpx.AsyncClient] = None
        self.device_states: Dict[str, bool] = {}  # True = ON, False = OFF
        self.total_consumption: Dict[str, float] = {}  # لكل جهاز
        self.plan_remaining: float = 0.0
        self.plan_active: bool = False
        self._running: bool = False
        
        # كل الأجهزة تبدأ في حالة OFF
        for d in DEVICES:
            self.device_states[d["id"]] = False
            self.total_consumption[d["id"]] = 0.0
    
    # ═══════════════════════════════════════════════════════
    # BACKEND API
    # ═══════════════════════════════════════════════════════
    @property
    def headers(self) -> Dict[str, str]:
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}
    
    async def login(self) -> bool:
        """تسجيل الدخول والحصول على JWT Token."""
        try:
            r = await self.client.post("/auth/login", json={
                "email": EMAIL, "password": PASSWORD
            })
            if r.status_code == 200:
                self.token = r.json()["access_token"]
                print(f"✅ Logged in")
                return True
            else:
                # نحاول نسجل الأول
                await self.client.post("/auth/register", json={
                    "email": EMAIL, "username": "amirhani", "password": PASSWORD
                })
                r = await self.client.post("/auth/login", json={
                    "email": EMAIL, "password": PASSWORD
                })
                if r.status_code == 200:
                    self.token = r.json()["access_token"]
                    print(f"✅ Registered & Logged in")
                    return True
            print(f"❌ Login failed: {r.status_code}")
            return False
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    async def register_devices(self):
        """تسجيل الأجهزة في الباك-إند (لو مش مسجلة)."""
        for d in DEVICES:
            try:
                r = await self.client.post("/devices", headers=self.headers, json={
                    "device_id": d["id"],
                    "device_name": d["name"],
                    "device_type": "meter",
                    "location": d["location"],
                })
                if r.status_code in (200, 201):
                    print(f"   📱 {d['name']} ({d['id']}) - Registered")
                elif r.status_code == 400:
                    print(f"   📱 {d['name']} ({d['id']}) - Already exists")
                else:
                    print(f"   ❌ {d['name']} - Failed ({r.status_code})")
            except Exception as e:
                print(f"   ❌ {d['name']} - Error: {e}")
    
    async def check_plan(self) -> bool:
        """التحقق من حالة الباقة."""
        try:
            r = await self.client.get("/plans/subscription", headers=self.headers)
            if r.status_code == 200:
                data = r.json()
                self.plan_remaining = data.get("remaining_quota", 0)
                self.plan_active = data.get("is_active", False)
                return self.plan_active and self.plan_remaining > 0
            elif r.status_code == 404:
                print("⚠️ No active plan found!")
                return False
            return False
        except Exception as e:
            print(f"⚠️ Plan check failed: {e}")
            return False
    
    async def send_telemetry(self, device_id: str, kwh: float):
        """إرسال استهلاك جهاز."""
        try:
            await self.client.post(
                f"/devices/{device_id}/telemetry",
                headers=self.headers,
                json={
                    "device_id": device_id,
                    "consumption_value": round(kwh, 4),
                    "timestamp": datetime.utcnow().isoformat(),
                    "device_type": "meter",
                },
                timeout=5,
            )
        except Exception:
            pass  # فشل صامت
    
    async def send_heartbeat(self, device_id: str):
        """إرسال نبض قلب."""
        try:
            await self.client.post(
                f"/devices/{device_id}/heartbeat",
                headers=self.headers,
                timeout=5,
            )
        except Exception:
            pass
    
    # ═══════════════════════════════════════════════════════
    # SIMULATION ENGINE
    # ═══════════════════════════════════════════════════════
    def generate_consumption(self, device: dict) -> float:
        """توليد استهلاك عشوائي واقعي."""
        hour = datetime.utcnow().hour
        
        # نمط يومي مبسط
        if device["id"] == "sim-ac":
            # مكيف - عالي وقت الظهر
            hour_factor = 0.3 + (0.7 * (1 - abs(hour - 14) / 12))
        elif device["id"] == "sim-heater":
            # سخان - الصبح وبليل
            hour_factor = 0.8 if hour in [6, 7, 8, 18, 19, 20] else 0.2
        elif device["id"] == "sim-light":
            # إضاءة - بليل
            hour_factor = 0.9 if 18 <= hour <= 23 else 0.1
        elif device["id"] == "sim-fridge":
            # تلاجة - شغالة طول الوقت
            hour_factor = 0.7
        else:
            # عداد - متوسط
            hour_factor = 0.5
        
        base = device["base_kwh"]
        max_val = device["max_kwh"]
        noise = random.uniform(0.8, 1.2)
        kwh = base * hour_factor * noise
        return min(kwh, max_val)
    
    async def telemetry_loop(self):
        """حلقة إرسال الاستهلاك."""
        while self._running:
            # ⭐ فحص الباقة الأول
            plan_ok = await self.check_plan()
            
            if not plan_ok:
                # ⭐ الباقة خلصت → اقفل كل الأجهزة
                print(f"\n⛔ PLAN EXHAUSTED! Forcing ALL devices OFF...")
                for d in DEVICES:
                    self.device_states[d["id"]] = False
                print(f"   All devices turned OFF\n")
                await asyncio.sleep(PLAN_CHECK_INTERVAL)
                continue
            
            # ⭐ إرسال استهلاك للأجهزة اللي شغالة
            for d in DEVICES:
                if self.device_states[d["id"]]:
                    kwh = self.generate_consumption(d)
                    self.total_consumption[d["id"]] += kwh
                    await self.send_telemetry(d["id"], kwh)
            
            await asyncio.sleep(TELEMETRY_INTERVAL)
    
    async def heartbeat_loop(self):
        """حلقة نبض القلب."""
        while self._running:
            for d in DEVICES:
                if self.device_states[d["id"]]:
                    await self.send_heartbeat(d["id"])
            await asyncio.sleep(HEARTBEAT_INTERVAL)
    
    async def status_display(self):
        """عرض حالة المحاكي كل 5 ثواني."""
        while self._running:
            on_count = sum(self.device_states.values())
            total = sum(self.total_consumption.values())
            print(f"[{datetime.now().strftime('%H:%M:%S')}] "
                  f"ON: {on_count}/{len(DEVICES)} | "
                  f"Plan: {self.plan_remaining:.0f} kWh | "
                  f"Total: {total:.2f} kWh")
            await asyncio.sleep(5)
    
    # ═══════════════════════════════════════════════════════
    # CONTROL
    # ═══════════════════════════════════════════════════════
    def turn_on(self, device_id: str) -> bool:
        """تشغيل جهاز (لو الباقة سامحة)."""
        if not self.plan_active or self.plan_remaining <= 0:
            print(f"⛔ Cannot turn ON {device_id}: Plan exhausted!")
            return False
        if device_id in self.device_states:
            self.device_states[device_id] = True
            print(f"🔌 {device_id}: ON")
            return True
        return False
    
    def turn_off(self, device_id: str) -> bool:
        """إيقاف جهاز."""
        if device_id in self.device_states:
            self.device_states[device_id] = False
            print(f"🔌 {device_id}: OFF")
            return True
        return False
    
    def force_all_off(self):
        """إيقاف كل الأجهزة (الباقة خلصت)."""
        for d in DEVICES:
            self.device_states[d["id"]] = False
        print("🛑 ALL DEVICES FORCED OFF")
    
        # ═══════════════════════════════════════════════════════
    # HISTORY GENERATOR
    # ═══════════════════════════════════════════════════════
    async def generate_history(self) -> dict:
        """
        ⭐ توليد استهلاك وهمي لآخر 7 أيام لكل الأجهزة.
        """
        if not self.token:
            return {"ok": False, "error": "Not connected to backend"}
        
        generated = 0
        now = datetime.utcnow()
        
        print("\n⏳ Generating 7-day history...")
        
        for d in DEVICES:
            device_id = d["id"]
            base = d["base_kwh"]
            max_val = d["max_kwh"]
            
            for day_offset in range(7, 0, -1):
                day = now - timedelta(days=day_offset)
                
                for hour in range(24):
                    timestamp = day.replace(hour=hour, minute=0, second=0, microsecond=0)
                    
                    if device_id == "sim-ac":
                        hour_factor = 0.3 + (0.7 * (1 - abs(hour - 14) / 12))
                    elif device_id == "sim-heater":
                        hour_factor = 0.8 if hour in [6, 7, 8, 18, 19, 20] else 0.2
                    elif device_id == "sim-light":
                        hour_factor = 0.9 if 18 <= hour <= 23 else 0.1
                    elif device_id == "sim-fridge":
                        hour_factor = 0.7
                    else:
                        hour_factor = 0.5
                    
                    noise = random.uniform(0.8, 1.2)
                    kwh = round(base * hour_factor * noise, 4)
                    kwh = min(kwh, max_val)
                    
                    try:
                        await self.client.post(
                            f"/devices/{device_id}/telemetry",
                            headers=self.headers,
                            json={
                                "device_id": device_id,
                                "consumption_value": kwh,
                                "timestamp": timestamp.isoformat(),
                                "device_type": "meter",
                            },
                            timeout=5,
                        )
                        generated += 1
                    except:
                        pass
            
            print(f"   ✅ {d['name']}: 7 days generated")
        
        print(f"   🎉 Total: {generated} readings sent!\n")
        
        return {
            "ok": True,
            "message": f"Generated {generated} historical readings for 5 devices over 7 days",
            "total_readings": generated,
        }
    # ═══════════════════════════════════════════════════════
    # LIFECYCLE
    # ═══════════════════════════════════════════════════════
    async def start(self):
        """بدء المحاكي."""
        print("\n" + "=" * 50)
        print("  🏠 SMART HOME SIMULATOR")
        print("=" * 50 + "\n")
        
        self._running = True
        self.client = httpx.AsyncClient(base_url=BASE_URL, timeout=10)
        
        if not await self.login():
            print("Cannot connect to backend. Exiting.")
            return
        
        print("\n📱 Registering devices...")
        await self.register_devices()
        
        print("\n⚡ Checking plan...")
        if await self.check_plan():
            print(f"   ✅ Plan active - {self.plan_remaining:.0f} kWh remaining\n")
        else:
            print(f"   ⚠️ No active plan! Devices will not send data.\n")
        
        # تشغيل الحلقات
        await asyncio.gather(
            self.telemetry_loop(),
            self.heartbeat_loop(),
            self.status_display(),
        )
    
    async def stop(self):
        """إيقاف المحاكي."""
        self._running = False
        if self.client:
            await self.client.aclose()
        print("\nSimulator stopped.")


# ═══════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════
async def main():
    sim = SmartHomeSimulator()
    try:
        await sim.start()
    except KeyboardInterrupt:
        await sim.stop()


if __name__ == "__main__":
    asyncio.run(main())
