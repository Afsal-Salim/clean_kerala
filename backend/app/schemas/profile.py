from uuid import UUID

from pydantic import BaseModel, Field


class UserLocationUpdate(BaseModel):
    latitude: float | None = None
    longitude: float | None = None
    ward: str | None = Field(default=None, max_length=120)
    municipality: str | None = Field(default=None, max_length=120)
    district: str | None = Field(default=None, max_length=120)


class UserResponse(BaseModel):
    id: UUID
    name: str
    email: str
    phone: str | None
    role: str
    is_email_verified: bool
    home_latitude: float | None = None
    home_longitude: float | None = None
    home_ward: str | None = None
    home_municipality: str | None = None
    home_district: str | None = None
    has_home_location: bool = False

    model_config = {"from_attributes": True}
