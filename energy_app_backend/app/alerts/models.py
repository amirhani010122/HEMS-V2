from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional
from enum import Enum

class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"

class AlertStatus(str, Enum):
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"

class AlertType(str, Enum):
    DEVICE_OFFLINE = "device_offline"
    HIGH_CONSUMPTION = "high_consumption"
    VOLTAGE_ABNORMAL = "voltage_abnormal"
    DEVICE_FAILURE = "device_failure"
    COMMUNICATION_ERROR = "communication_error"
    ANOMALY_DETECTED = "anomaly_detected"

class Alert(Document):
    """Alert model."""
    user_id: str = Indexed()
    device_id: Optional[str] = Indexed()
    
    alert_type: AlertType
    severity: AlertSeverity = AlertSeverity.INFO
    
    title: str
    description: str
    
    condition: dict = Field(
        default_factory=lambda: {
            "metric": "",
            "threshold": 0.0,
            "actual_value": 0.0,
            "unit": ""
        }
    )
    
    status: AlertStatus = AlertStatus.ACTIVE
    acknowledged_at: Optional[datetime] = None
    acknowledged_by: Optional[str] = None
    
    resolution: dict = Field(
        default_factory=lambda: {
            "resolved_at": None,
            "resolved_by": "",
            "resolution_notes": "",
            "action_taken": ""
        }
    )
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "alerts"
