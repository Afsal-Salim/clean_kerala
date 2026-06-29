# Make Kerala Clean — Low-Level Design (LLD)

> **Last updated:** 2026-06-28  
> **Stage:** Pre-implementation (design baseline)

---

## 1. Modules Overview

| Module | Stage | Path (planned) |
|--------|-------|----------------|
| Authentication | 1 | `backend/app/modules/auth/` |
| Geography | 1 | `backend/app/modules/geography/` |
| Reports / Feed | 1 | `backend/app/modules/reports/` |
| NGO | 1 | `backend/app/modules/ngo/` |
| Issues | 1 | `backend/app/modules/issues/` |
| Media | 1 | `backend/app/modules/media/` |
| Notifications | 1 | `backend/app/modules/notifications/` |
| Volunteers | 1 | `backend/app/modules/volunteers/` |
| Achievements | 1 | `backend/app/modules/achievements/` |
| Officials | 2 | `backend/app/modules/officials/` |
| Escalation | 2 | `backend/app/modules/escalation/` |
| Analytics | 2 | `backend/app/modules/analytics/` |
| Funding | 3 | `backend/app/modules/funding/` |
| Donations | 3 | `backend/app/modules/donations/` |
| AI Classification | 3 | `backend/app/modules/ai/` |
| Rewards | 3 | `backend/app/modules/rewards/` |
| Admin | 1–3 | `backend/app/modules/admin/` |

---

## 2. Authentication Module (Stage 1)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register (`account_type`: basic, ngo, admin) |
| POST | `/api/v1/auth/verify-email` | Verify email with OTP |
| POST | `/api/v1/auth/resend-otp` | Resend OTP |
| POST | `/api/v1/auth/login` | Login (email must be verified) |
| POST | `/api/v1/auth/forgot-password` | Send password-reset OTP |
| POST | `/api/v1/auth/reset-password` | Reset password with OTP |
| POST | `/api/v1/auth/logout` | Invalidate refresh token |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/auth/profile` | Current user profile |

### User Fields

```
id, name, email, phone, password_hash, role,
district_id, municipality_id, ward_id, created_at, updated_at
```

**Roles (Stage 1):** `citizen` · `ngo_admin` · `volunteer` · `system_admin`

---

## 3. Reports / Feed Module (Stage 1)

Citizen "posts" — the social feed entry point.

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/reports` | Create waste report (max 3 **camera** images; waste verification; 5/day rate limit) |
| GET | `/api/v1/reports` | Public feed (paginated, geo filter) |
| GET | `/api/v1/reports/{id}` | Report detail |
| GET | `/api/v1/reports/mine` | Current user's reports |
| POST | `/api/v1/reports/{id}/comments` | Add comment |
| POST | `/api/v1/reports/{id}/upvote` | Upvote report |

### waste_reports Fields

```
id, user_id, category, description, latitude, longitude, address,
district_id, municipality_id, ward_id, status, upvote_count,
comment_count, created_at, updated_at
```

**Report status:** `posted` · `pending_ngo` · `accepted` · `resolved` · `closed`

There is **no** `rejected` status. NGO reject is stored in `ngo_responses` only.

### Validation rules

| Rule | Enforcement |
|------|-------------|
| Max photos | 3 per report on `POST /reports` → `400 MAX_PHOTOS_EXCEEDED` |
| Rate limit | 5 reports per `user_id` per UTC calendar day → `429 REPORT_RATE_LIMIT_EXCEEDED` |
| Camera only | `image_metadata[].source` must be `camera` → `400 GALLERY_NOT_ALLOWED` |
| Fresh capture | `captured_at` within 15 min → `400 STALE_CAPTURE` |
| Waste detected | `waste_confidence` ≥ 0.35 (when enabled) → `400 WASTE_NOT_DETECTED` |
| Metadata | One metadata object per image file → `400 IMAGE_METADATA_*` |

**Multipart form fields:** `category`, `description`, location fields, `images[]`, `image_metadata` (JSON array string).

### NGO accept / reject

| Action | Report status | Side effects |
|--------|---------------|--------------|
| Accept | `pending_ngo` → `accepted` | Create `issue` (`open`); notify citizen |
| Reject | **unchanged** | Insert `ngo_responses`; no citizen notification (MVP) |

---

## 4. NGO Module (Stage 1)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ngos` | Register NGO |
| GET | `/api/v1/ngos/{id}` | NGO profile |
| PUT | `/api/v1/ngos/{id}` | Update NGO |
| GET | `/api/v1/ngos/{id}/incoming` | Reports awaiting accept/reject |
| POST | `/api/v1/ngos/{id}/accept/{report_id}` | Accept → status `accepted`, create issue |
| POST | `/api/v1/ngos/{id}/reject/{report_id}` | Reject → log only, **no status change** |

### ngos Fields

```
id, name, district_id, contact, logo_url, verified, created_at
```

### ngo_service_areas Fields

```
id, ngo_id, ward_id (nullable), radius_km (nullable), center_lat, center_lng
```

### ngo_responses Fields

```
id, ngo_id, report_id, action (accept|reject), reason, created_at
```

---

## 5. Issues Module (Stage 1)

Created when an NGO **accepts** a report.

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/issues` | List issues (NGO scoped) |
| GET | `/api/v1/issues/{id}` | Issue detail + timeline |
| PUT | `/api/v1/issues/{id}/progress` | Mark in progress |
| POST | `/api/v1/issues/{id}/complete` | Upload completion photo, mark resolved |
| POST | `/api/v1/issues/{id}/confirm` | Citizen confirms closure |

### issues Fields

```
id, report_id, ngo_id, assigned_volunteer_id, status,
completion_image_id, resolved_at, closed_at, created_at, updated_at
```

**Issue status:** `open` · `in_progress` · `resolved` · `closed`

### issue_status_history Fields

```
id, issue_id, old_status, new_status, updated_by, note, updated_at
```

---

## 6. Media Module (Stage 1)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/media/upload` | Upload image (multipart) |
| GET | `/api/v1/media/{id}` | Metadata / signed URL |
| DELETE | `/api/v1/media/{id}` | Delete (admin only) |

### report_images Fields

```
id, report_id, file_path, source (camera), captured_at, latitude, longitude,
waste_confidence, waste_labels, created_at
```

Stage 3 adds: `device_id`, server-side `ai_classification_id`, completion `type`

**Completion photos** (`POST /issues/{id}/complete`): same camera-only + `image_metadata` rules as reports.

---

## 6b. Analytics / Map Module (Stage 1)

Public Kerala statistics with drill-down: state → district → local body → ward.

Full architecture: [analytics-map.md](analytics-map.md)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/analytics/summary` | Kerala-wide totals |
| GET | `/api/v1/analytics/districts` | District list + counts |
| GET | `/api/v1/analytics/districts/{slug}` | District + local bodies |
| GET | `/api/v1/analytics/local-bodies/{slug}` | Local body + wards |
| GET | `/api/v1/analytics/wards/{slug}` | Ward detail |

Stats aggregated from `waste_reports.district_name`, `municipality_name`, `ward_name` (normalized).

### Map rendering (Flutter)

- **Tiles:** OpenStreetMap (free) via `flutter_map`
- **Boundaries:** GeoJSON from OpenDataKerala / geohacker/kerala / kerala-wards (free, ODbL)
- **No Google Maps API** required for MVP

---

## 7. Notifications Module (Stage 1)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notifications` | User notifications |
| PUT | `/api/v1/notifications/{id}/read` | Mark read |

### Trigger Events

| Event | Recipients |
|-------|------------|
| Report posted | Nearby NGOs |
| NGO accepted | Citizen (report author) |
| NGO rejected | — (no citizen alert unless all reject) |
| Issue resolved | Citizen |
| Issue closed | Citizen + NGO |
| Badge earned | User who earned the badge |

---

## 8. Achievements Module (Stage 1)

Badges awarded when an account reaches closed-issue milestones (10, 100, 1,000, 10,000).

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/achievements/badges` | All badge definitions |
| GET | `/api/v1/achievements/me` | Current user's badges, close count, next milestone |
| GET | `/api/v1/achievements/users/{id}` | Public badges for a user |
| GET | `/api/v1/achievements/ngos/{id}` | Badges and close count for an NGO |

### badges Fields

```
id, slug, name, description, threshold, tier (bronze|silver|gold|platinum),
icon_url, account_type (citizen|ngo|volunteer|any), created_at
```

**Default milestones:**

| threshold | name | tier |
|-----------|------|------|
| 10 | Green Starter | bronze |
| 100 | Clean Warrior | silver |
| 1,000 | Clean Kerala Champion | gold |
| 10,000 | Waste Hero | platinum |

### user_achievements Fields

```
id, user_id, badge_id, issue_id (triggering close, nullable), earned_at
UNIQUE (user_id, badge_id)
```

### close_counters Fields

```
id, user_id, ngo_id (nullable), counter_type (citizen|ngo|volunteer),
close_count, updated_at
UNIQUE (user_id, counter_type) OR (ngo_id, counter_type)
```

### Award Logic (on issue → closed)

```
1. Load issue + report + ngo + assigned_volunteer
2. Increment close_counters for:
     - report.user_id  (counter_type: citizen)
     - ngo linked to issue  (counter_type: ngo, ngo_id set)
     - volunteer if assigned  (counter_type: volunteer)
3. For each counter, find badges where threshold <= new close_count
     AND badge not in user_achievements
4. INSERT user_achievements + send push notification per new badge
5. Transaction must be atomic with issue close
```

---

## 9. Official Module (Stage 2)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/officials/dashboard` | Jurisdiction overview |
| GET | `/api/v1/officials/reports` | Reports in jurisdiction |
| GET | `/api/v1/officials/issues` | Issues in jurisdiction |
| POST | `/api/v1/officials/verify/{report_id}` | Mark report verified |
| POST | `/api/v1/officials/reject/{report_id}` | Flag fake report |
| POST | `/api/v1/officials/escalate/{issue_id}` | Escalate to higher authority |
| POST | `/api/v1/officials/assign/{issue_id}` | Assign govt cleaning team |
| POST | `/api/v1/officials/complete/{issue_id}` | Official completion |

### officials Fields

```
id, user_id, designation, district_id, municipality_id, ward_id, approved
```

### escalations Fields

```
id, issue_id, from_level, to_level, reason, escalated_by, created_at
```

---

## 10. Funding Module (Stage 3)

### Public APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/funding/summary` | Total in, spent, remaining |
| GET | `/api/v1/funding/donations` | Recent donations feed |
| GET | `/api/v1/funding/expenses` | Expense log |
| GET | `/api/v1/funding/breakdown` | By source and category |
| GET | `/api/v1/funding/stream` | SSE/WebSocket live updates |

### Donation APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/donations/create` | Initiate payment |
| POST | `/api/v1/donations/webhook` | Payment gateway callback |
| GET | `/api/v1/donations/{id}/receipt` | Donor receipt |

### funding_sources Fields

```
id, source_type (govt|organisation|other), name, amount, reference_no,
received_at, recorded_by, created_at
```

### donations Fields

```
id, user_id (nullable), amount, currency, donor_name, is_anonymous,
payment_ref, status, created_at
```

### expenses Fields

```
id, amount, category, description, issue_id (nullable), receipt_url,
recorded_by, created_at
```

### funding_ledger Fields (append-only)

```
id, entry_type (credit|debit), amount, source_table, source_id,
balance_after, created_at
```

**Balance formula:** `SUM(credits) − SUM(debits) = remaining`

On donation webhook success → insert donation → append ledger credit → publish real-time event.

---

## 11. AI Module (Stage 3)

### APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ai/classify` | Classify waste image |
| POST | `/api/v1/ai/duplicate-check` | Check nearby duplicates |
| POST | `/api/v1/ai/compare-images` | Before/after comparison |
| GET | `/api/v1/ai/hotspots` | Recurring location clusters |

### ai_classifications Fields

```
id, report_id, predicted_category, severity, confidence, model_version, created_at
```

---

## 12. Database Tables Summary

> **Canonical schema:** [DATABASE.md](DATABASE.md) — all tables, audit columns, API write map, ERD.

### Stage 1

`users` · `districts` · `municipalities` · `wards` · `waste_reports` · `report_images` · `report_comments` · `report_upvotes` · `ngos` · `ngo_service_areas` · `ngo_responses` · `issues` · `issue_status_history` · `notifications` · `volunteers` · **`badges` · `user_achievements` · `close_counters`**

### Stage 2

`officials` · `escalations` · `govt_assignments` · `sla_rules` · `partnership`

### Stage 3

`funding_sources` · `donations` · `expenses` · `funding_ledger` · `donation_campaigns` · `ai_classifications` · `rankings`

> `badges` and `user_achievements` are defined in Stage 1. Stage 3 may add leaderboard rankings that reference close counts.

---

## 13. State Machines

### Report (Stage 1)

```
posted → pending_ngo
  ↓ accept (first NGO wins)
accepted (issue created)
  ↓ resolve path via issue
resolved → closed
```

Reject path: NGO rejects → report stays `pending_ngo` for other NGOs.

### Issue (Stage 1)

```
open → in_progress → resolved → closed
```

### Issue + Government (Stage 2)

```
open → escalated → govt_in_progress → govt_resolved → closed
```

All transitions logged in `issue_status_history`.

---

## 14. NGO Matching Algorithm (Stage 1)

```
1. On report create: geocode → ward_id, municipality_id, district_id
2. Query NGOs where:
     - ward_id IN ngo_service_areas.ward_id
     OR haversine(report.lat/lng, service_area.center) <= radius_km
3. Insert notification row for each matching NGO
4. Dispatch push via Firebase async queue
5. On accept: SELECT FOR UPDATE on report → if `pending_ngo` → set `accepted` + create issue
6. On reject: INSERT `ngo_responses` only — report status stays `pending_ngo`
```

---

## 15. Real-Time Funding Update (Stage 3)

```
Payment webhook (donation succeeded)
  → BEGIN transaction
  → INSERT donations
  → INSERT funding_ledger (credit)
  → COMMIT
  → Redis PUBLISH funding:update { total, spent, remaining, latest_donation }
  → SSE/WebSocket clients receive event → UI refreshes
```

Target latency: **< 2 seconds** from payment confirmation to dashboard update.

---

## 16. Ranking & Leaderboards

### Closure milestone badges (Stage 1)

See § Achievements Module — badges at 10, 100, 1,000, 10,000 closes per account.

### NGO leaderboards (Stage 3)

Cleanups completed · volunteers participated · area covered · community rating · avg resolution time

### Competitive rankings (Stage 3)

Platform-wide leaderboards using `close_counters` and satisfaction scores.

### Officials (Stage 2+)

| Factor | Weight |
|--------|--------|
| Average resolution time | 30% |
| Issue closure rate | 30% |
| Citizen satisfaction | 20% |
| Pending issues (inverse) | 10% |
| Reopened issues (inverse) | 10% |

---

## 17. API Conventions

- Base path: `/api/v1`
- Auth header: `Authorization: Bearer <token>`
- Pagination: `?page=1&limit=20`
- Geo filter: `?district_id=&municipality_id=&ward_id=`
- Errors: `{ "detail": "...", "code": "REPORT_NOT_FOUND" }`
- Timestamps: ISO 8601 UTC
- Public funding endpoints: no auth required (read-only)

---

## 18. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-06-28 | Initial LLD from product spec | — |
| 2026-06-28 | Location-based feed 60/30/10; profile location API; location overlay on images | — |
| 2026-06-28 | Camera-only report photos; ML Kit waste check; capture metadata on `report_images` | — |
| 2026-06-28 | Analytics API (district/local body/ward drill-down); Flutter map screen scaffold | — |
| 2026-06-28 | Complete Stage 1 DB models + AuditMixin + row_audit_logs; see DATABASE.md | — |

> Add a row here whenever APIs, tables, or algorithms change. See [DOCUMENTATION.md](DOCUMENTATION.md).
