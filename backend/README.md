# Backend — Make Kerala Clean

FastAPI backend for the MKC platform.

## Quick start

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
docker compose up -d
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

## Auth (implemented)

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/auth/register` | Sign up (`account_type`: basic, ngo, admin) |
| `POST /api/v1/auth/verify-email` | Verify OTP after signup |
| `POST /api/v1/auth/resend-otp` | Resend OTP |
| `POST /api/v1/auth/login` | Login (requires verified email) |
| `POST /api/v1/auth/forgot-password` | Send reset OTP |
| `POST /api/v1/auth/reset-password` | Reset with OTP |
| `GET /api/v1/auth/profile` | Current user (Bearer token) |

**Admin signup** requires `admin_code`: `MKC-ADMIN-2026`

## OTP email

- HTML template: `app/templates/email/otp_verification.html`
- Without SMTP configured, OTP is **printed in server logs** (`LOG_OTP_TO_CONSOLE=true`)

## Public home APIs

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/reports` | Waste report feed (no login required) |
| `POST /api/v1/reports` | Create report (auth, max 3 photos, 5/day) |
| `GET /api/v1/quotes/random` | Random cleanliness awareness quote |

## Environment

See `.env.example`. Configure `SMTP_*` for real email delivery.

## Database

Full schema and audit design: [docs/DATABASE.md](../docs/DATABASE.md)

Every table includes **audit columns** (`created_at`, `updated_at`, `created_by_user_id`, `created_by_api`, etc.) plus append-only **`row_audit_logs`** for change history.

```bash
docker compose up -d
alembic upgrade head                    # apply migrations
alembic revision --autogenerate -m "…"  # after model changes
```

On dev boot, `uvicorn` also runs `create_all` if tables are missing.
