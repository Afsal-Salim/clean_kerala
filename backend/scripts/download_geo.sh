#!/usr/bin/env bash
# Download Kerala admin boundary GeoJSON from geohacker/kerala (datameet-derived, free).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)/data/geo"
BASE="https://raw.githubusercontent.com/geohacker/kerala/master/geojsons"

mkdir -p "$ROOT/districts"

echo "Downloading district boundaries..."
curl -fsSL -o "$ROOT/districts/kerala-districts.geojson" "$BASE/district.geojson"

echo "Downloading state boundary..."
curl -fsSL -o "$ROOT/kerala-state.geojson" "$BASE/state.geojson"

echo "Done."
echo "  $ROOT/districts/kerala-districts.geojson ($(du -h "$ROOT/districts/kerala-districts.geojson" | cut -f1))"
echo "  $ROOT/kerala-state.geojson ($(du -h "$ROOT/kerala-state.geojson" | cut -f1))"
echo ""
echo "Optional (large, not downloaded by default):"
echo "  taluk.geojson   ~580 KB"
echo "  village.geojson ~12 MB"
