from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.modules.analytics import service as analytics_service
from app.schemas.analytics import (
    AnalyticsSummary,
    DistrictDetailResponse,
    DistrictStatsItem,
    LocalBodyDetailResponse,
    WardDetailResponse,
)

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/summary", response_model=AnalyticsSummary)
def kerala_summary(db: Annotated[Session, Depends(get_db)]):
    """Kerala-wide report statistics."""
    return analytics_service.kerala_summary(db)


@router.get("/districts", response_model=list[DistrictStatsItem])
def list_districts(db: Annotated[Session, Depends(get_db)]):
    """All districts with report counts (for map choropleth or list view)."""
    return analytics_service.district_stats(db)


@router.get("/districts/{district_slug}", response_model=DistrictDetailResponse)
def get_district(district_slug: str, db: Annotated[Session, Depends(get_db)]):
    """District detail + local bodies (municipalities / panchayats)."""
    data = analytics_service.district_detail(db, district_slug)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="DISTRICT_NOT_FOUND")
    return data


@router.get("/local-bodies/{body_slug}", response_model=LocalBodyDetailResponse)
def get_local_body(body_slug: str, db: Annotated[Session, Depends(get_db)]):
    """Local body detail + wards."""
    data = analytics_service.local_body_detail(db, body_slug)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="LOCAL_BODY_NOT_FOUND")
    return data


@router.get("/wards/{ward_slug}", response_model=WardDetailResponse)
def get_ward(ward_slug: str, db: Annotated[Session, Depends(get_db)]):
    """Ward-level statistics."""
    data = analytics_service.ward_detail(db, ward_slug)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="WARD_NOT_FOUND")
    return data
