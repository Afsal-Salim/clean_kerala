from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_current_user_optional
from app.db.session import get_db
from app.models.report_image import ReportImage
from app.models.user import User
from app.models.waste_report import WasteReport
from app.modules.reports import service as report_service
from app.services.capture_validation import parse_image_metadata
from app.modules.reports.feed_mix import UserLocation, merge_location_feed
from app.schemas.reports import (
    FeedMixInfo,
    ReportCreatedResponse,
    ReportFeedItem,
    ReportFeedResponse,
)
from app.services.storage import public_image_url

router = APIRouter(prefix="/reports", tags=["reports"])


def _location_label(report: WasteReport) -> str:
    parts = [report.ward_name, report.municipality_name, report.district_name]
    return " · ".join(p for p in parts if p)


def _feed_item(
    db: Session,
    report: WasteReport,
    author_name: str | None,
    location_tier: str | None = None,
) -> ReportFeedItem:
    paths = db.scalars(select(ReportImage.file_path).where(ReportImage.report_id == report.id)).all()
    return ReportFeedItem(
        id=report.id,
        category=report.category.value,
        description=report.description,
        address=report.address or _location_label(report) or None,
        ward_name=report.ward_name,
        municipality_name=report.municipality_name,
        district_name=report.district_name,
        latitude=report.latitude,
        longitude=report.longitude,
        status=report.status.value,
        upvote_count=report.upvote_count,
        comment_count=report.comment_count,
        author_name=author_name,
        image_urls=[public_image_url(p) for p in paths],
        location_tier=location_tier,
        created_at=report.created_at,
    )


def _resolve_viewer_location(
    user: User | None,
    lat: float | None,
    lng: float | None,
    ward: str | None,
    municipality: str | None,
    district: str | None,
) -> UserLocation | None:
    if user:
        loc = UserLocation.from_user(user)
        if loc and loc.is_set:
            return loc
    if any([lat, lng, ward, municipality, district]):
        return UserLocation(
            latitude=lat,
            longitude=lng,
            ward=ward.strip().lower() if ward else None,
            municipality=municipality.strip().lower() if municipality else None,
            district=district.strip().lower() if district else None,
        )
    return None


@router.get("", response_model=ReportFeedResponse)
def public_feed(
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User | None, Depends(get_current_user_optional)],
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    lat: float | None = Query(None, description="Guest viewer latitude"),
    lng: float | None = Query(None, description="Guest viewer longitude"),
    ward: str | None = Query(None, description="Guest viewer ward"),
    municipality: str | None = Query(None, description="Guest viewer municipality"),
    district: str | None = Query(None, description="Guest viewer district"),
):
    """
    Feed blending when location is set (profile or query params):
    **60%** near you · **30%** surrounding · **10%** all Kerala.
    Newest posts appear first within each tier.
    Without location: all Kerala, newest first.
    """
    offset = (page - 1) * limit
    total = db.scalar(select(func.count()).select_from(WasteReport)) or 0

    all_reports = db.scalars(select(WasteReport).order_by(WasteReport.created_at.desc())).all()
    user_ids = {r.user_id for r in all_reports if r.user_id}
    author_map: dict = {}
    if user_ids:
        author_map = dict(db.execute(select(User.id, User.name).where(User.id.in_(user_ids))).all())

    viewer_loc = _resolve_viewer_location(user, lat, lng, ward, municipality, district)
    mixed, mix_meta = merge_location_feed(all_reports, viewer_loc, limit=limit, offset=offset)

    items = [
        _feed_item(
            db,
            report,
            author_map.get(report.user_id) if report.user_id else None,
            location_tier=tier.value,
        )
        for report, tier in mixed
    ]

    return ReportFeedResponse(
        items=items,
        total=total,
        page=page,
        limit=limit,
        mix=FeedMixInfo(**mix_meta),
    )


@router.post("", response_model=ReportCreatedResponse, status_code=201)
async def create_report(
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    category: Annotated[str, Form()],
    description: Annotated[str, Form()],
    latitude: Annotated[float | None, Form()] = None,
    longitude: Annotated[float | None, Form()] = None,
    address: Annotated[str | None, Form()] = None,
    ward_name: Annotated[str | None, Form()] = None,
    municipality_name: Annotated[str | None, Form()] = None,
    district_name: Annotated[str | None, Form()] = None,
    image_metadata: Annotated[str | None, Form()] = None,
    images: Annotated[list[UploadFile], File()] = [],
):
    if not description.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Description is required")

    file_list = images if isinstance(images, list) else [images] if images else []
    if not file_list:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="At least one photo is required")

    metadata = parse_image_metadata(image_metadata, len(file_list))

    try:
        report = await report_service.create_report(
            db,
            user,
            category=category,
            description=description,
            latitude=latitude,
            longitude=longitude,
            address=address,
            ward_name=ward_name,
            municipality_name=municipality_name,
            district_name=district_name,
            images=file_list,
            image_metadata=metadata,
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc)) from exc

    return ReportCreatedResponse(id=report.id, status=report.status.value)
