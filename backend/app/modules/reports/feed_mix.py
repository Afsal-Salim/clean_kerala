import enum
import math
from dataclasses import dataclass

from app.models.user import User
from app.models.waste_report import WasteReport

NEAR_RADIUS_KM = 8.0
SURROUNDING_RADIUS_KM = 40.0

FEED_NEAR_RATIO = 0.60
FEED_SURROUNDING_RATIO = 0.30
FEED_KERALA_RATIO = 0.10


class LocationTier(str, enum.Enum):
    near = "near"
    surrounding = "surrounding"
    kerala = "kerala"


@dataclass
class UserLocation:
    latitude: float | None = None
    longitude: float | None = None
    ward: str | None = None
    municipality: str | None = None
    district: str | None = None

    @property
    def is_set(self) -> bool:
        return any([self.latitude, self.longitude, self.ward, self.municipality, self.district])

    @classmethod
    def from_user(cls, user: User | None) -> "UserLocation | None":
        if not user:
            return None
        loc = cls(
            latitude=user.home_latitude,
            longitude=user.home_longitude,
            ward=_norm(user.home_ward),
            municipality=_norm(user.home_municipality),
            district=_norm(user.home_district),
        )
        return loc if loc.is_set else None


def _norm(value: str | None) -> str | None:
    if not value:
        return None
    return value.strip().lower()


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlon / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def classify_report(report: WasteReport, loc: UserLocation) -> LocationTier:
    # GPS-based when both sides have coordinates
    if (
        loc.latitude is not None
        and loc.longitude is not None
        and report.latitude is not None
        and report.longitude is not None
    ):
        km = haversine_km(loc.latitude, loc.longitude, report.latitude, report.longitude)
        if km <= NEAR_RADIUS_KM:
            return LocationTier.near
        if km <= SURROUNDING_RADIUS_KM:
            return LocationTier.surrounding
        return LocationTier.kerala

    r_ward = _norm(report.ward_name)
    r_muni = _norm(report.municipality_name)
    r_dist = _norm(report.district_name)

    if loc.ward and r_ward and loc.ward == r_ward:
        return LocationTier.near

    if loc.municipality and r_muni and loc.municipality == r_muni:
        if loc.ward and r_ward and loc.ward != r_ward:
            return LocationTier.surrounding
        if not loc.ward:
            return LocationTier.near

    if loc.district and r_dist and loc.district == r_dist:
        if loc.municipality and r_muni and loc.municipality != r_muni:
            return LocationTier.surrounding
        if loc.municipality and r_muni and loc.municipality == r_muni:
            return LocationTier.surrounding
        if not loc.municipality:
            return LocationTier.surrounding

    return LocationTier.kerala


def _sort_key(report: WasteReport) -> float:
    return report.created_at.timestamp()


def merge_location_feed(
    reports: list[WasteReport],
    loc: UserLocation | None,
    *,
    limit: int,
    offset: int,
) -> tuple[list[tuple[WasteReport, LocationTier]], dict]:
    """Blend feed: 60% near · 30% surrounding · 10% all Kerala. Newest first within each tier."""

    if not loc or not loc.is_set:
        chronological = sorted(reports, key=_sort_key, reverse=True)
        page = chronological[offset : offset + limit]
        return [(r, LocationTier.kerala) for r in page], {
            "mode": "chronological",
            "location_based": False,
            "near_pct": 0,
            "surrounding_pct": 0,
            "kerala_pct": 100,
        }

    buckets: dict[LocationTier, list[WasteReport]] = {
        LocationTier.near: [],
        LocationTier.surrounding: [],
        LocationTier.kerala: [],
    }
    for report in reports:
        buckets[classify_report(report, loc)].append(report)

    for tier in buckets:
        buckets[tier].sort(key=_sort_key, reverse=True)

    pattern = (
        [LocationTier.near] * 6
        + [LocationTier.surrounding] * 3
        + [LocationTier.kerala] * 1
    )
    indices = {LocationTier.near: 0, LocationTier.surrounding: 0, LocationTier.kerala: 0}
    merged: list[tuple[WasteReport, LocationTier]] = []
    seen_ids: set = set()
    max_iterations = len(reports) * 2 + 10
    iteration = 0

    while len(merged) < offset + limit and iteration < max_iterations:
        iteration += 1
        added = False
        for tier in pattern:
            if len(merged) >= offset + limit:
                break
            pool = buckets[tier]
            idx = indices[tier]
            while idx < len(pool):
                report = pool[idx]
                idx += 1
                if report.id in seen_ids:
                    continue
                seen_ids.add(report.id)
                merged.append((report, tier))
                added = True
                break
            indices[tier] = idx

        if not added:
            for tier in (LocationTier.near, LocationTier.surrounding, LocationTier.kerala):
                pool = buckets[tier]
                idx = indices[tier]
                while idx < len(pool):
                    report = pool[idx]
                    idx += 1
                    if report.id in seen_ids:
                        continue
                    seen_ids.add(report.id)
                    merged.append((report, tier))
                    added = True
                    break
                indices[tier] = idx
                if added:
                    break
        if not added:
            break

    page_items = merged[offset : offset + limit]
    return page_items, {
        "mode": "location_mix",
        "location_based": True,
        "near_pct": int(FEED_NEAR_RATIO * 100),
        "surrounding_pct": int(FEED_SURROUNDING_RATIO * 100),
        "kerala_pct": int(FEED_KERALA_RATIO * 100),
    }
