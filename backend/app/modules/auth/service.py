import hashlib
import logging
from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_otp,
    hash_password,
    verify_password,
)
from app.models.email_otp import EmailOtp, OtpPurpose
from app.models.refresh_token import RefreshToken
from app.models.user import User, UserRole
from app.schemas.auth import AccountType, RegisterRequest
from app.services.email import send_otp_email

logger = logging.getLogger(__name__)

ADMIN_REGISTRATION_CODE = "MKC-ADMIN-2026"


def account_type_to_role(account_type: AccountType) -> UserRole:
    mapping = {
        AccountType.basic: UserRole.citizen,
        AccountType.ngo: UserRole.ngo_admin,
        AccountType.admin: UserRole.system_admin,
    }
    return mapping[account_type]


def _hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def create_and_send_otp(db: Session, user: User, purpose: OtpPurpose) -> str:
    otp_code = generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expire_minutes)

    db.add(
        EmailOtp(
            user_id=user.id,
            email=user.email,
            otp_code=otp_code,
            purpose=purpose,
            expires_at=expires_at,
        )
    )
    db.commit()

    await send_otp_email(
        to_email=user.email,
        name=user.name,
        otp_code=otp_code,
        purpose=purpose.value,
    )
    return otp_code


def verify_otp(db: Session, email: str, otp: str, purpose: OtpPurpose) -> EmailOtp:
    record = db.scalar(
        select(EmailOtp)
        .where(
            EmailOtp.email == email,
            EmailOtp.otp_code == otp,
            EmailOtp.purpose == purpose,
            EmailOtp.used_at.is_(None),
            EmailOtp.expires_at > datetime.now(timezone.utc),
        )
        .order_by(EmailOtp.created_at.desc())
    )
    if not record:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP")
    record.used_at = datetime.now(timezone.utc)
    return record


def issue_tokens(db: Session, user: User) -> tuple[str, str]:
    access = create_access_token(str(user.id))
    refresh = create_refresh_token(str(user.id))
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=_hash_refresh_token(refresh),
            expires_at=datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days),
        )
    )
    db.commit()
    return access, refresh


async def register_user(db: Session, data: RegisterRequest) -> User:
    existing = db.scalar(select(User).where(User.email == data.email))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    if data.account_type == AccountType.admin:
        if data.admin_code != ADMIN_REGISTRATION_CODE:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid admin registration code")

    user = User(
        name=data.name,
        email=data.email.lower(),
        phone=data.phone,
        password_hash=hash_password(data.password),
        role=account_type_to_role(data.account_type),
        is_email_verified=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    await create_and_send_otp(db, user, OtpPurpose.email_verification)
    return user


async def verify_email(db: Session, email: str, otp: str) -> User:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.is_email_verified:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already verified")

    verify_otp(db, email.lower(), otp, OtpPurpose.email_verification)
    user.is_email_verified = True
    db.commit()
    db.refresh(user)
    return user


def login_user(db: Session, email: str, password: str) -> User:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")
    if not user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email not verified. Please verify your email with the OTP sent to you.",
        )
    return user


async def resend_verification_otp(db: Session, email: str) -> None:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.is_email_verified:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already verified")
    await create_and_send_otp(db, user, OtpPurpose.email_verification)


async def forgot_password(db: Session, email: str) -> None:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user:
        # Avoid email enumeration
        logger.info("Password reset requested for unknown email: %s", email)
        return
    await create_and_send_otp(db, user, OtpPurpose.password_reset)


async def reset_password(db: Session, email: str, otp: str, new_password: str) -> None:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    verify_otp(db, email.lower(), otp, OtpPurpose.password_reset)
    user.password_hash = hash_password(new_password)
    db.commit()


def refresh_access_token(db: Session, refresh_token: str) -> tuple[str, str]:
    from app.core.security import decode_token

    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    token_hash = _hash_refresh_token(refresh_token)
    stored = db.scalar(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > datetime.now(timezone.utc),
        )
    )
    if not stored:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user = db.get(User, stored.user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    stored.revoked_at = datetime.now(timezone.utc)
    return issue_tokens(db, user)


def logout_user(db: Session, refresh_token: str) -> None:
    token_hash = _hash_refresh_token(refresh_token)
    stored = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    if stored and stored.revoked_at is None:
        stored.revoked_at = datetime.now(timezone.utc)
        db.commit()
