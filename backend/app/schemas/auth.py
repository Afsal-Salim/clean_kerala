from enum import Enum
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class AccountType(str, Enum):
    basic = "basic"
    ngo = "ngo"
    admin = "admin"


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    phone: str | None = Field(default=None, max_length=20)
    account_type: AccountType = AccountType.basic
    admin_code: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)


class ResendOtpRequest(BaseModel):
    email: EmailStr
    purpose: str = "email_verification"


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: UUID
    name: str
    email: EmailStr
    phone: str | None
    role: str
    is_email_verified: bool

    model_config = {"from_attributes": True}


# Extended profile with location lives in schemas/profile.py (UserResponse re-exported from auth router)


class AuthResponse(BaseModel):
    user: UserResponse
    tokens: TokenResponse | None = None
    message: str | None = None
