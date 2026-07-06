"""
Smart Home Dashboard - تحكم في أجهزة البيت
"""
import asyncio
import json
from datetime import datetime
from typing import Dict

from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
import uvicorn
import httpx

# ═══════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════
BASE_URL = "https://hems-v2-production.up.railway.app/api/v1"
EMAIL = "amir@test.com"
PASSWORD = "1234567"

# ═══════════════════════════════════════════════════════════
# SIMULATOR
# ═══════════════════════════════════════════════════════════
DEVICES = [
    {"id": "sim-meter",  "name": "Smart Meter",      "location": "Main Panel",   "base_kwh": 0.8,  "max_kwh": 3.0},
    {"id": "sim-ac",     "name": "Air Conditioner",   "location": "Living Room",  "base_kwh": 2.0,  "max_kwh": 4.0},
    {"id": "sim-fridge", "name": "Refrigerator",      "location": "Kitchen",      "base_kwh": 0.15, "max_kwh": 0.3},
    {"id": "sim-heater", "name": "Water Heater",      "location": "Bathroom",     "base_kwh": 2.5,  "max_kwh": 5.0},
    {"id": "sim-light",  "name": "Lighting",          "location": "Whole House",  "base_kwh": 0.1,  "max_kwh": 0.5},
]

from simulator import SmartHomeSimulator

sim = SmartHomeSimulator()
sim_task: asyncio.Task = None


# ═══════════════════════════════════════════════════════════
# FASTAPI APP
# ═══════════════════════════════════════════════════════════
app = FastAPI(title="Smart Home Dashboard")


@app.on_event("startup")
async def startup():
    global sim_task
    sim_task = asyncio.create_task(sim.start())


@app.on_event("shutdown")
async def shutdown():
    global sim_task
    await sim.stop()
    if sim_task:
        sim_task.cancel()


# ═══════════════════════════════════════════════════════════
# API
# ═══════════════════════════════════════════════════════════
@app.get("/api/status")
async def status():
    devices_status = []
    for d in DEVICES:
        devices_status.append({
            "device_id": d["id"],
            "name": d["name"],
            "location": d["location"],
            "is_on": sim.device_states.get(d["id"], False),
            "total_consumption": round(sim.total_consumption.get(d["id"], 0), 2),
        })
    
    return {
        "plan_remaining": round(sim.plan_remaining, 1),
        "plan_active": sim.plan_active,
        "devices": devices_status,
        "total_consumption": round(sum(sim.total_consumption.values()), 2),
        "backend_connected": sim.token is not None,
        "timestamp": datetime.now().isoformat(),
    }


@app.post("/api/toggle/{device_id}")
async def toggle_device(device_id: str):
    if device_id not in sim.device_states:
        return JSONResponse({"error": "Device not found"}, 404)
    
    if sim.device_states[device_id]:
        sim.turn_off(device_id)
        return {"device_id": device_id, "state": "OFF"}
    else:
        ok = sim.turn_on(device_id)
        if ok:
            return {"device_id": device_id, "state": "ON"}
        else:
            return JSONResponse(
                {"error": "Plan exhausted! Cannot turn ON.", "device_id": device_id}, 403
            )


@app.post("/api/all/off")
async def all_off():
    sim.force_all_off()
    return {"message": "All devices turned OFF"}


@app.post("/api/register")
async def register():
    """محاولة تسجيل مستخدم جديد."""
    try:
        async with httpx.AsyncClient(base_url=BASE_URL, timeout=10) as client:
            r = await client.post("/auth/register", json={
                "email": EMAIL,
                "username": "amirhani",
                "password": PASSWORD,
            })
            if r.status_code in (200, 201):
                # نجرب login بعد التسجيل
                r2 = await client.post("/auth/login", json={
                    "email": EMAIL, "password": PASSWORD
                })
                if r2.status_code == 200:
                    sim.token = r2.json()["access_token"]
                    # نسجل الأجهزة
                    await sim.register_devices()
                    return {"ok": True, "message": "Registered & logged in!"}
                return {"ok": False, "error": "Register OK but login failed"}
            else:
                detail = r.json() if r.text else "Unknown error"
                return {"ok": False, "error": str(detail)}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/api/generate-history")
async def generate_history():
    """توليد استهلاك وهمي لآخر 7 أيام."""
    if not sim.token:
        return JSONResponse({"ok": False, "error": "Not connected to backend. Click Register first."}, 400)
    
    result = await sim.generate_history()
    return JSONResponse(result)
# ═══════════════════════════════════════════════════════════
# HTML
# ═══════════════════════════════════════════════════════════
HTML = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏠 Smart Home</title>
    <style>
        :root {
            --bg: #0a0a0a;
            --card: #1a1a1a;
            --border: #2a2a2a;
            --text: #e0e0e0;
            --muted: #888;
            --green: #00ff88;
            --red: #ff4444;
            --yellow: #ffaa00;
            --blue: #4488ff;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg);
            color: var(--text);
            font-family: 'Segoe UI', system-ui, sans-serif;
            padding: 20px;
            min-height: 100vh;
        }
        .container { max-width: 600px; margin: 0 auto; }
        
        /* Header */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
        }
        h1 { 
            font-size: 24px; 
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 4px;
        }
        .subtitle { color: var(--muted); font-size: 14px; }
        
        /* Register Button */
        .register-btn {
            padding: 8px 16px;
            background: var(--blue);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        .register-btn:hover { opacity: 0.85; }
        .register-btn:disabled { opacity: 0.4; cursor: not-allowed; }
        
        /* Notification */
        .toast {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            padding: 12px 24px;
            border-radius: 10px;
            color: white;
            font-weight: 600;
            z-index: 100;
            animation: slideDown 0.3s ease;
            display: none;
        }
        .toast.show { display: block; }
        .toast.success { background: var(--green); color: #000; }
        .toast.error { background: var(--red); }
        
        @keyframes slideDown {
            from { opacity: 0; transform: translateX(-50%) translateY(-20px); }
            to { opacity: 1; transform: translateX(-50%) translateY(0); }
        }
        
        /* Plan Card */
        .plan-card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .plan-title { font-size: 12px; text-transform: uppercase; color: var(--muted); letter-spacing: 1px; }
        .plan-value { font-size: 36px; font-weight: 700; margin: 4px 0; }
        .plan-bar {
            height: 6px;
            background: var(--border);
            border-radius: 3px;
            margin-top: 12px;
            overflow: hidden;
        }
        .plan-bar-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.5s, background 0.5s;
        }
        .plan-details { display: flex; justify-content: space-between; margin-top: 8px; font-size: 12px; color: var(--muted); }
        
        /* Device Cards */
        .device-grid { display: flex; flex-direction: column; gap: 10px; }
        .device-card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            transition: all 0.2s;
        }
        .device-card:hover { border-color: #444; }
        .device-card.on { border-color: var(--green); box-shadow: 0 0 20px rgba(0,255,136,0.05); }
        .device-info h3 { font-size: 16px; margin-bottom: 2px; }
        .device-info span { font-size: 12px; color: var(--muted); }
        .device-consumption { font-size: 13px; color: var(--muted); margin-top: 4px; }
        
        /* Toggle Switch */
        .toggle {
            width: 52px;
            height: 28px;
            background: var(--border);
            border-radius: 14px;
            position: relative;
            transition: background 0.3s;
            flex-shrink: 0;
        }
        .toggle.on { background: var(--green); }
        .toggle::after {
            content: '';
            position: absolute;
            width: 22px;
            height: 22px;
            background: white;
            border-radius: 50%;
            top: 3px;
            left: 3px;
            transition: left 0.3s;
        }
        .toggle.on::after { left: 27px; }
        
        /* Buttons */
        .all-off-btn {
            width: 100%;
            padding: 14px;
            background: var(--red);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 20px;
            transition: opacity 0.2s;
        }
        .all-off-btn:hover { opacity: 0.85; }
        .history-btn {
    width: 100%;
    padding: 14px;
    background: var(--yellow);
    color: #000;
    border: none;
    border-radius: 12px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 12px;
    transition: opacity 0.2s;
}
.history-btn:hover { opacity: 0.85; }
.history-btn:disabled { opacity: 0.4; cursor: not-allowed; }
        /* Status Dot */
        .dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
        }
        .dot.active { background: var(--green); box-shadow: 0 0 10px var(--green); }
        .dot.exhausted { background: var(--red); box-shadow: 0 0 10px var(--red); }
        
        @media (max-width: 480px) {
            body { padding: 12px; }
            .plan-value { font-size: 28px; }
        }
    </style>
</head>
<body>
    <!-- Toast Notification -->
    <div id="toast" class="toast"></div>
    
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>
                    🏠 Smart Home
                    <span id="statusDot" class="dot exhausted"></span>
                </h1>
                <p class="subtitle" id="clock">--</p>
            </div>
            <button class="register-btn" id="registerBtn" onclick="doRegister()">
                📝 Register
            </button>
        </div>
        
        <!-- Plan Card -->
        <div class="plan-card">
            <div class="plan-title">⚡ Plan Remaining</div>
            <div class="plan-value" id="planValue">-- kWh</div>
            <div class="plan-bar">
                <div class="plan-bar-fill" id="planBar" style="width: 100%"></div>
            </div>
            <div class="plan-details">
                <span id="planUsed">Used: --</span>
                <span id="planTotal">Total: --</span>
            </div>
        </div>
        
        <!-- Device Grid -->
        <div class="device-grid" id="deviceGrid"></div>
        
        <!-- All Off -->
        <button class="history-btn" id="historyBtn" onclick="generateHistory()">
    ⏳ Generate 7-Day History </button>
        <button class="all-off-btn" onclick="allOff()">🔴 Emergency: All OFF</button>
    </div>

    <script>
        const REFRESH = 2000;
        
        function showToast(msg, type) {
            const t = document.getElementById('toast');
            t.textContent = msg;
            t.className = 'toast show ' + type;
            setTimeout(() => t.classList.remove('show'), 3000);
        }
        
        async function tick() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                render(data);
            } catch(e) {
                console.error('Failed to fetch');
            }
        }
        
        function render(data) {
            document.getElementById('clock').textContent = new Date(data.timestamp).toLocaleTimeString();
            
            const plan = data.plan_remaining;
            const total = data.plan_remaining + data.total_consumption;
            const pct = total > 0 ? (plan / total * 100) : 0;
            
            document.getElementById('planValue').textContent = plan.toFixed(0) + ' kWh';
            document.getElementById('planUsed').textContent = 'Used: ' + data.total_consumption.toFixed(1) + ' kWh';
            document.getElementById('planTotal').textContent = 'Quota: ' + total.toFixed(0) + ' kWh';
            
            const bar = document.getElementById('planBar');
            bar.style.width = pct + '%';
            if (pct < 20) bar.style.background = 'var(--red)';
            else if (pct < 50) bar.style.background = 'var(--yellow)';
            else bar.style.background = 'var(--green)';
            
            const dot = document.getElementById('statusDot');
            if (data.plan_active && data.plan_remaining > 0) {
                dot.className = 'dot active';
            } else {
                dot.className = 'dot exhausted';
            }
            
            // Backend status
            const btn = document.getElementById('registerBtn');
            if (data.backend_connected) {
                btn.textContent = '✅ Connected';
                btn.style.background = 'var(--green)';
                btn.style.color = '#000';
                btn.disabled = true;
            } else {
                btn.textContent = '📝 Register';
                btn.style.background = 'var(--blue)';
                btn.style.color = 'white';
                btn.disabled = false;
            }
            
            const grid = document.getElementById('deviceGrid');
            grid.innerHTML = data.devices.map(d => `
                <div class="device-card ${d.is_on ? 'on' : ''}" onclick="toggleDevice('${d.device_id}')">
                    <div class="device-info">
                        <h3>${getIcon(d.device_id)} ${d.name}</h3>
                        <span>📍 ${d.location}</span>
                        <div class="device-consumption">⚡ ${d.total_consumption.toFixed(2)} kWh</div>
                    </div>
                    <div class="toggle ${d.is_on ? 'on' : ''}"></div>
                </div>
            `).join('');
        }
        
        function getIcon(id) {
            const icons = {
                'sim-meter': '🔢', 'sim-ac': '❄️', 'sim-fridge': '🧊',
                'sim-heater': '🔥', 'sim-light': '💡'
            };
            return icons[id] || '📱';
        }
        
        async function toggleDevice(id) {
            try {
                const res = await fetch('/api/toggle/' + id, { method: 'POST' });
                const data = await res.json();
                if (data.error) {
                    showToast('⛔ ' + data.error, 'error');
                }
                tick();
            } catch(e) {
                showToast('Toggle failed', 'error');
            }
        }
        async function generateHistory() {
    const btn = document.getElementById('historyBtn');
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = '⏳ Generating... Please wait...';
    
    try {
        const res = await fetch('/api/generate-history', { method: 'POST' });
        const data = await res.json();
        if (data.ok) {
            showToast('✅ ' + data.message, 'success');
        } else {
            showToast('❌ ' + (data.error || 'Failed'), 'error');
        }
    } catch(e) {
        showToast('❌ Connection error', 'error');
    }
    
    btn.disabled = false;
    btn.textContent = originalText;
    setTimeout(tick, 1000);
}
        async function allOff() {
            if (confirm('⚠️ Turn off ALL devices?')) {
                await fetch('/api/all/off', { method: 'POST' });
                tick();
            }
        }
        
        async function doRegister() {
            const btn = document.getElementById('registerBtn');
            btn.disabled = true;
            btn.textContent = '⏳ Registering...';
            
            try {
                const res = await fetch('/api/register', { method: 'POST' });
                const data = await res.json();
                if (data.ok) {
                    showToast('✅ ' + data.message, 'success');
                } else {
                    showToast('❌ ' + (data.error || 'Failed'), 'error');
                }
            } catch(e) {
                showToast('❌ Connection error', 'error');
            }
            
            setTimeout(tick, 2000);
        }
        
        tick();
        setInterval(tick, REFRESH);
    </script>
</body>
</html>"""


@app.get("/", response_class=HTMLResponse)
async def dashboard():
    return HTML


if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("  🏠 SMART HOME DASHBOARD")
    print("  http://localhost:8050")
    print("  Network: http://YOUR_IP:8050")
    print("=" * 50 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8050, log_level="warning")
