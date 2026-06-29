# Stage 1 — Community Platform

> **Status:** In progress  
> **Last updated:** 2026-06-28  
> **Depends on:** —  
> **Blocks:** Stage 2

---

## Goal

Launch a **community-first** platform — similar to a Facebook feed for waste — where citizens post reports, NGOs respond, and accepted reports become trackable **issues**. No government integration yet; NGOs are the primary responders.

---

## Product Concept

```
Citizen posts waste report (photo + location + description)
        ↓
Appears on public feed (ward / municipality scoped)
        ↓
Nearby NGOs notified (push + in-app)
        ↓
NGO accepts  →  status: accepted + OPEN ISSUE created
NGO rejects  →  no status change; logged only; other NGOs can still accept
        ↓
NGO resolves issue (upload completion photo)
        ↓
Citizen confirms → Issue closed
```

---

## Scope

### Backend — Achievements & Badges

- [ ] `badges` catalog — milestone definitions (threshold, name, tier, icon)
- [ ] `user_achievements` — badges earned per user (unique per badge)
- [ ] `close_counters` — running total of closes per user (and per NGO entity)
- [ ] On issue `closed`: increment counters for citizen, NGO admin(s), assigned volunteer
- [ ] Milestone check → auto-award badge + notification
- [ ] Idempotent award (same badge never twice)
- [ ] Public profile API returns earned badges and close count
- [ ] Seed default milestones: 10, 100, 1,000, 10,000

### Backend — Auth & Users

- [ ] FastAPI project structure with modular layout
- [ ] PostgreSQL + Alembic migrations
- [ ] Redis for caching and notification queue prep
- [ ] User registration / login with JWT
- [ ] Roles: `citizen`, `ngo_admin`, `volunteer`, `system_admin`
- [ ] Profile with optional home location

### Backend — Geography

- [x] Models: `districts`, `municipalities`, `wards` (with audit columns)
- [ ] Seed Kerala geography data (or admin CRUD)
- [ ] Reverse geocode lat/lng → ward / municipality / district
- [ ] GPS validation (configurable Kerala bounds)

### Backend — Waste Reports (Social Feed)

- [ ] `waste_reports` model — the "post" (photo, description, category, location)
- [ ] Create report with GPS, ward, municipality, district
- [ ] Public feed API (paginated, filter by geography)
- [ ] Report detail with comments and upvote count
- [ ] Comments on reports
- [ ] Upvote reports
- [ ] Report status: `posted` · `pending_ngo` · `accepted` · `resolved` · `closed` (no `rejected` — reject is logged in `ngo_responses` only)
- [ ] **Max 3 photos** per report (enforce on create)
- [ ] **Rate limit: 5 reports per user per day**

### Backend — NGO Module

- [ ] NGO registration (name, district, contact, service areas)
- [ ] NGO admin links user account to NGO profile
- [ ] Define NGO service radius or ward list
- [ ] List incoming report requests for NGO
- [ ] **Accept** report → `pending_ngo` → `accepted`, creates `issue`, assigns NGO
- [ ] **Reject** report → log in `ngo_responses` only; **report status unchanged** (`pending_ngo`)
- [ ] NGO dashboard: open issues, in progress, resolved

### Backend — Issues (Accepted Reports)

- [ ] `issues` model — created when NGO accepts a report
- [ ] Issue status: `open` · `in_progress` · `resolved` · `closed`
- [ ] Status history / audit log
- [ ] Assign volunteers to issue (optional, basic)
- [ ] Upload completion photo
- [ ] Citizen confirmation to close

### Backend — Notifications

- [ ] Notify nearby NGOs when report posted (geo query by ward/radius)
- [ ] Push notification (Firebase) + in-app notification list
- [ ] Notify citizen when NGO **accepts** or **resolves** (not on single reject — see DECISIONS.md)
- [ ] Email notifications (optional)

### Backend — Media

- [x] Local image upload for report photos (camera-only + metadata validation)
- [ ] S3 image upload for report photos
- [ ] Completion photo upload (camera-only)
- [ ] Signed URL retrieval

### Backend — Waste verification

- [x] Require `image_metadata` on report create (source, timestamp, waste confidence)
- [x] Reject gallery / stale captures server-side
- [ ] Server-side ML classification (Stage 3)
- [ ] Duplicate image detection (Stage 3)

### Backend — Map analytics

- [x] Stats API — Kerala / district / local body / ward drill-down
- [x] Import district GeoJSON (geohacker/kerala)
- [ ] Import local body + ward GeoJSON (OpenDataKerala / kerala-wards)
- [ ] Geo registry (canonical slugs + Malayalam names)
- [ ] PostGIS point-in-polygon (optional)

### Frontend — Map analytics

- [x] Analytics screen — OSM base map + stats drill-down list
- [ ] Choropleth district polygons (tap to zoom)
- [ ] Local body + ward boundary layers on drill-down
- [ ] Filter feed from ward stats tile

### Frontend — Citizen

- [ ] Login / register
- [ ] **Feed screen** — scroll waste reports (like social feed)
- [ ] **Create post** — **camera-only**, on-device waste check, GPS, category, description
- [ ] Report detail — comments, upvotes, status
- [ ] My reports — track status
- [ ] **Profile** — earned badges, close count, highest badge displayed
- [ ] Push notification when a new badge is earned
- [ ] Push notification handling

### Frontend — NGO Admin

- [ ] NGO registration / profile setup
- [ ] **Incoming requests** — accept / reject with reason
- [ ] **My issues** — open, in progress, resolved
- [ ] Mark in progress, upload **camera-only** completion photo, mark resolved
- [ ] **NGO profile** — badges and total closes visible publicly

### Frontend — Volunteer (Basic)

- [ ] Join NGO (request or invite)
- [ ] View assigned issues
- [ ] Log participation on cleanup

### DevOps

- [ ] Docker Compose (PostgreSQL + Redis)
- [ ] `.env.example`
- [ ] OpenAPI docs

---

## Database Tables (Stage 1)

| Table | Purpose |
|-------|---------|
| `users` | All users |
| `districts` | Geography |
| `municipalities` | Geography |
| `wards` | Geography |
| `ngos` | NGO profiles and service areas |
| `ngo_service_areas` | Wards or radius per NGO |
| `waste_reports` | Citizen posts (social feed) |
| `report_images` | Photos attached to reports |
| `report_comments` | Comments on feed posts |
| `report_upvotes` | Upvotes |
| `issues` | Accepted reports assigned to NGO |
| `issue_status_history` | Audit trail |
| `ngo_responses` | Accept / reject log with reason |
| `notifications` | In-app + push log |
| `volunteers` | Basic volunteer link to NGO |
| `badges` | Milestone badge definitions (10, 100, 1000…) |
| `user_achievements` | Badges earned by each user |
| `close_counters` | Per-user (and per-NGO) closed issue totals |

---

## API Endpoints (Stage 1)

### Auth

```
POST /api/v1/auth/register          # account_type: basic | ngo | admin
POST /api/v1/auth/verify-email      # OTP after signup
POST /api/v1/auth/resend-otp
POST /api/v1/auth/login
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET  /api/v1/auth/profile
```

### Quotes (home awareness banner)

```
GET  /api/v1/quotes
GET  /api/v1/quotes/random
```

### Feed / Reports

```
POST   /api/v1/reports              # Create waste report (post)
GET    /api/v1/reports              # Public feed (paginated)
GET    /api/v1/reports/{id}
POST   /api/v1/reports/{id}/comments
POST   /api/v1/reports/{id}/upvote
GET    /api/v1/reports/mine        # My reports
```

### NGOs

```
POST   /api/v1/ngos                 # Register NGO
GET    /api/v1/ngos/{id}
PUT    /api/v1/ngos/{id}
GET    /api/v1/ngos/{id}/incoming   # Reports awaiting response
POST   /api/v1/ngos/{id}/accept/{report_id}
POST   /api/v1/ngos/{id}/reject/{report_id}
```

### Issues

```
GET    /api/v1/issues               # NGO's issues
GET    /api/v1/issues/{id}
PUT    /api/v1/issues/{id}/progress # Mark in progress
POST   /api/v1/issues/{id}/complete # Upload completion, mark resolved
POST   /api/v1/issues/{id}/confirm  # Citizen confirms closure
```

### Media

```
POST   /api/v1/media/upload
GET    /api/v1/media/{id}
```

### Notifications

```
GET    /api/v1/notifications
PUT    /api/v1/notifications/{id}/read
```

### Achievements

```
GET    /api/v1/achievements/badges           # All badge definitions
GET    /api/v1/achievements/me               # My badges + close count + next milestone
GET    /api/v1/achievements/users/{id}       # Public badges for a user profile
GET    /api/v1/achievements/ngos/{id}        # Badges for NGO (aggregate closes)
```

---

## Report → Issue State Machine

```
posted
  ↓ (nearby NGOs notified)
pending_ngo
  ↓ accept only              ↓ reject (status stays pending_ngo)
accepted → issue: open       ngo_responses row only
  ↓
issue: in_progress
  ↓
issue: resolved
  ↓ (citizen confirms)
issue: closed  →  increment close_counters  →  check milestones  →  award badge(s)
```

See [DECISIONS.md](../DECISIONS.md) for limits (3 photos, 5 reports/day).

---

## NGO Matching Logic

When a report is posted:

1. Resolve `ward_id`, `municipality_id`, `district_id` from GPS
2. Find NGOs whose service area includes that ward (or within radius km)
3. Send push + in-app notification to each matching NGO
4. First NGO to accept gets the issue (lock / optimistic concurrency)
5. Rejected NGOs are not re-notified for same report; **report status remains `pending_ngo`**

---

## Report Limits

| Rule | Value |
|------|-------|
| Max photos per report | 3 |
| Reports per user per day | 5 |

---

## Acceptance Criteria

- [ ] Citizen can post a waste report with photo and GPS; it appears on the feed
- [ ] Report shows ward, municipality, and district
- [ ] Nearby NGOs receive notification within seconds of posting
- [ ] NGO can accept → report status becomes `accepted` and open issue is created
- [ ] NGO can reject with reason → report status **unchanged**; rejection stored in `ngo_responses`
- [ ] Report rejects at most 3 photos; 4th photo returns validation error
- [ ] User cannot create more than 5 reports in one day
- [ ] NGO can mark issue in progress, upload completion photo, mark resolved
- [ ] Citizen receives notifications at accept, resolve, and close
- [ ] Feed supports comments and upvotes
- [ ] Only one NGO can hold an issue per report
- [ ] When an issue closes, close counters update for citizen, NGO, and volunteer (if assigned)
- [ ] User earns a badge at 10, 100, and 1,000 closes; badge appears on profile
- [ ] User receives push notification when a new badge is earned
- [ ] Public profile shows all earned badges and total close count

---

## Out of Scope (Deferred)

- Government / official accounts (Stage 2)
- AI classification (Stage 3)
- Funding and donation dashboard (Stage 3)
- Leaderboards and competitive rankings (Stage 3)
- SMS notifications

---

## Completion Checklist

When Stage 1 is done:

1. Mark all scope items and acceptance criteria above
2. Update status in [STAGES.md](../STAGES.md)
3. Update [README.md](../../README.md) stage table
4. Update [HLD.md](../HLD.md) and [LLD.md](../LLD.md)
