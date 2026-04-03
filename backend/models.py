from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Boolean,
    DateTime,
    ForeignKey,
    Enum,
    Numeric,
)
from sqlalchemy.orm import relationship
import enum

from database import Base


class ContentItemType(enum.Enum):
    article = "article"
    news = "news"
    course = "course"
    event = "event"
    publication = "publication"


class ContentStatus(enum.Enum):
    draft = "draft"
    in_review = "in_review"
    published = "published"
    archived = "archived"


class PriceTypeEnum(enum.Enum):
    free = "free"
    paid = "paid"
    subscription = "subscription"


class AccreditationStatusEnum(enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    expired = "expired"


class CourseStatusEnum(enum.Enum):
    draft = "draft"
    published = "published"
    archived = "archived"
    closed = "closed"


class AttendanceMode(enum.Enum):
    onsite = "onsite"
    online = "online"
    hybrid = "hybrid"


class ContentCategory(Base):
    __tablename__ = "content_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)


class Specialization(Base):
    __tablename__ = "specializations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)


class ContentItem(Base):
    __tablename__ = "content_items"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)
    content_type = Column(Enum(ContentItemType), nullable=False)
    status = Column(Enum(ContentStatus), nullable=False, default=ContentStatus.draft)
    short_description = Column(Text)
    body = Column(Text)
    category_id = Column(Integer, ForeignKey("content_categories.id"))
    specialization_id = Column(Integer, ForeignKey("specializations.id"))
    hero_image_url = Column(Text)
    thumbnail_url = Column(Text)
    published_at = Column(DateTime(timezone=True))
    author_name = Column(String(255))
    source_url = Column(Text)
    seo_title = Column(String(255))
    seo_description = Column(String(500))
    canonical_url = Column(Text)
    is_featured = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)
    created_by_user_id = Column(Integer)
    updated_by_user_id = Column(Integer)
    published_by_user_id = Column(Integer)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))
    deleted_at = Column(DateTime(timezone=True))

    category = relationship("ContentCategory", backref="content_items")
    specialization = relationship("Specialization", backref="content_items")
    event = relationship("Event", uselist=False, back_populates="content_item")
    course = relationship("Course", uselist=False, back_populates="content_item")
    publication = relationship("Publication", uselist=False, back_populates="content_item")


class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id"), unique=True, nullable=False)
    city_id = Column(Integer)
    venue_name = Column(String(255))
    attendance_mode = Column(Enum(AttendanceMode), nullable=False, default=AttendanceMode.onsite)
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True), nullable=False)
    price_type = Column(Enum(PriceTypeEnum), nullable=False)
    price_amount = Column(Numeric(10, 2))
    emc_credits = Column(Integer)
    accreditation_status = Column(Enum(AccreditationStatusEnum))
    event_page_url = Column(Text)
    registration_url = Column(Text)

    content_item = relationship("ContentItem", back_populates="event")


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id"), unique=True, nullable=False)
    emc_credits = Column(Integer)
    valid_from = Column(DateTime(timezone=True))
    valid_until = Column(DateTime(timezone=True))
    enrollment_url = Column(Text)
    provider = Column(String(255))
    course_status = Column(Enum(CourseStatusEnum), nullable=False, default=CourseStatusEnum.draft)

    content_item = relationship("ContentItem", back_populates="course")


class Publication(Base):
    __tablename__ = "publications"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id"), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    logo_url = Column(Text)
    description = Column(Text)
    emc_credits_text = Column(Text)
    creditation_text = Column(Text)
    indexing_text = Column(Text)
    subscription_url = Column(Text)

    content_item = relationship("ContentItem", back_populates="publication")