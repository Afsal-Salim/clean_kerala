from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class ReportFeedItem(BaseModel):
    id: UUID
    category: str
    description: str
    address: str | None
    ward_name: str | None
    municipality_name: str | None
    district_name: str | None
    latitude: float | None = None
    longitude: float | None = None
    status: str
    upvote_count: int
    comment_count: int
    author_name: str | None
    image_urls: list[str] = Field(default_factory=list)
    location_tier: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class FeedMixInfo(BaseModel):
    mode: str
    location_based: bool
    near_pct: int
    surrounding_pct: int
    kerala_pct: int


class ReportFeedResponse(BaseModel):
    items: list[ReportFeedItem]
    total: int
    page: int
    limit: int
    mix: FeedMixInfo
    newest_first_within_tiers: bool = True


class ReportCreatedResponse(BaseModel):
    id: UUID
    status: str
    message: str = "Report posted. Nearby NGOs will be notified."
