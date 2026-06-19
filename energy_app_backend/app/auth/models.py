from beanie import Document, Indexed
from pydantic import Field, EmailStr
from datetime import datetime
from typing import Optional
from enum import Enum

class UserRole(str, Enum):
    ADMIN = "admin"
    OPERATOR = "operator"
    USER = "user"

class User(Document):
    """User model."""
    username: str = Indexed(unique=True)
    email: EmailStr = Indexed(unique=True)
    password_hash: str
    
    first_name: str
    last_name: str
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    
    role: UserRole = UserRole.USER
    
    is_active: bool = True
    is_verified: bool = False
    verification_token: Optional[str] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: Optional[datetime] = None
    
    preferences: dict = Field(
        default_factory=lambda: {
            "theme": "dark",
            "notifications_enabled": True,
            "email_alerts": True,
            "push_alerts": True
        }
    )
    
    class Settings:
        name = "users"

class RefreshToken(Document):
    """Refresh token model."""
    user_id: str
    token: str = Indexed(unique=True)
    expires_at: datetime
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    revoked: bool = False
    
    class Settings:
        name = "refresh_tokens"
