# EnergyIQ Backend - FastAPI + MongoDB

Production-grade backend for IoT Energy Monitoring and Device Management Platform.

## ✨ Features

### Core Features
- ✅ User Authentication & JWT Tokens
- ✅ Device Management (CRUD)
- ✅ Energy Consumption Tracking
- ✅ Plan Management & Subscriptions
- ✅ Alert System
- ✅ 3 AI Modules:
  - **Forecasting**: Predict future consumption
  - **Anomaly Detection**: Detect abnormal patterns
  - **Smart Advisor**: Personalized recommendations

### Architecture
- Clean Architecture
- Repository Pattern
- Dependency Injection
- MongoDB with Beanie ODM
- JWT Authentication
- Type Hints (Pydantic V2)
- Full API Documentation (Swagger/OpenAPI)

## 🛠️ Technology Stack

- **Framework**: FastAPI
- **Database**: MongoDB
- **ODM**: Beanie
- **Authentication**: JWT (python-jose)
- **Validation**: Pydantic V2
- **Server**: Uvicorn
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

- Python 3.12+
- MongoDB 4.0+
- Docker & Docker Compose (optional)

## 🚀 Quick Start

### 1. Clone & Setup

```bash
# Clone repository
git clone <repo-url>
cd energy_app_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
```

### 2. Configure Environment

Edit `.env`:
```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=energyiq_db
SECRET_KEY=your-super-secret-key-change-this
```

### 3. Run with Docker Compose (Recommended)

```bash
# Start all services
docker-compose up

# Access:
# - API: http://localhost:8000
# - Docs: http://localhost:8000/docs
# - MongoDB Express: http://localhost:8081
```

### 4. Run Locally

```bash
# Make sure MongoDB is running
mongod

# In another terminal, run:
uvicorn app.main:app --reload

# API will be at http://localhost:8000
```

## 📚 API Documentation

Interactive API docs available at: `http://localhost:8000/docs`

### API Endpoints (100% Compatible with Flutter App)

#### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login user
- `POST /api/v1/auth/logout` - Logout user
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/change-password` - Change password

#### Users
- `GET /api/v1/users/me` - Get current user info

#### Devices
- `GET /api/v1/devices` - List all devices
- `POST /api/v1/devices` - Create device
- `GET /api/v1/devices/{device_id}` - Get device details
- `DELETE /api/v1/devices/{device_id}` - Delete device

#### Consumption
- `POST /api/v1/consumption` - Record consumption (from device)
- `GET /api/v1/consumption/daily` - Daily consumption data
- `GET /api/v1/consumption/monthly` - Monthly consumption data
- `GET /api/v1/consumption/summary` - Consumption summary (for dashboard)
- `GET /api/v1/consumption/per-device-daily` - Per-device daily breakdown

#### Plans
- `GET /api/v1/plans/available` - Get available plans
- `POST /api/v1/plans/subscribe` - Subscribe to plan
- `GET /api/v1/plans/subscription` - Get current subscription

#### Alerts
- `GET /api/v1/alerts` - Get user alerts

#### AI
- `GET /api/v1/ai/analysis` - Consumption analysis
- `GET /api/v1/ai/prediction` - Consumption prediction
- `GET /api/v1/ai/plan-exhaustion` - Plan quota forecast
- `GET /api/v1/ai/recommendations` - Energy saving recommendations

## 🗂️ Project Structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI app & routes
│   ├── core/
│   │   ├── config.py           # Configuration
│   │   ├── security.py         # JWT & Password
│   │   ├── exceptions.py       # Custom exceptions
│   │   └── constants.py        # Constants
│   ├── auth/
│   │   ├── models.py           # User, RefreshToken
│   │   ├── schemas.py          # Pydantic schemas
│   │   ├── service.py          # Business logic
│   │   └── dependencies.py     # FastAPI dependencies
│   ├── devices/
│   │   ├── models.py
│   │   ├── schemas.py
│   │   └── service.py
│   ├── consumption/
│   │   ├── models.py
│   │   ├── schemas.py
│   │   └── service.py
│   ├── plans/
│   │   ├── models.py
│   │   └── schemas.py
│   ├── alerts/
│   │   ├── models.py
│   │   └── schemas.py
│   ├── ai/
│   │   ├── forecasting/        # AI Module 1
│   │   ├── anomaly_detection/  # AI Module 2
│   │   └── smart_advisor/      # AI Module 3
│   └── database/
│       └── mongodb.py
├── tests/
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── .env.example
└── README.md
```

## 🔐 Authentication

### JWT Tokens

1. **Register**: `POST /api/v1/auth/register`
2. **Login**: `POST /api/v1/auth/login` → Get `access_token` & `refresh_token`
3. **Use Token**: Add header: `Authorization: Bearer <access_token>`
4. **Refresh**: `POST /api/v1/auth/refresh` with `refresh_token`

### Token Storage (Client-side)
- Store `access_token` in memory or secure storage
- Store `refresh_token` in secure/persistent storage
- Refresh token when access token expires

## 📝 Consumption Data Format

Devices send consumption data:

```python
class ConsumptionCreate(BaseModel):
    device_id: str
    device_type: str  # "meter", "breaker", "sensor"
    consumption_value: float  # kWh
    timestamp: datetime  # Optional, defaults to now
```

Example:
```bash
POST /api/v1/consumption
{
  "device_id": "DVC-001",
  "device_type": "meter",
  "consumption_value": 2.5,
  "timestamp": "2024-06-19T14:30:00Z"
}
```

## 🧪 Testing

```bash
# Run tests
pytest

# With coverage
pytest --cov=app

# Specific test
pytest tests/test_auth.py
```

## 📊 Database Collections

All automatically created on startup:

- `users` - User accounts
- `refresh_tokens` - JWT refresh tokens
- `devices` - IoT devices
- `consumption_records` - Raw consumption data
- `daily_aggregations` - Pre-aggregated daily data
- `monthly_aggregations` - Pre-aggregated monthly data
- `plans` - Energy plans
- `subscriptions` - User subscriptions
- `alerts` - System alerts
- `forecasting_results` - AI forecasts
- `anomaly_detection_results` - Anomalies detected
- `recommendations` - AI recommendations
- `saving_plans` - Energy saving plans

## 🔧 Configuration

All settings in `.env`:

```env
# App
APP_NAME=EnergyIQ Backend
ENVIRONMENT=production

# Server
HOST=0.0.0.0
PORT=8000

# Database
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=energyiq_db

# JWT
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# AI
AI_FORECAST_MIN_DAYS=30
ANOMALY_Z_SCORE_THRESHOLD=3.0

# Features
ENABLE_AI_FEATURES=True
```

## 📈 Monitoring

- Health Check: `GET /health`
- Root: `GET /`
- Logs: Check console output or configure logging

## 🚨 Error Handling

All errors return standard JSON:

```json
{
  "detail": "Error message here"
}
```

Status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

## 🔄 Development Workflow

1. Create feature branch
2. Make changes
3. Run tests: `pytest`
4. Format code: `black app/`
5. Lint: `flake8 app/`
6. Commit & push
7. Create PR

## 📚 Additional Resources

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [MongoDB Docs](https://docs.mongodb.com/)
- [Beanie Docs](https://roman-right.github.io/beanie/)
- [Pydantic V2 Docs](https://docs.pydantic.dev/latest/)

## 📞 Support

For issues:
1. Check API docs: `http://localhost:8000/docs`
2. Review logs
3. Check `.env` configuration
4. Verify MongoDB connection

## 📄 License

Proprietary - EnergyIQ Platform

## ✅ Checklist Before Production

- [ ] Change `SECRET_KEY` in `.env`
- [ ] Set `ENVIRONMENT=production`
- [ ] Configure real MongoDB URL
- [ ] Enable HTTPS
- [ ] Set up logging
- [ ] Configure monitoring
- [ ] Set up backups
- [ ] Test all APIs
- [ ] Load testing
- [ ] Security audit

## 🎉 Ready to Deploy!

This backend is **100% compatible** with the Flutter application and fully implements all required features.

**Start Backend**: `docker-compose up`  
**API Docs**: `http://localhost:8000/docs`  
**Monitor**: `http://localhost:8081` (MongoDB)

Happy coding! 🚀
