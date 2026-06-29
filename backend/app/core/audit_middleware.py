from uuid import UUID

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.audit_context import AuditInfo, reset_audit_info, set_audit_info
from app.core.security import decode_token


class AuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        user_id = None
        auth = request.headers.get("authorization")
        if auth and auth.lower().startswith("bearer "):
            payload = decode_token(auth.split(" ", 1)[1])
            if payload and payload.get("type") == "access" and payload.get("sub"):
                try:
                    user_id = UUID(payload["sub"])
                except ValueError:
                    user_id = None

        api_route = f"{request.method} {request.url.path}"
        ip = request.client.host if request.client else None
        ua = request.headers.get("user-agent")

        token = set_audit_info(AuditInfo(user_id=user_id, api_route=api_route, ip_address=ip, user_agent=ua))
        try:
            return await call_next(request)
        finally:
            reset_audit_info(token)
