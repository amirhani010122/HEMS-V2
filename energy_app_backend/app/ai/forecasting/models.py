from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional

class ForecastingResult(Document):
    """Forecasting AI model results."""
    user_id: str = Indexed()
    device_id: str = Indexed()
    
    forecast_type: str  # "daily", "weekly", "monthly"
    forecast_date: datetime
    
    predictions: dict = Field(
        default_factory=lambda: {
            "predicted_consumption": 0.0,  # kWh
            "confidence_score": 0.0,  # 0-1
            "expected_cost": 0.0,  # USD
            "trend": "stable",  # "increasing", "stable", "decreasing"
            "variance": 0.0  # percentage
        }
    )
    
    model_info: dict = Field(
        default_factory=lambda: {
            "version": "1.0",
            "training_samples": 0,
            "mape": 0.0,  # Mean Absolute Percentage Error
            "last_trained": datetime.utcnow()
        }
    )
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "forecasting_results"
