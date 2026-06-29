import enum
import uuid

from sqlalchemy import Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.mixins import AuditMixin


class LocalBodyType(str, enum.Enum):
    corporation = "corporation"
    municipality = "municipality"
    gram_panchayat = "gram_panchayat"


class District(AuditMixin, Base):
    __tablename__ = "districts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    slug: Mapped[str] = mapped_column(String(120), unique=True, nullable=False, index=True)
    census_code: Mapped[int | None] = mapped_column(Integer, nullable=True)
    state_name: Mapped[str] = mapped_column(String(60), default="Kerala", nullable=False)


class Municipality(AuditMixin, Base):
    __tablename__ = "municipalities"
    __table_args__ = (UniqueConstraint("district_id", "slug", name="uq_municipality_district_slug"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    district_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("districts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    slug: Mapped[str] = mapped_column(String(160), nullable=False, index=True)
    local_body_type: Mapped[LocalBodyType] = mapped_column(
        Enum(LocalBodyType, name="local_body_type"), nullable=False, default=LocalBodyType.gram_panchayat
    )


class Ward(AuditMixin, Base):
    __tablename__ = "wards"
    __table_args__ = (UniqueConstraint("municipality_id", "slug", name="uq_ward_municipality_slug"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    municipality_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("municipalities.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    slug: Mapped[str] = mapped_column(String(160), nullable=False, index=True)
    ward_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
