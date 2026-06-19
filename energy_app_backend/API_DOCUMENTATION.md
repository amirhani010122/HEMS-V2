# 🔌 EnergyIQ Backend API Documentation

## Complete API Reference - 100% Flutter Compatible

### Base URL
```
http://localhost:8000/api/v1
```

### Authentication
All protected endpoints require JWT token in header:
```
Authorization: Bearer <access_token>
```

---

## 🔐 Authentication Endpoints

### 1. Register User
```
POST /auth/register
```

**Request:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

**Response (201):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "role": "user",
  "is_active": true,
  "is_verified": false,
  "created_at": "2024-06-19T10:30:00Z"
}
```

---

### 2. Login
```
POST /auth/login
```

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

---

### 3. Logout
```
POST /auth/logout
```

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

### 4. Refresh Token
```
POST /auth/refresh?refresh_token=<token>
```

**Response (200):**
```json
{
  "access_token": "new_access_token",
  "refresh_token": "refresh_token",
  "token_type": "bearer",
  "expires_in": 1800
}
```

---

### 5. Change Password
```
POST /auth/change-password
```

**Request:**
```json
{
  "old_password": "OldPass123",
  "new_password": "NewPass456"
}
```

**Response (200):**
```json
{
  "message": "Password changed successfully"
}
```

---

## 👤 User Endpoints

### 1. Get Current User
```
GET /users/me
```

**Response (200):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "avatar_url": "https://example.com/avatar.jpg",
  "role": "user",
  "is_active": true,
  "is_verified": true,
  "created_at": "2024-06-19T10:30:00Z",
  "last_login": "2024-06-20T15:45:00Z"
}
```

---

## 🔌 Device Endpoints

### 1. Get All Devices
```
GET /devices
```

**Response (200):**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "device_id": "DVC-001",
    "name": "Living Room Meter",
    "location": "Living Room",
    "device_type": "meter",
    "model": "Model-X",
    "firmware_version": "1.2.3",
    "is_active": true,
    "status": "online",
    "last_heartbeat": "2024-06-20T15:45:00Z",
    "specifications": {
      "voltage_rating": 220,
      "current_rating": 16,
      "frequency": 50,
      "power_rating": 3.5
    },
    "statistics": {
      "total_energy": 150.5,
      "peak_power": 3.2,
      "average_power": 1.5,
      "uptime_percentage": 99.8,
      "command_count": 5
    },
    "created_at": "2024-06-15T10:00:00Z",
    "updated_at": "2024-06-20T15:45:00Z"
  }
]
```

---

### 2. Create Device
```
POST /devices
```

**Request:**
```json
{
  "device_id": "DVC-002",
  "name": "Kitchen Meter",
  "location": "Kitchen",
  "device_type": "meter",
  "model": "Model-Y",
  "firmware_version": "1.2.3"
}
```

**Response (201):**
```json
{
  "id": "507f1f77bcf86cd799439012",
  "device_id": "DVC-002",
  "name": "Kitchen Meter",
  ...
}
```

---

### 3. Get Device Details
```
GET /devices/{device_id}
```

**Response (200):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "device_id": "DVC-001",
  "name": "Living Room Meter",
  ...
}
```

---

### 4. Delete Device
```
DELETE /devices/{device_id}
```

**Response (200):**
```json
{
  "message": "Device deleted successfully"
}
```

---

## 📊 Consumption Endpoints

### 1. Record Consumption (From Device)
```
POST /consumption
```

**Request:**
```json
{
  "device_id": "DVC-001",
  "device_type": "meter",
  "consumption_value": 2.5,
  "timestamp": "2024-06-20T15:45:00Z"
}
```

**Response (200):**
```json
{
  "message": "Consumption recorded",
  "id": "507f1f77bcf86cd799439015"
}
```

---

### 2. Get Daily Consumption
```
GET /consumption/daily?days=7
```

**Response (200):**
```json
[
  {
    "date": "2024-06-20",
    "consumption": 18.5,
    "avg_power": 0.77,
    "peak_power": 3.2
  },
  {
    "date": "2024-06-19",
    "consumption": 19.2,
    "avg_power": 0.80,
    "peak_power": 3.0
  }
]
```

---

### 3. Get Monthly Consumption
```
GET /consumption/monthly?months=12
```

**Response (200):**
```json
[
  {
    "month": "2024-06",
    "consumption": 550.0,
    "avg_daily": 18.33,
    "peak_daily": 21.5
  },
  {
    "month": "2024-05",
    "consumption": 520.0,
    "avg_daily": 16.77,
    "peak_daily": 20.0
  }
]
```

---

### 4. Get Consumption Summary (Dashboard)
```
GET /consumption/summary
```

**Response (200):**
```json
{
  "total_consumption": 550.0,
  "daily_average": 18.33,
  "monthly_average": 550.0,
  "trend": "stable",
  "peak_hour": 12,
  "peak_consumption": 21.5,
  "estimated_cost": 82.50,
  "estimated_monthly_cost": 82.50
}
```

---

### 5. Get Per-Device Daily Consumption
```
GET /consumption/per-device-daily?device_id=DVC-001&days=7
```

**Response (200):**
```json
{
  "devices": [
    {
      "device_id": "DVC-001",
      "device_name": "Living Room Meter",
      "data": [
        {
          "date": "2024-06-20",
          "consumption": 18.5,
          "avg_power": 0.77,
          "peak_power": 3.2
        }
      ]
    }
  ]
}
```

---

## ⚡ Plan Endpoints

### 1. Get Available Plans
```
GET /plans/available
```

**Response (200):**
```json
[
  {
    "id": "507f1f77bcf86cd799439020",
    "name": "Basic Plan",
    "description": "Perfect for getting started",
    "tier": "basic",
    "pricing": {
      "monthly_cost": 9.99,
      "currency": "USD",
      "billing_cycle": 30,
      "annual_discount": 10.0
    },
    "limits": {
      "max_devices": 5,
      "max_daily_consumption_kwh": 100.0,
      "max_users": 1,
      "data_retention_days": 90,
      "api_requests_per_day": 1000
    },
    "features": {
      "real_time_monitoring": true,
      "analytics": true,
      "ai_insights": false,
      "device_commands": false,
      "alerts": true,
      "multiple_locations": false,
      "api_access": false,
      "priority_support": false
    }
  }
]
```

---

### 2. Subscribe to Plan
```
POST /plans/subscribe?plan_id=507f1f77bcf86cd799439020
```

**Response (200):**
```json
{
  "message": "Subscribed to plan successfully"
}
```

---

### 3. Get Current Subscription
```
GET /plans/subscription
```

**Response (200):**
```json
{
  "plan": {
    "id": "507f1f77bcf86cd799439020",
    "name": "Pro Plan",
    "tier": "pro",
    ...
  },
  "subscription": {
    "id": "507f1f77bcf86cd799439025",
    "user_id": "507f1f77bcf86cd799439011",
    "plan_id": "507f1f77bcf86cd799439020",
    "billing": {
      "status": "active",
      "started_at": "2024-06-19T10:30:00Z",
      "current_period_start": "2024-06-19T10:30:00Z",
      "current_period_end": "2024-07-19T10:30:00Z",
      "renewal_date": "2024-07-19T10:30:00Z"
    },
    "usage": {
      "devices_used": 3,
      "daily_consumption_kwh": 18.5,
      "api_calls_today": 450,
      "api_calls_remaining": 550
    }
  }
}
```

---

## 🚨 Alert Endpoints

### 1. Get Alerts
```
GET /alerts?limit=10
```

**Response (200):**
```json
[
  {
    "id": "507f1f77bcf86cd799439030",
    "device_id": "DVC-001",
    "alert_type": "high_consumption",
    "severity": "warning",
    "title": "High Consumption Alert",
    "description": "Device consumption exceeded threshold",
    "condition": {
      "metric": "consumption",
      "threshold": 20.0,
      "actual_value": 21.5,
      "unit": "kWh"
    },
    "status": "active",
    "created_at": "2024-06-20T15:45:00Z"
  }
]
```

---

## 🤖 AI Endpoints

### 1. Get AI Analysis
```
GET /ai/analysis
```

**Response (200):**
```json
{
  "analysis": {
    "total_consumption": 550.0,
    "daily_average": 18.33,
    "trend": "stable",
    "insights": [
      "Your consumption is relatively stable",
      "Peak usage occurs during evening hours"
    ]
  }
}
```

---

### 2. Get AI Prediction
```
GET /ai/prediction
```

**Response (200):**
```json
{
  "prediction": {
    "predicted_daily_consumption": 18.33,
    "predicted_monthly_consumption": 550.0,
    "confidence_score": 0.85,
    "trend": "stable"
  }
}
```

---

### 3. Get Plan Exhaustion Forecast
```
GET /ai/plan-exhaustion
```

**Response (200):**
```json
{
  "quota_info": {
    "daily_quota": 100.0,
    "current_consumption": 18.5,
    "usage_percentage": 18.5,
    "days_until_exceeded": null,
    "will_exceed": false
  }
}
```

---

### 4. Get AI Recommendations
```
GET /ai/recommendations
```

**Response (200):**
```json
{
  "recommendations": [
    {
      "title": "Reduce peak hour usage",
      "description": "Shift high-consumption activities to off-peak hours",
      "potential_savings": {
        "kwh_savings": 15.0,
        "percentage": 8.5,
        "estimated_cost_reduction": 2.25
      }
    }
  ]
}
```

---

## ✅ Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Missing/invalid token |
| 403 | Forbidden - No permission |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable - Validation error |
| 500 | Server Error |

---

## 🔒 Security Notes

1. **Store tokens securely** - Use secure storage on client
2. **HTTPS only** - Always use HTTPS in production
3. **Token expiration** - Access tokens expire after 30 minutes
4. **Refresh tokens** - Use to get new access tokens
5. **Never expose secrets** - Keep `SECRET_KEY` safe

---

## 🧪 Example: Full User Flow

```
1. Register:      POST /auth/register
2. Login:         POST /auth/login → Get tokens
3. Get User:      GET /users/me (with token)
4. Get Devices:   GET /devices (with token)
5. Add Device:    POST /devices (with token)
6. Record Data:   POST /consumption (from device)
7. View Summary:  GET /consumption/summary (with token)
8. Get Plans:     GET /plans/available (with token)
9. Subscribe:     POST /plans/subscribe (with token)
10. Check Alerts: GET /alerts (with token)
11. AI Insights:  GET /ai/analysis (with token)
12. Logout:       POST /auth/logout (with token)
```

---

## 📞 Need Help?

- Check API docs: `GET /docs`
- View schema: `GET /redoc`
- Check logs for errors
- Verify token validity
- Ensure MongoDB is running

---

**Backend is 100% compatible with the Flutter application!** ✅
