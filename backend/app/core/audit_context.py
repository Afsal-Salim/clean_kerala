"""Request-scoped audit metadata (user, API route, IP) for DB writes."""

from __future__ import annotations

import uuid
from contextvars import ContextVar
from dataclasses import dataclass


@dataclass(frozen=True)
class AuditInfo:
    user_id: uuid.UUID | None = None
    api_route: str | None = None
    ip_address: str | None = None
    user_agent: str | None = None


_audit_context: ContextVar[AuditInfo | None] = ContextVar("audit_context", default=None)


def get_audit_info() -> AuditInfo | None:
    return _audit_context.get()


def set_audit_info(info: AuditInfo):
    return _audit_context.set(info)


def reset_audit_info(token) -> None:
    _audit_context.reset(token)


def audit_info_for_system(api_route: str = "system/seed") -> AuditInfo:
    """Use in scripts and background jobs."""
    return AuditInfo(user_id=None, api_route=api_route, ip_address=None)
