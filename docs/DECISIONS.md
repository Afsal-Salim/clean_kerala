# Make Kerala Clean — Locked Decisions

> **Last updated:** 2026-06-28
> Update this file when product or technical defaults change. See [DOCUMENTATION.md](DOCUMENTATION.md).

---

## Feed algorithm

| Mix | Share | Match rule |
|-----|-------|------------|
| Near | **60%** | Same ward, or within ~8 km (GPS) |
| Surrounding | **30%** | Same municipality/district (different ward), or ~8–40 km |
| All Kerala | **10%** | Rest of the state |

- **Newest posts first** within each tier, then blended in a 6:3:1 pattern per 10 slots.
- Without user/guest location: **100% Kerala**, newest first (chronological).
- Location source: **profile settings** (logged in) or **guest area picker** (stored locally).

---

| Rule | Value |
|------|-------|
| Max photos per report | **3** |
| Rate limit | **5 reports per user per day** (rolling 24h or calendar day — use UTC calendar day for MVP) |

When limits are exceeded:

- More than 3 images on create → `400` with code `MAX_PHOTOS_EXCEEDED`
- 6th report in a day → `429` with code `REPORT_RATE_LIMIT_EXCEEDED`

---

## NGO accept vs reject — report status

**Only NGO accept changes report status. Reject does not.**

| Action | Report `status` | Other effects |
|--------|-----------------|---------------|
| **Accept** | `pending_ngo` → `accepted` | Create `issue` (status `open`); notify citizen |
| **Reject** | **No change** — stays `pending_ngo` | Insert `ngo_responses` row (`action: reject`, reason); other NGOs can still accept |

Reject is recorded in `ngo_responses` only. The report remains on the feed and in `pending_ngo` until an NGO accepts or the report expires (future rule).

### Accept concurrency

- First NGO to accept wins (`SELECT FOR UPDATE` on report while `status = pending_ngo`)
- After accept, report is no longer available for other NGOs

### Reject behaviour

- Rejecting NGO is excluded from re-notification for that report
- Report status is **never** set to `rejected`
- Citizen is **not** notified on a single reject (optional: notify only if all nearby NGOs reject — deferred)

---

## Report status enum (canonical)

```
posted → pending_ngo → accepted → resolved → closed
                              ↑
                    (only via NGO accept)

expired   ← optional future: no accept within TTL
```

There is **no** `rejected` report status.

Issue status (separate entity, created on accept):

```
open → in_progress → resolved → closed
```

---

## Other MVP defaults (recommended, not yet coded)

| Topic | Default |
|-------|---------|
| NGO onboarding | Admin approval before accept capability |
| Report expiry | 7 days in `pending_ngo` → `expired` (future) |
| Citizen confirm timeout | Auto-close 3 days after NGO marks resolved (future) |
| Auth | Email + password for MVP |
| Dev media storage | Local filesystem; S3 in production |

---

## Report photos — camera-only + waste verification

Reports must use **live in-app camera** photos. Gallery uploads are rejected.

### Three layers (defense in depth)

| Layer | Where | What it does |
|-------|--------|--------------|
| **1. Camera-only UI** | Flutter | Only `ImageSource.camera`; no gallery picker |
| **2. On-device waste check** | Flutter (ML Kit) | Labels image for waste-related objects before upload; min confidence **0.35** |
| **3. Server validation** | FastAPI | Requires `image_metadata` JSON per photo: `source=camera`, fresh `captured_at` (≤ **15 min**), `waste_confidence` ≥ threshold; basic image size/resolution checks |

### POST `/api/v1/reports` — extra form field

`image_metadata` — JSON array, one object per image (same order as `images` files):

```json
[
  {
    "captured_at": "2026-06-28T10:00:00Z",
    "source": "camera",
    "latitude": 10.015,
    "longitude": 76.341,
    "waste_confidence": 0.62,
    "waste_labels": ["Plastic:0.71", "Package:0.45"]
  }
]
```

### Error codes

| Code | Meaning |
|------|---------|
| `GALLERY_NOT_ALLOWED` | `source` is not `camera` |
| `WASTE_NOT_DETECTED` | `waste_confidence` below threshold |
| `STALE_CAPTURE` | Photo older than 15 minutes |
| `IMAGE_METADATA_REQUIRED` | Missing metadata |
| `IMAGE_METADATA_COUNT_MISMATCH` | Metadata count ≠ image count |

### Env / config (backend)

| Setting | Default |
|---------|---------|
| `capture_max_age_seconds` | 900 |
| `waste_verification_enabled` | true |
| `waste_verification_min_confidence` | 0.35 |
| `min_image_width` / `min_image_height` | 200 |

Set `waste_verification_enabled=false` only for local dev without ML Kit.

### Completion photos (issue resolve)

When an NGO marks an issue resolved, **completion photos use the same rules** as report photos:

- In-app **camera only** (no gallery)
- ML Kit waste / cleanup scene check on device
- Same `image_metadata` validation on `POST /api/v1/issues/{id}/complete`

### AI inference cost (no GPU required)

| Tier | Where | Cost |
|------|-------|------|
| **MVP (now)** | ML Kit on user's phone | **Free** |
| **Optional server re-check** | Small ONNX model on **CPU** (2 vCPU VPS) | ~₹500–2000/mo, **no GPU** |
| **GPU inference** | Only at very high volume | Defer until needed |

Do **not** block Stage 1 on a custom GPU-hosted model. NGOs remain the human backstop for fakes.

### Future (Stage 3)

- Server-side waste classification model (not just client scores)
- Duplicate image detection (same location + perceptual hash)
- Watermark (date, GPS) burned into image
- NGO/govt can still reject fakes that pass automated checks

---

## Change log

| Date | Decision |
|------|----------|
| 2026-06-28 | Feed mix 60/30/10 by location; profile + guest location; location on images |
| 2026-06-28 | Max 3 photos/report; 5 reports/day; reject does not change report status |
| 2026-06-28 | Camera-only photos; ML Kit waste pre-check; server capture metadata validation |
| 2026-06-28 | Completion photos camera-only; AI on-device first (no GPU); map analytics via free OSM + GeoJSON |
| 2026-06-28 | All tables use AuditMixin + row_audit_logs; full schema in DATABASE.md |
