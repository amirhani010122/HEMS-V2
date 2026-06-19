from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional, List

class AnomalyDetectionResult(Document):
    """Anomaly detection AI model results."""
    user_id: str = Indexed()
    device_id: str = Indexed()
    
    detection_timestamp: datetime
    
    anomaly: dict = Field(
        default_factory=lambda: {
            "type": "",  # "spike", "drop", "pattern_deviation", "malfunction"
            "severity": "low",  # "low", "medium", "high", "critical"
            "anomaly_score": 0.0,  # 0-100
            "confidence": 0.0,  # 0-1
            "details": {
                "expected_consumption": 0.0,
                "actual_consumption": 0.0,
                "deviation_percentage": 0.0,
                "root_cause_suggestion": "",
                "possible_causes": []
            }
        }
    )
    
    alert_generated: bool = False
    alert_id: Optional[str] = None
    
    status: str = "active"  # "active", "acknowledged", "resolved"
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "anomaly_detection_results"
