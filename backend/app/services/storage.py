import uuid
from pathlib import Path

from fastapi import UploadFile

from app.core.config import settings

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def ensure_upload_dir() -> Path:
    path = Path(settings.upload_dir)
    path.mkdir(parents=True, exist_ok=True)
    return path


async def save_report_images(report_id: uuid.UUID, files: list[UploadFile]) -> list[tuple[str, bytes]]:
    if len(files) > settings.max_photos_per_report:
        raise ValueError("MAX_PHOTOS_EXCEEDED")

    upload_root = ensure_upload_dir() / "reports" / str(report_id)
    upload_root.mkdir(parents=True, exist_ok=True)

    saved: list[tuple[str, bytes]] = []
    for file in files:
        ext = Path(file.filename or "").suffix.lower()
        if ext not in ALLOWED_EXTENSIONS:
            ext = ".jpg"
        if file.content_type and file.content_type not in ALLOWED_CONTENT_TYPES:
            raise ValueError("INVALID_IMAGE_TYPE")

        filename = f"{uuid.uuid4()}{ext}"
        relative = f"reports/{report_id}/{filename}"
        dest = upload_root / filename

        content = await file.read()
        dest.write_bytes(content)
        saved.append((relative, content))

    return saved


def public_image_url(relative_path: str) -> str:
    return f"{settings.public_base_url.rstrip('/')}/uploads/{relative_path}"
