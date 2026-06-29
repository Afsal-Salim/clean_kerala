import json
from datetime import datetime, timezone

from fastapi import HTTPException, status
from pydantic import BaseModel, Field

from app.core.config import settings


class ImageCaptureMeta(BaseModel):
    captured_at: datetime
    source: str = Field(default="camera")
    latitude: float | None = None
    longitude: float | None = None
    waste_confidence: float = Field(ge=0, le=1)
    waste_labels: list[str] = Field(default_factory=list)


def parse_image_metadata(raw: str | None, image_count: int) -> list[ImageCaptureMeta]:
    if not raw or not raw.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IMAGE_METADATA_REQUIRED",
        )
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="INVALID_IMAGE_METADATA",
        ) from exc

    if not isinstance(payload, list):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="INVALID_IMAGE_METADATA")

    if len(payload) != image_count:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IMAGE_METADATA_COUNT_MISMATCH",
        )

    try:
        return [ImageCaptureMeta.model_validate(item) for item in payload]
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="INVALID_IMAGE_METADATA",
        ) from exc


def validate_capture_metadata(meta: ImageCaptureMeta) -> None:
    if meta.source != "camera":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="GALLERY_NOT_ALLOWED",
        )

    if meta.captured_at.tzinfo is None:
        captured = meta.captured_at.replace(tzinfo=timezone.utc)
    else:
        captured = meta.captured_at.astimezone(timezone.utc)

    age_seconds = (datetime.now(timezone.utc) - captured).total_seconds()
    if age_seconds < 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="FUTURE_CAPTURE_TIME")
    if age_seconds > settings.capture_max_age_seconds:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="STALE_CAPTURE")

    if settings.waste_verification_enabled and meta.waste_confidence < settings.waste_verification_min_confidence:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="WASTE_NOT_DETECTED",
        )
