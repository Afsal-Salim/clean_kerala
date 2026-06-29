import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.quote import AwarenessQuote
from app.schemas.quotes import QuoteListResponse, QuoteResponse

router = APIRouter(prefix="/quotes", tags=["quotes"])


@router.get("", response_model=QuoteListResponse)
def list_quotes(db: Annotated[Session, Depends(get_db)]):
    items = db.scalars(
        select(AwarenessQuote).where(AwarenessQuote.is_active.is_(True)).order_by(AwarenessQuote.created_at)
    ).all()
    quotes = [QuoteResponse.model_validate(q) for q in items]
    featured = quotes[0] if quotes else None
    return QuoteListResponse(items=quotes, featured=featured)


@router.get("/random", response_model=QuoteResponse)
def random_quote(db: Annotated[Session, Depends(get_db)]):
    quote = db.scalar(
        select(AwarenessQuote)
        .where(AwarenessQuote.is_active.is_(True))
        .order_by(func.random())
        .limit(1)
    )
    if not quote:
        return QuoteResponse(
            id=uuid.uuid4(),
            text="Cleanliness is next to godliness — keep Kerala beautiful.",
            author="Make Kerala Clean",
        )
    return QuoteResponse.model_validate(quote)
