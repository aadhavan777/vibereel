from typing import cast
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.moderation import ContentReport, UserBlock
from app.models.user import User
from app.schemas.moderation import ContentReportCreate, ContentReportResponse


class ModerationService:
    def create_report(
        self, db: Session, reporter: User, report_in: ContentReportCreate
    ) -> ContentReportResponse:
        valid_types = {"video", "forum_post", "forum_comment", "video_comment"}
        if report_in.entity_type.lower() not in valid_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid entity_type. Must be one of: {', '.join(valid_types)}",
            )

        report = ContentReport(
            reporter_id=reporter.id,
            entity_type=report_in.entity_type.lower(),
            entity_id=report_in.entity_id,
            reason=report_in.reason,
            details=report_in.details,
            status="pending",
        )
        db.add(report)
        db.commit()
        db.refresh(report)

        return ContentReportResponse(
            id=cast(UUID, report.id),
            reporter_id=cast(UUID, report.reporter_id),
            entity_type=cast(str, report.entity_type),
            entity_id=cast(UUID, report.entity_id),
            reason=cast(str, report.reason),
            details=cast(str | None, report.details),
            status=cast(str, report.status),
            created_at=report.created_at,
        )

    def block_user(self, db: Session, blocker: User, target_user_id: UUID) -> bool:
        if blocker.id == target_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot block yourself",
            )

        target = db.scalar(select(User).where(User.id == target_user_id))
        if not target:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        existing = db.scalar(
            select(UserBlock).where(
                UserBlock.blocker_id == blocker.id,
                UserBlock.blocked_id == target_user_id,
            )
        )
        if not existing:
            block = UserBlock(blocker_id=blocker.id, blocked_id=target_user_id)
            db.add(block)
            db.commit()

        return True

    def unblock_user(self, db: Session, blocker: User, target_user_id: UUID) -> bool:
        existing = db.scalar(
            select(UserBlock).where(
                UserBlock.blocker_id == blocker.id,
                UserBlock.blocked_id == target_user_id,
            )
        )
        if existing:
            db.delete(existing)
            db.commit()

        return True

    def get_blocked_user_ids(self, db: Session, user_id: UUID | None) -> list[UUID]:
        if not user_id:
            return []
        blocks = db.scalars(
            select(UserBlock.blocked_id).where(UserBlock.blocker_id == user_id)
        ).all()
        return [cast(UUID, b) for b in blocks]


moderation_service = ModerationService()
