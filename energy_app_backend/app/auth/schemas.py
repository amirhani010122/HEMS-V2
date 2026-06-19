from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional
from enum import Enum

class UserRole(str, Enum):
    ADMIN = "admin"
    OPERATOR = "operator"
    USER = "user"

# Registration
class UserRegister(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None

# Login
class UserLogin(BaseModel):
    email: EmailStr
    password: str

# Token Response
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds

# Refresh Token Request
class RefreshTokenRequest(BaseModel):
    refresh_token: str

# User Response
class UserResponse(BaseModel):
    id: str = Field(..., alias="_id")
    username: str
    email: str
    first_name: str
    last_name: str
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        populate_by_name = True

# User Update
class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    preferences: Optional[dict] = None

# Password Change
class PasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=8)

# Password Reset
class PasswordReset(BaseModel):
    email: EmailStr
    token: str
    new_password: str = Field(..., min_length=8)

# Password Reset Request
class PasswordResetRequest(BaseModel):
    email: EmailStr

# Logout
class LogoutRequest(BaseModel):
    refresh_token: Optional[str] = None
