from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class QuoteResponse(BaseModel):
    id: UUID
    text: str
    author: str | None

    model_config = {"from_attributes": True}


class QuoteListResponse(BaseModel):
    items: list[QuoteResponse]
    featured: QuoteResponse | None = None
