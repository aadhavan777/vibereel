from typing import Any, Generic, TypeVar
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.base import BaseModel

ModelType = TypeVar("ModelType", bound=BaseModel)


class BaseRepository(Generic[ModelType]):
    def __init__(self, model: type[ModelType]):
        self.model = model

    def get(self, db: Session, id: UUID) -> ModelType | None:
        return db.query(self.model).filter(self.model.id == id).first()

    def get_multi(self, db: Session, skip: int = 0, limit: int = 100) -> list[ModelType]:
        return db.query(self.model).offset(skip).limit(limit).all()

    def create(self, db: Session, *, obj_in: Any) -> ModelType:
        if isinstance(obj_in, dict):
            db_obj = self.model(**obj_in)
        else:
            db_obj = self.model(**obj_in.model_dump(exclude_unset=True))
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def remove(self, db: Session, *, id: UUID) -> ModelType | None:
        obj = db.query(self.model).get(id)
        if obj:
            db.delete(obj)
            db.commit()
        return obj
