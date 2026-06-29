from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.modules.auth import service as auth_service
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResendOtpRequest,
    ResetPasswordRequest,
    TokenResponse,
    VerifyEmailRequest,
)
from app.schemas.profile import UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])


def _user_response(user: User) -> UserResponse:
    has_loc = any(
        [
            user.home_latitude,
            user.home_longitude,
            user.home_ward,
            user.home_municipality,
            user.home_district,
        ]
    )
    return UserResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        phone=user.phone,
        role=user.role.value,
        is_email_verified=user.is_email_verified,
        home_latitude=user.home_latitude,
        home_longitude=user.home_longitude,
        home_ward=user.home_ward,
        home_municipality=user.home_municipality,
        home_district=user.home_district,
        has_home_location=bool(has_loc),
    )


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(data: RegisterRequest, db: Annotated[Session, Depends(get_db)]):
    user = await auth_service.register_user(db, data)
    return AuthResponse(
        user=_user_response(user),
        message="Account created. Please verify your email with the OTP sent to you.",
    )


@router.post("/verify-email", response_model=AuthResponse)
async def verify_email(data: VerifyEmailRequest, db: Annotated[Session, Depends(get_db)]):
    user = await auth_service.verify_email(db, data.email, data.otp)
    access, refresh = auth_service.issue_tokens(db, user)
    return AuthResponse(
        user=_user_response(user),
        tokens=TokenResponse(access_token=access, refresh_token=refresh),
        message="Email verified successfully.",
    )


@router.post("/resend-otp")
async def resend_otp(data: ResendOtpRequest, db: Annotated[Session, Depends(get_db)]):
    if data.purpose == "password_reset":
        await auth_service.forgot_password(db, data.email)
    else:
        await auth_service.resend_verification_otp(db, data.email)
    return {"message": "If the account exists, a new OTP has been sent."}


@router.post("/login", response_model=AuthResponse)
async def login(data: LoginRequest, db: Annotated[Session, Depends(get_db)]):
    user = auth_service.login_user(db, data.email, data.password)
    access, refresh = auth_service.issue_tokens(db, user)
    return AuthResponse(
        user=_user_response(user),
        tokens=TokenResponse(access_token=access, refresh_token=refresh),
    )


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest, db: Annotated[Session, Depends(get_db)]):
    await auth_service.forgot_password(db, data.email)
    return {"message": "If the account exists, a password reset OTP has been sent."}


@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest, db: Annotated[Session, Depends(get_db)]):
    await auth_service.reset_password(db, data.email, data.otp, data.new_password)
    return {"message": "Password reset successfully. You can now log in."}


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: Annotated[Session, Depends(get_db)]):
    access, refresh_token = auth_service.refresh_access_token(db, data.refresh_token)
    return TokenResponse(access_token=access, refresh_token=refresh_token)


@router.post("/logout")
async def logout(data: RefreshRequest, db: Annotated[Session, Depends(get_db)]):
    auth_service.logout_user(db, data.refresh_token)
    return {"message": "Logged out successfully."}


@router.get("/profile", response_model=UserResponse)
async def profile(user: Annotated[User, Depends(get_current_user)]):
    return _user_response(user)
