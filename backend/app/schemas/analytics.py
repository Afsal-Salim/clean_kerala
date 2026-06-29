from pydantic import BaseModel, Field


class GeoStatsBase(BaseModel):
    level: str
    name: str
    slug: str
    total_reports: int = 0
    pending: int = 0
    accepted: int = 0
    resolved: int = 0
    closed: int = 0


class AnalyticsSummary(BaseModel):
    level: str = "state"
    name: str = "Kerala"
    slug: str = "kerala"
    total_reports: int = 0
    pending: int = 0
    closed: int = 0


class DistrictStatsItem(GeoStatsBase):
    level: str = "district"


class LocalBodyStatsItem(GeoStatsBase):
    level: str = "local_body"


class WardStatsItem(GeoStatsBase):
    level: str = "ward"


class DistrictDetailResponse(BaseModel):
    level: str = "district"
    name: str
    slug: str
    total_reports: int = 0
    pending: int = 0
    closed: int = 0
    local_bodies: list[LocalBodyStatsItem] = Field(default_factory=list)


class LocalBodyDetailResponse(BaseModel):
    level: str = "local_body"
    name: str
    slug: str
    district_name: str | None = None
    total_reports: int = 0
    pending: int = 0
    closed: int = 0
    wards: list[WardStatsItem] = Field(default_factory=list)


class WardDetailResponse(BaseModel):
    level: str = "ward"
    name: str
    slug: str
    municipality_name: str | None = None
    district_name: str | None = None
    total_reports: int = 0
    pending: int = 0
    closed: int = 0
