from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.profile import UserLocationUpdate, UserResponse

router = APIRouter(prefix="/profile", tags=["profile"])


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


@router.get("/me", response_model=UserResponse)
def get_profile(user: Annotated[User, Depends(get_current_user)]):
    return _user_response(user)


@router.put("/location", response_model=UserResponse)
def update_location(
    data: UserLocationUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Set home area for the 60/30/10 location-based feed."""
    user.home_latitude = data.latitude
    user.home_longitude = data.longitude
    user.home_ward = data.ward.strip() if data.ward else None
    user.home_municipality = data.municipality.strip() if data.municipality else None
    user.home_district = data.district.strip() if data.district else None
    db.commit()
    db.refresh(user)
    return _user_response(user)
