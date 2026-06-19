from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional, List

class Recommendation(Document):
    """AI-generated energy saving recommendation."""
    user_id: str = Indexed()
    device_id: Optional[str] = None
    
    recommendation: dict = Field(
        default_factory=lambda: {
            "title": "",
            "description": "",
            "potential_savings": {
                "kwh_savings": 0.0,
                "percentage": 0.0,
                "estimated_cost_reduction": 0.0
            },
            "affected_device": "",
            "implementation_difficulty": "easy",  # "easy", "medium", "hard"
            "estimated_time_to_implement": "immediate",  # "immediate", "1 week", "1 month"
            "actions": []
        }
    )
    
    status: str = "active"  # "active", "implemented", "dismissed"
    dismissed_at: Optional[datetime] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "recommendations"

class SavingPlan(Document):
    """AI-generated energy saving plan."""
    user_id: str = Indexed()
    
    plan_type: str  # "basic", "moderate", "aggressive"
    name: str
    description: str
    
    timeline: str  # "1 month", "3 months", "6 months", "1 year"
    
    targets: dict = Field(
        default_factory=lambda: {
            "target_consumption_kwh": 0.0,
            "target_cost_usd": 0.0,
            "expected_savings_kwh": 0.0,
            "expected_savings_cost": 0.0,
            "expected_savings_percentage": 0.0
        }
    )
    
    actions: List[dict] = Field(
        default_factory=list  # List of actions with rank, title, description, etc.
    )
    
    status: str = "suggested"  # "suggested", "active", "completed", "abandoned"
    activated_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    actual_results: dict = Field(
        default_factory=lambda: {
            "actual_consumption_kwh": 0.0,
            "actual_cost_usd": 0.0,
            "actual_savings_kwh": 0.0,
            "actual_savings_cost": 0.0,
            "accuracy": 0.0
        }
    )
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "saving_plans"
