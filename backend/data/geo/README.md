# Geo data sources

| File | Source | Licence | Size |
|------|--------|---------|------|
| `districts/kerala-districts.geojson` | [geohacker/kerala](https://github.com/geohacker/kerala) → `geojsons/district.geojson` | Datameet / community maps | ~282 KB |
| `kerala-state.geojson` | same repo → `geojsons/state.geojson` | same | ~122 KB |
| `registry/districts.json` | Generated from district GeoJSON | — | — |

**Attribution:** © OpenStreetMap contributors (ODbL) where applicable; original admin boundaries from datameet.org/maps via geohacker/kerala.

**Re-download:**

```bash
bash backend/scripts/download_geo.sh
```

**District property key:** `DISTRICT` (e.g. `Alappuzha`, `Thiruvananthapuram`) — 14 features.

**Not included (too large for default checkout):**

- `taluk.geojson` (~580 KB)
- `village.geojson` (~12 MB)
- Ward boundaries → [Vonter/kerala-wards](https://github.com/Vonter/kerala-wards/releases)
- Local bodies → [OpenDataKerala](https://opendatakerala.org/)

See [docs/analytics-map.md](../../../docs/analytics-map.md).
