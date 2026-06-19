from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum

class DeviceType(str, Enum):
    METER = "meter"
    BREAKER = "breaker"
    SENSOR = "sensor"

# Device sends consumption in this format (as per Flutter app)
class ConsumptionCreate(BaseModel):
    device_id: str
    device_type: Optional[str] = "meter"  # "meter", "breaker", "sensor"
    consumption_value: float  # kWh
    timestamp: Optional[datetime] = None
    # Optional richer telemetry (devices/simulators may send these)
    voltage: Optional[float] = None
    current: Optional[float] = None
    power: Optional[float] = None

# Consumption record response
class ConsumptionResponse(BaseModel):
    id: str = Field(..., alias="_id")
    device_id: str
    consumption_value: float
    timestamp: datetime
    recorded_at: datetime
    
    class Config:
        populate_by_name = True

# Daily consumption
class DailyConsumption(BaseModel):
    id: str = Field(..., alias="_id")
    device_id: str
    date: datetime
    
    total_energy: float
    avg_power: float
    max_power: float
    min_power: float
    peak_hour: int
    peak_power: float
    
    class Config:
        populate_by_name = True

# Monthly consumption
class MonthlyConsumption(BaseModel):
    id: str = Field(..., alias="_id")
    device_id: str
    year_month: str
    
    total_energy: float
    avg_daily_energy: float
    max_daily_energy: float
    min_daily_energy: float
    avg_power: float
    max_power: float
    
    class Config:
        populate_by_name = True

# Consumption Summary for Dashboard
class ConsumptionSummary(BaseModel):
    total_consumption: float  # Total kWh
    daily_average: float  # Avg daily kWh
    monthly_average: float  # Avg monthly kWh
    trend: str  # "increasing", "stable", "decreasing"
    peak_hour: int
    peak_consumption: float
    estimated_cost: float
    estimated_monthly_cost: float

# Per Device Daily Breakdown
class DeviceDailyConsumption(BaseModel):
    device_id: str
    device_name: str
    date: datetime
    total_energy: float
    avg_power: float
    max_power: float
    peak_hour: int

# API Response Types
class ConsumptionDailyResponse(BaseModel):
    date: str  # YYYY-MM-DD
    consumption: float  # kWh
    avg_power: float
    peak_power: float

class ConsumptionMonthlyResponse(BaseModel):
    month: str  # YYYY-MM
    consumption: float  # kWh
    avg_daily: float
    peak_daily: float

class ConsumptionPerDeviceDailyResponse(BaseModel):
    device_id: str
    device_name: str
    data: List[ConsumptionDailyResponse]
