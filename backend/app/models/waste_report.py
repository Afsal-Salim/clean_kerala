import enum
import uuid

from sqlalchemy import Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.mixins import AuditMixin


class ReportStatus(str, enum.Enum):
    posted = "posted"
    pending_ngo = "pending_ngo"
    accepted = "accepted"
    resolved = "resolved"
    closed = "closed"


class WasteCategory(str, enum.Enum):
    plastic = "plastic"
    food = "food"
    construction = "construction"
    electronic = "electronic"
    biomedical = "biomedical"
    overflowing_dustbin = "overflowing_dustbin"
    roadside = "roadside"
    canal = "canal"
    beach = "beach"
    illegal_dumping = "illegal_dumping"


class WasteReport(AuditMixin, Base):
    __tablename__ = "waste_reports"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    category: Mapped[WasteCategory] = mapped_column(Enum(WasteCategory, name="waste_category"), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    ward_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    municipality_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    district_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    ward_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wards.id", ondelete="SET NULL"), nullable=True, index=True
    )
    municipality_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("municipalities.id", ondelete="SET NULL"), nullable=True, index=True
    )
    district_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("districts.id", ondelete="SET NULL"), nullable=True, index=True
    )
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[ReportStatus] = mapped_column(
        Enum(ReportStatus, name="report_status"), default=ReportStatus.pending_ngo, nullable=False, index=True
    )
    upvote_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    comment_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
