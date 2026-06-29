# Map Analytics — Kerala Drill-Down

> **Last updated:** 2026-06-28  
> **Stage:** 1 (public stats) · Stage 2 (official jurisdiction dashboards)

---

## Goal

Users open a **Kerala map** and drill down:

```
Kerala (state)
  └── District (14)
        └── Local body — municipality / corporation / grama panchayat (~1,200)
              └── Ward (~20,950)
```

Each level shows **statistics** for that area: report count, resolved/closed, pending, top categories. Clicking a polygon zooms into the next level.

---

## Is this possible for free?

**Yes.** You do **not** need Google Maps or a paid API for this feature.

| Need | Free option | Cost |
|------|-------------|------|
| Base map tiles | [OpenStreetMap](https://www.openstreetmap.org/) via `flutter_map` | **Free** (fair-use; self-host tiles at scale) |
| Kerala district boundaries | [geohacker/kerala](https://github.com/geohacker/kerala) GeoJSON | **Free** (datameet-derived) |
| Local body boundaries | [OpenDataKerala](https://opendatakerala.org/) / OSM Kerala | **Free** (ODbL licence) |
| Ward boundaries (2024) | [Vonter/kerala-wards](https://github.com/Vonter/kerala-wards) / [wardmap.ksmart.live](https://wardmap.ksmart.live/) | **Free** (Govt of Kerala delimitation data) |
| Stats aggregation | Your FastAPI backend + PostgreSQL | **Your server only** |
| GPU / ML for map | **Not required** | — |

### What to avoid (unless budget allows)

| Service | Why skip for MVP |
|---------|------------------|
| Google Maps Platform | Geocoding + map loads bill per request |
| Mapbox | Free tier (~50k map loads/mo) then paid |
| Custom GPU server for maps | Maps are static GeoJSON + tiles — **no GPU** |

### Recommended stack (MKC)

```
Flutter app
  flutter_map  →  OSM raster tiles (free)
  GeoJSON layers  →  bundled or CDN-hosted boundary files
  Tap polygon  →  GET /api/v1/analytics/...  (counts from DB)

Backend
  PostgreSQL aggregates on waste_reports (district / municipality / ward text fields)
  Optional later: PostGIS for point-in-polygon if GPS used instead of typed names
```

---

## Data sources (download once, ship with app or API)

1. **Districts (14)** — `github.com/geohacker/kerala` → `districts.geojson`
2. **Local bodies** — OpenDataKerala LSGI boundary release (corporations, municipalities, grama panchayats)
3. **Wards** — `github.com/Vonter/kerala-wards` releases (2024 delimitation, ~20k wards)

Store under `backend/data/geo/` (or CDN). **Do not commit multi-GB files to git** — use release download script + `.gitignore`.

Licence: respect **ODbL** (OpenStreetMap / OpenDataKerala) — attribute OSM © contributors on the map screen.

---

## Drill-down UX

| Level | Map shows | Side panel |
|-------|-----------|------------|
| **State** | 14 district polygons, colour = report density | Kerala totals, tap district |
| **District** | Local body polygons in that district | District stats, list of bodies |
| **Local body** | Ward polygons | Body stats, ward list |
| **Ward** | Ward outline highlighted | Ward stats, link to feed filtered by ward |

**Interaction:** tap polygon → animate zoom to bounds → load child GeoJSON + stats API.

**Fallback without geometry:** list + bar chart by district/municipality/ward (works before GeoJSON is imported).

---

## Backend APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/analytics/summary` | Kerala-wide totals |
| GET | `/api/v1/analytics/districts` | All districts with counts |
| GET | `/api/v1/analytics/districts/{slug}` | One district + local body breakdown |
| GET | `/api/v1/analytics/local-bodies/{slug}` | One body + ward breakdown |
| GET | `/api/v1/analytics/wards/{slug}` | One ward detail |
| GET | `/api/v1/geo/{level}/{slug}.geojson` | Boundary file (optional static serve) |

Stats are computed from `waste_reports` grouped by normalized `district_name`, `municipality_name`, `ward_name`.

---

## Name matching problem

Reports use **free-text** location fields. GeoJSON uses **official names**. Mitigation:

1. **Canonical registry** — JSON catalog with `slug`, `name_en`, `name_ml`, aliases
2. **Normalize** — lowercase, trim, collapse spaces before join
3. **Stage 2** — dropdown picker from registry instead of free text (best fix)
4. **Optional PostGIS** — classify report by GPS point inside ward polygon

---

## AI / waste model — no GPU required

| Approach | Runs on | Cost |
|----------|---------|------|
| **ML Kit (current MVP)** | User's phone | Free |
| **Small ONNX model on CPU** | Your API server (2 vCPU) | ~₹500–2000/mo VPS, **no GPU** |
| **Custom GPU inference** | Only if volume is huge (1000s/min) | Expensive — defer |

**Recommendation:** keep verification **on-device** for Stage 1–2. Add optional **CPU** server re-check with a quantized model only if abuse is high. Skip GPU until scale demands it.

---

## Completion photos

Same rules as report photos: **in-app camera only**, ML Kit waste check, server metadata validation. See [DECISIONS.md](DECISIONS.md).

---

## Implementation phases

| Phase | Deliverable |
|-------|-------------|
| **1a** | Stats API (district / municipality / ward lists) — **implemented** |
| **1b** | Flutter stats screen (list + charts, no map yet) |
| **1c** | Import district GeoJSON + `flutter_map` choropleth |
| **1d** | Local body + ward GeoJSON drill-down |
| **2** | Location picker from registry; PostGIS point-in-polygon |

---

## Change log

| Date | Change |
|------|--------|
| 2026-06-28 | Initial map analytics architecture; free data sources documented |
