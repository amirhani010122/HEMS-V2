from datetime import datetime, timedelta
from typing import Optional, Tuple
from beanie import PydanticObjectId
from app.auth.models import User, RefreshToken
from app.auth.schemas import UserRegister, UserLogin, UserResponse
from app.core.security import (
    hash_password, verify_password, 
    create_access_token, create_refresh_token,
    verify_token
)
from app.core.exceptions import (
    InvalidCredentialsException,
    UserNotFoundException,
    UserAlreadyExistsException,
    InvalidTokenException
)
import logging

logger = logging.getLogger(__name__)

class AuthService:
    
    @staticmethod
    async def register(user_data: UserRegister) -> User:
        """Register a new user and return the created document."""
        # Check if user exists (by email or username)
        existing_user = await User.find_one(User.email == user_data.email)
        if existing_user:
            raise UserAlreadyExistsException()
        existing_username = await User.find_one(User.username == user_data.username)
        if existing_username:
            raise UserAlreadyExistsException()

        # Create new user (first/last name optional - default sensibly)
        user = User(
            username=user_data.username,
            email=user_data.email,
            password_hash=hash_password(user_data.password),
            first_name=user_data.first_name or user_data.username,
            last_name=user_data.last_name or "",
            phone=user_data.phone,
        )

        await user.save()
        logger.info(f"User registered: {user.email}")

        return user
    
    @staticmethod
    async def login(login_data: UserLogin) -> Tuple[str, str]:
        """Login user and return tokens."""
        # Find user by email
        user = await User.find_one(User.email == login_data.email)
        if not user:
            raise InvalidCredentialsException()
        
        # Verify password
        if not verify_password(login_data.password, user.password_hash):
            raise InvalidCredentialsException()
        
        # Update last login
        user.last_login = datetime.utcnow()
        await user.save()
        
        # Create tokens
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        # Store refresh token
        token_doc = RefreshToken(
            user_id=str(user.id),
            token=refresh_token,
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        await token_doc.save()
        
        logger.info(f"User logged in: {user.email}")
        
        return access_token, refresh_token
    
    @staticmethod
    async def refresh_token(refresh_token: str) -> str:
        """Refresh access token."""
        # Verify refresh token
        payload = verify_token(refresh_token, token_type="refresh")
        user_id = payload.get("sub")
        
        # Check if token is stored and not revoked
        token_doc = await RefreshToken.find_one(
            RefreshToken.token == refresh_token,
            RefreshToken.revoked == False
        )
        
        if not token_doc:
            raise InvalidTokenException("Refresh token not found or revoked")
        
        # Create new access token
        access_token = create_access_token(data={"sub": user_id})
        
        return access_token
    
    @staticmethod
    async def logout(user_id: str, refresh_token: Optional[str] = None) -> bool:
        """Logout user by revoking refresh token."""
        try:
            if refresh_token:
                token_doc = await RefreshToken.find_one(
                    RefreshToken.token == refresh_token,
                    RefreshToken.user_id == user_id
                )
                if token_doc:
                    token_doc.revoked = True
                    await token_doc.save()
            else:
                # Revoke all refresh tokens for user
                await RefreshToken.find(
                    RefreshToken.user_id == user_id
                ).update({"$set": {"revoked": True}})
            
            logger.info(f"User logged out: {user_id}")
            return True
        except Exception as e:
            logger.error(f"Logout error: {e}")
            return False
    
    @staticmethod
    async def get_user_by_id(user_id: str) -> UserResponse:
        """Get user by ID."""
        user = await User.get(PydanticObjectId(user_id))
        if not user:
            raise UserNotFoundException()
        
        return UserResponse(**user.dict())
    
    @staticmethod
    async def get_user_by_email(email: str) -> Optional[User]:
        """Get user by email."""
        return await User.find_one(User.email == email)
    
    @staticmethod
    async def verify_user_email(user_id: str) -> bool:
        """Mark user email as verified."""
        user = await User.get(PydanticObjectId(user_id))
        if not user:
            raise UserNotFoundException()
        
        user.is_verified = True
        user.verification_token = None
        user.updated_at = datetime.utcnow()
        await user.save()
        
        return True
    
    @staticmethod
    async def change_password(user_id: str, old_password: str, new_password: str) -> bool:
        """Change user password."""
        user = await User.get(PydanticObjectId(user_id))
        if not user:
            raise UserNotFoundException()
        
        if not verify_password(old_password, user.password_hash):
            raise InvalidCredentialsException()
        
        user.password_hash = hash_password(new_password)
        user.updated_at = datetime.utcnow()
        await user.save()
        
        logger.info(f"Password changed for user: {user.email}")
        return True
