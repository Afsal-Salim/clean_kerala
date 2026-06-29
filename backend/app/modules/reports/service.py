from datetime import datetime, timezone

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.report_image import ReportImage
from app.models.user import User
from app.models.waste_report import ReportStatus, WasteCategory, WasteReport
from app.services.capture_validation import ImageCaptureMeta, validate_capture_metadata
from app.services.storage import public_image_url, save_report_images
from app.services.waste_verification import validate_image_content


def _utc_day_start() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def check_rate_limit(db: Session, user_id) -> None:
    count = db.scalar(
        select(func.count())
        .select_from(WasteReport)
        .where(
            WasteReport.user_id == user_id,
            WasteReport.created_at >= _utc_day_start(),
        )
    )
    if count and count >= settings.max_reports_per_day:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="REPORT_RATE_LIMIT_EXCEEDED",
        )


async def create_report(
    db: Session,
    user: User,
    *,
    category: str,
    description: str,
    latitude: float | None,
    longitude: float | None,
    address: str | None,
    ward_name: str | None,
    municipality_name: str | None,
    district_name: str | None,
    images: list[UploadFile],
    image_metadata: list[ImageCaptureMeta],
) -> WasteReport:
    if not images:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="At least one photo is required")
    if len(images) > settings.max_photos_per_report:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="MAX_PHOTOS_EXCEEDED")

    check_rate_limit(db, user.id)

    try:
        cat = WasteCategory(category)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category") from exc

    report = WasteReport(
        user_id=user.id,
        category=cat,
        description=description.strip(),
        latitude=latitude,
        longitude=longitude,
        address=address,
        ward_name=ward_name,
        municipality_name=municipality_name,
        district_name=district_name,
        status=ReportStatus.pending_ngo,
    )
    db.add(report)
    db.flush()

    for meta in image_metadata:
        validate_capture_metadata(meta)

    try:
        saved = await save_report_images(report.id, images)
    except ValueError as e:
        db.rollback()
        code = str(e)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=code) from e

    for (path, content), meta in zip(saved, image_metadata, strict=True):
        try:
            validate_image_content(content)
        except ValueError as e:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)) from e

        labels = ",".join(meta.waste_labels[:8]) if meta.waste_labels else None
        db.add(
            ReportImage(
                report_id=report.id,
                file_path=path,
                source=meta.source,
                captured_at=meta.captured_at,
                latitude=meta.latitude,
                longitude=meta.longitude,
                waste_confidence=meta.waste_confidence,
                waste_labels=labels,
            )
        )

    db.commit()
    db.refresh(report)
    return report


def get_report_image_urls(db: Session, report_id) -> list[str]:
    rows = db.scalars(select(ReportImage.file_path).where(ReportImage.report_id == report_id)).all()
    return [public_image_url(p) for p in rows]
