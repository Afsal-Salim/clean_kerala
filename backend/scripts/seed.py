"""Seed awareness quotes and sample feed posts."""

from sqlalchemy import select

from app.core.audit_context import audit_info_for_system, reset_audit_info, set_audit_info
from app.db.session import SessionLocal
from app.models.quote import AwarenessQuote
from app.models.user import User
from app.models.waste_report import WasteCategory, WasteReport, ReportStatus

QUOTES = [
    ("A clean Kerala begins with you.", "Make Kerala Clean"),
    ("Waste in the wrong place is a threat to every place.", "Kerala Pledge"),
    ("Small acts of cleaning create a large wave of change.", None),
    ("Do not pass the trash — pick the future.", "Green Kerala"),
    ("Every ward cleaned is a community healed.", None),
    ("Plastic today, problem tomorrow. Act now.", "Coastal Care Kerala"),
    ("Clean streets reflect a caring society.", "MKC Volunteers"),
    ("Report it. Fix it. Keep Kerala beautiful.", "Make Kerala Clean"),
]

SAMPLE_REPORTS = [
    (
        WasteCategory.plastic,
        "Large pile of plastic bottles and bags near the bus stop. Needs urgent cleanup.",
        "MG Road, near KSRTC stand",
        "Ward 12",
        "Kochi Corporation",
        "Ernakulam",
    ),
    (
        WasteCategory.roadside,
        "Mixed household waste dumped on the roadside after yesterday's rain.",
        "NH 66 service road",
        "Ward 5",
        "Kozhikode Corporation",
        "Kozhikode",
    ),
    (
        WasteCategory.canal,
        "Canal blocked with food waste and plastic — water flow reduced significantly.",
        "Thevara canal bank",
        "Ward 18",
        "Kochi Corporation",
        "Ernakulam",
    ),
    (
        WasteCategory.construction,
        "Construction debris left on public land for over a week.",
        "Technopark Phase 3 approach road",
        "Ward 3",
        "Kazhakoottam Grama Panchayat",
        "Thiruvananthapuram",
    ),
]


def seed_if_empty() -> None:
    token = set_audit_info(audit_info_for_system("system/seed"))
    db = SessionLocal()
    try:
        if not db.scalar(select(AwarenessQuote).limit(1)):
            for text, author in QUOTES:
                db.add(AwarenessQuote(text=text, author=author, is_active=True))

        if not db.scalar(select(WasteReport).limit(1)):
            demo_user = db.scalar(select(User).where(User.email == "demo@makekeralaclean.org"))
            for category, description, address, ward, municipality, district in SAMPLE_REPORTS:
                db.add(
                    WasteReport(
                        user_id=demo_user.id if demo_user else None,
                        category=category,
                        description=description,
                        address=address,
                        ward_name=ward,
                        municipality_name=municipality,
                        district_name=district,
                        status=ReportStatus.pending_ngo,
                        upvote_count=0,
                        comment_count=0,
                    )
                )
        db.commit()
    finally:
        db.close()
        reset_audit_info(token)
