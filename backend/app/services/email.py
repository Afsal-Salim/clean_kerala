import logging
from email.message import EmailMessage
from pathlib import Path

import aiosmtplib
from jinja2 import Environment, FileSystemLoader, select_autoescape

from app.core.config import settings

logger = logging.getLogger(__name__)

TEMPLATE_DIR = Path(__file__).resolve().parent.parent / "templates" / "email"
_jinja = Environment(
    loader=FileSystemLoader(str(TEMPLATE_DIR)),
    autoescape=select_autoescape(["html"]),
)


def _render_otp_email(
    *,
    name: str,
    otp_code: str,
    purpose: str,
) -> tuple[str, str]:
    if purpose == "password_reset":
        subject = "Reset your Make Kerala Clean password"
        purpose_label = "Password reset"
        intro_text = "Use the code below to reset your password."
    else:
        subject = "Verify your Make Kerala Clean account"
        purpose_label = "Email verification"
        intro_text = "Welcome! Use the code below to verify your email and activate your account."

    html = _jinja.get_template("otp_verification.html").render(
        subject=subject,
        name=name,
        otp_code=otp_code,
        purpose_label=purpose_label,
        intro_text=intro_text,
        expire_minutes=settings.otp_expire_minutes,
        year=2026,
    )
    return subject, html


async def send_otp_email(*, to_email: str, name: str, otp_code: str, purpose: str) -> None:
    subject, html_body = _render_otp_email(name=name, otp_code=otp_code, purpose=purpose)

    if settings.log_otp_to_console or not settings.smtp_configured:
        logger.info("OTP for %s (%s): %s", to_email, purpose, otp_code)
        if not settings.smtp_configured:
            return

    message = EmailMessage()
    message["From"] = settings.smtp_from
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(html_body, subtype="html")

    await aiosmtplib.send(
        message,
        recipients=[to_email],
        sender=settings.smtp_from,
        hostname=settings.smtp_host,
        port=settings.smtp_port,
        username=settings.smtp_user,
        password=settings.smtp_password,
        start_tls=settings.smtp_tls,
    )
