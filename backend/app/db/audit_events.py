"""Auto-fill audit columns and append row_audit_logs on insert/update."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import event, inspect
from sqlalchemy.orm import Session

from app.core.audit_context import get_audit_info
from app.db.mixins import AuditMixin


def _serialize(value: Any) -> Any:
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if hasattr(value, "value"):
        return value.value
    return value


def _row_snapshot(instance) -> dict[str, Any]:
    snap: dict[str, Any] = {}
    for col in inspect(instance.__class__).columns:
        if col.name in ("password_hash", "token_hash", "otp_code"):
            snap[col.name] = "[redacted]"
            continue
        snap[col.name] = _serialize(getattr(instance, col.name, None))
    return snap


def _apply_audit_fields(target: AuditMixin, is_insert: bool) -> None:
    info = get_audit_info()
    if not info:
        return

    user_id = info.user_id
    api = info.api_route
    ip = info.ip_address

    if is_insert:
        if user_id and target.created_by_user_id is None:
            target.created_by_user_id = user_id
        if api and not target.created_by_api:
            target.created_by_api = api
        if ip and not target.created_ip:
            target.created_ip = ip
        if user_id and target.updated_by_user_id is None:
            target.updated_by_user_id = user_id
        if api and not target.updated_by_api:
            target.updated_by_api = api
        if ip and not target.updated_ip:
            target.updated_ip = ip
    else:
        if user_id:
            target.updated_by_user_id = user_id
        if api:
            target.updated_by_api = api
        if ip:
            target.updated_ip = ip
        target.row_version = (target.row_version or 0) + 1


def _queue_row_audit(session: Session, entry: dict) -> None:
    session.info.setdefault("row_audit_queue", []).append(entry)


def register_audit_events() -> None:
    @event.listens_for(AuditMixin, "before_insert", propagate=True)
    def _before_insert(mapper, connection, target):  # noqa: ARG001
        if isinstance(target, AuditMixin):
            _apply_audit_fields(target, is_insert=True)

    @event.listens_for(AuditMixin, "before_update", propagate=True)
    def _before_update(mapper, connection, target):  # noqa: ARG001
        if isinstance(target, AuditMixin):
            _apply_audit_fields(target, is_insert=False)

    @event.listens_for(Session, "after_flush")
    def _after_flush(session: Session, flush_context):  # noqa: ARG001
        from app.models.row_audit_log import RowAuditLog

        info = get_audit_info()
        for instance in session.new:
            if not isinstance(instance, AuditMixin):
                continue
            row_id = getattr(instance, "id", None)
            if row_id is None:
                continue
            _queue_row_audit(
                session,
                {
                    "table_name": instance.__tablename__,
                    "row_id": row_id,
                    "action": "insert",
                    "old_values": None,
                    "new_values": _row_snapshot(instance),
                    "changed_by_user_id": info.user_id if info else None,
                    "changed_by_api": info.api_route if info else None,
                    "changed_ip": info.ip_address if info else None,
                    "changed_at": datetime.now(timezone.utc),
                },
            )

        for instance in session.dirty:
            if not isinstance(instance, AuditMixin):
                continue
            if not session.is_modified(instance, include_collections=False):
                continue
            row_id = getattr(instance, "id", None)
            if row_id is None:
                continue
            state = inspect(instance)
            old_values = {
                attr.key: _serialize(attr.history.deleted[0] if attr.history.deleted else getattr(instance, attr.key))
                for attr in state.attrs
                if attr.history.has_changes() and attr.key != "row_version"
            }
            _queue_row_audit(
                session,
                {
                    "table_name": instance.__tablename__,
                    "row_id": row_id,
                    "action": "update",
                    "old_values": old_values,
                    "new_values": _row_snapshot(instance),
                    "changed_by_user_id": info.user_id if info else None,
                    "changed_by_api": info.api_route if info else None,
                    "changed_ip": info.ip_address if info else None,
                    "changed_at": datetime.now(timezone.utc),
                },
            )

    @event.listens_for(Session, "after_commit")
    def _after_commit(session: Session):
        from app.models.row_audit_log import RowAuditLog
        from app.db.session import SessionLocal

        queue = session.info.pop("row_audit_queue", [])
        if not queue:
            return
        audit_db = SessionLocal()
        try:
            for entry in queue:
                audit_db.add(RowAuditLog(**entry))
            audit_db.commit()
        except Exception:
            audit_db.rollback()
            raise
        finally:
            audit_db.close()
