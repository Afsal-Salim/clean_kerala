import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.mixins import AuditMixin


class ReportImageType(str, enum.Enum):
    report = "report"
    completion = "completion"


class ReportImage(AuditMixin, Base):
    __tablename__ = "report_images"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("waste_reports.id", ondelete="CASCADE"), index=True
    )
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    image_type: Mapped[ReportImageType] = mapped_column(
        Enum(ReportImageType, name="report_image_type"), default=ReportImageType.report, nullable=False
    )
    source: Mapped[str] = mapped_column(String(20), nullable=False, default="camera")
    captured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    waste_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    waste_labels: Mapped[str | None] = mapped_column(String(500), nullable=True)
