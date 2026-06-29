"""Aggregate waste report statistics by geography."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.waste_report import ReportStatus, WasteReport


def _normalize(column):
    return func.lower(func.trim(column))


def _stats_select(group_col):
    return select(
        group_col.label("name"),
        func.count().label("total_reports"),
        func.count().filter(WasteReport.status == ReportStatus.pending_ngo).label("pending"),
        func.count().filter(WasteReport.status == ReportStatus.accepted).label("accepted"),
        func.count().filter(WasteReport.status == ReportStatus.resolved).label("resolved"),
        func.count().filter(WasteReport.status == ReportStatus.closed).label("closed"),
    ).group_by(group_col)


def kerala_summary(db: Session) -> dict:
    row = db.execute(
        select(
            func.count().label("total_reports"),
            func.count().filter(WasteReport.status == ReportStatus.pending_ngo).label("pending"),
            func.count().filter(WasteReport.status == ReportStatus.closed).label("closed"),
        )
    ).one()
    return {
        "level": "state",
        "name": "Kerala",
        "slug": "kerala",
        "total_reports": row.total_reports or 0,
        "pending": row.pending or 0,
        "closed": row.closed or 0,
    }


def district_stats(db: Session) -> list[dict]:
    col = _normalize(WasteReport.district_name)
    rows = db.execute(
        _stats_select(col).where(WasteReport.district_name.isnot(None), WasteReport.district_name != "")
    ).all()
    return [_row_to_stats("district", r) for r in rows if r.name]


def _slugify(name: str) -> str:
    return name.strip().lower().replace(" ", "-")


def _slug_to_name(slug: str) -> str:
    return slug.strip().lower().replace("-", " ")


def district_detail(db: Session, district_slug: str) -> dict | None:
    slug_name = _slug_to_name(district_slug)
    col = _normalize(WasteReport.district_name)
    summary = db.execute(
        select(
            func.max(WasteReport.district_name).label("display_name"),
            func.count().label("total_reports"),
            func.count().filter(WasteReport.status == ReportStatus.pending_ngo).label("pending"),
            func.count().filter(WasteReport.status == ReportStatus.closed).label("closed"),
        ).where(col == slug_name)
    ).one()
    if not summary.total_reports:
        return None

    muni_col = _normalize(WasteReport.municipality_name)
    bodies = db.execute(
        _stats_select(muni_col).where(col == slug_name, WasteReport.municipality_name.isnot(None))
    ).all()

    return {
        "level": "district",
        "name": summary.display_name or district_slug,
        "slug": _slugify(summary.display_name or district_slug),
        "total_reports": summary.total_reports or 0,
        "pending": summary.pending or 0,
        "closed": summary.closed or 0,
        "local_bodies": [_row_to_stats("local_body", r) for r in bodies if r.name],
    }


def local_body_detail(db: Session, body_slug: str) -> dict | None:
    slug_name = _slug_to_name(body_slug)
    muni_col = _normalize(WasteReport.municipality_name)
    summary = db.execute(
        select(
            func.max(WasteReport.municipality_name).label("display_name"),
            func.max(WasteReport.district_name).label("district_name"),
            func.count().label("total_reports"),
            func.count().filter(WasteReport.status == ReportStatus.pending_ngo).label("pending"),
            func.count().filter(WasteReport.status == ReportStatus.closed).label("closed"),
        ).where(muni_col == slug_name)
    ).one()
    if not summary.total_reports:
        return None

    ward_col = _normalize(WasteReport.ward_name)
    wards = db.execute(
        _stats_select(ward_col).where(muni_col == slug_name, WasteReport.ward_name.isnot(None))
    ).all()

    return {
        "level": "local_body",
        "name": summary.display_name or body_slug,
        "slug": _slugify(summary.display_name or body_slug),
        "district_name": summary.district_name,
        "total_reports": summary.total_reports or 0,
        "pending": summary.pending or 0,
        "closed": summary.closed or 0,
        "wards": [_row_to_stats("ward", r) for r in wards if r.name],
    }


def ward_detail(db: Session, ward_slug: str) -> dict | None:
    slug_name = _slug_to_name(ward_slug)
    ward_col = _normalize(WasteReport.ward_name)
    row = db.execute(
        select(
            func.max(WasteReport.ward_name).label("display_name"),
            func.max(WasteReport.municipality_name).label("municipality_name"),
            func.max(WasteReport.district_name).label("district_name"),
            func.count().label("total_reports"),
            func.count().filter(WasteReport.status == ReportStatus.pending_ngo).label("pending"),
            func.count().filter(WasteReport.status == ReportStatus.closed).label("closed"),
        ).where(ward_col == slug_name)
    ).one()
    if not row.total_reports:
        return None

    return {
        "level": "ward",
        "name": row.display_name or ward_slug,
        "slug": _slugify(row.display_name or ward_slug),
        "municipality_name": row.municipality_name,
        "district_name": row.district_name,
        "total_reports": row.total_reports or 0,
        "pending": row.pending or 0,
        "closed": row.closed or 0,
    }


def _row_to_stats(level: str, row) -> dict:
    name = row.name
    display = name.title() if name else ""
    return {
        "level": level,
        "name": display,
        "slug": _slugify(name) if name else "",
        "total_reports": row.total_reports or 0,
        "pending": row.pending or 0,
        "accepted": row.accepted or 0,
        "resolved": row.resolved or 0,
        "closed": row.closed or 0,
    }
