"""Shared columns for row-level audit on every business table."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column


class AuditMixin:
    """Who/when/which API created or last updated a row."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
    created_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    updated_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    created_by_api: Mapped[str | None] = mapped_column(String(160), nullable=True)
    updated_by_api: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_ip: Mapped[str | None] = mapped_column(String(45), nullable=True)
    updated_ip: Mapped[str | None] = mapped_column(String(45), nullable=True)
    row_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
