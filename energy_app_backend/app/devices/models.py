from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime
from typing import Optional
from enum import Enum

class DeviceStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    ERROR = "error"

class DeviceType(str, Enum):
    METER = "meter"
    BREAKER = "breaker"
    SENSOR = "sensor"

class Device(Document):
    """Device model."""
    user_id: str = Indexed()
    device_id: str = Indexed(unique=True)
    
    name: str
    location: Optional[str] = None
    device_type: DeviceType
    model: Optional[str] = None
    firmware_version: Optional[str] = None
    
    is_active: bool = True
    status: DeviceStatus = DeviceStatus.OFFLINE
    last_data_at: Optional[datetime] = Field(default=None)
    last_heartbeat: Optional[datetime] = None
    
    specifications: dict = Field(
        default_factory=lambda: {
            "voltage_rating": 220,
            "current_rating": 16,
            "frequency": 50,
            "power_rating": 3.5
        }
    )
    
    installation: dict = Field(
        default_factory=lambda: {
            "installed_at": datetime.utcnow(),
            "installed_by": "",
            "location_coordinates": {
                "latitude": 0.0,
                "longitude": 0.0
            }
        }
    )
    
    metadata: dict = Field(
        default_factory=lambda: {
            "serial_number": "",
            "manufacturer": "",
            "warranty_until": None,
            "maintenance_due": None
        }
    )
    
    statistics: dict = Field(
        default_factory=lambda: {
            "total_energy": 0.0,
            "peak_power": 0.0,
            "average_power": 0.0,
            "uptime_percentage": 100.0,
            "command_count": 0
        }
    )
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "devices"


class CommandStatus(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    EXECUTED = "executed"
    FAILED = "failed"


class DeviceCommand(Document):
    """Command queued for a device to poll and execute."""
    device_id: str = Indexed()
    user_id: str = Indexed()

    command: str  # e.g. "turn_on", "turn_off", "reset", "set_threshold"
    parameters: dict = Field(default_factory=dict)

    status: CommandStatus = CommandStatus.PENDING
    result: Optional[str] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    executed_at: Optional[datetime] = None

    class Settings:
        name = "device_commands"
