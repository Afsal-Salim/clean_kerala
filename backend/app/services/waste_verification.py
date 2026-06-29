"""Waste image verification — MVP uses client ML Kit scores + metadata.

Stage 3 adds server-side classification models and duplicate detection.
"""

from io import BytesIO

from PIL import Image

from app.core.config import settings


def validate_image_content(content: bytes) -> None:
    """Basic sanity checks on uploaded bytes (not a substitute for ML)."""
    if len(content) < 5_000:
        raise ValueError("IMAGE_TOO_SMALL")

    try:
        with Image.open(BytesIO(content)) as img:
            width, height = img.size
    except Exception as exc:
        raise ValueError("INVALID_IMAGE") from exc

    if width < settings.min_image_width or height < settings.min_image_height:
        raise ValueError("IMAGE_RESOLUTION_TOO_LOW")
