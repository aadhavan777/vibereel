from typing import Annotated, cast
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.dependencies.auth import get_optional_current_user
from app.models.user import User
from app.schemas.search import SearchResponse, TrendingSearchResult
from app.services.search_service import search_service

router = APIRouter(prefix="/search", tags=["Search"])


@router.get("", response_model=SearchResponse)
def search(
    q: Annotated[str, Query(min_length=1, description="Search query string")],
    type: Annotated[str, Query(description="Filter type: all, videos, creators, forum")] = "all",
    page: Annotated[int, Query(ge=1)] = 1,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
    current_user: User | None = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
) -> SearchResponse:
    current_user_id: UUID | None = cast(UUID, current_user.id) if current_user else None
    results = search_service.search(
        db, query_str=q, type_filter=type, page=page, limit=limit, current_user_id=current_user_id
    )
    return SearchResponse(**results)




@router.get("/trending", response_model=list[TrendingSearchResult])
def get_trending_searches(
    db: Session = Depends(get_db),
) -> list[TrendingSearchResult]:
    items = search_service.get_trending_searches(db)
    return [TrendingSearchResult(**item) for item in items]
