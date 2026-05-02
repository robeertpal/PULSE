from sqlalchemy import (
    BigInteger,
    Column,
    Integer,
    String,
    Text,
    Boolean,
    DateTime,
    ForeignKey,
    Enum,
    Numeric,
    JSON,
)
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import ENUM as PGEnum, JSONB
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


class UserCourseStatus(enum.Enum):
    enrolled = "enrolled"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class RegistrationStatus(enum.Enum):
    registered = "registered"
    confirmed = "confirmed"
    attended = "attended"
    cancelled = "cancelled"
    no_show = "no_show"


class SubscriptionStatus(enum.Enum):
    pending = "pending"
    active = "active"
    expired = "expired"
    cancelled = "cancelled"
    suspended = "suspended"


class PaymentStatus(enum.Enum):
    pending = "pending"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"
    cancelled = "cancelled"


class LessonContentType(enum.Enum):
    video = "video"
    article = "article"
    quiz = "quiz"
    pdf = "pdf"
    external_link = "external_link"


class AdType(enum.Enum):
    publication = "publication"
    event = "event"
    course = "course"
    article = "article"
    news = "news"
    other = "other"


class AdStatus(enum.Enum):
    draft = "draft"
    active = "active"
    paused = "paused"
    archived = "archived"


class AdPlacement(enum.Enum):
    home_top = "home_top"
    home_between_sections = "home_between_sections"
    home_after_news = "home_after_news"
    home_after_publications = "home_after_publications"
    home_after_events = "home_after_events"
    home_after_courses = "home_after_courses"
    news_feed = "news_feed"
    publications_feed = "publications_feed"
    events_feed = "events_feed"
    courses_feed = "courses_feed"
    article_detail = "article_detail"
    publication_detail = "publication_detail"
    event_detail = "event_detail"
    course_detail = "course_detail"


class County(Base):
    __tablename__ = "counties"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)


class City(Base):
    __tablename__ = "cities"

    id = Column(Integer, primary_key=True, index=True)
    county_id = Column(Integer, ForeignKey("counties.id"), nullable=False)
    name = Column(String(255), nullable=False)

    county = relationship("County", backref="cities")


class Occupation(Base):
    __tablename__ = "occupations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)


class ContentCategory(Base):
    __tablename__ = "content_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)


class Specialization(Base):
    __tablename__ = "specializations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)


class Interest(Base):
    __tablename__ = "interests"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)
    slug = Column(String(255), unique=True)


class ProfessionalGrade(Base):
    __tablename__ = "professional_grades"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)


class Institution(Base):
    __tablename__ = "institutions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id"), nullable=False)
    address = Column(Text)
    type = Column(String(100))

    city = relationship("City", backref="institutions")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    email_verified_at = Column(DateTime(timezone=True))
    last_login_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))
    deleted_at = Column(DateTime(timezone=True))


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    cnp = Column(String(13))
    phone = Column(String(50))
    correspondence_address = Column(Text)
    city_id = Column(Integer, ForeignKey("cities.id"), nullable=False)
    occupation_id = Column(Integer, ForeignKey("occupations.id"), nullable=False)
    specialization_id = Column(Integer, ForeignKey("specializations.id"))
    professional_grade_id = Column(Integer, ForeignKey("professional_grades.id"))
    institution_id = Column(Integer, ForeignKey("institutions.id"))
    total_emc_points = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    user = relationship("User", backref="profile")
    city = relationship("City")
    occupation = relationship("Occupation")
    specialization = relationship("Specialization")
    professional_grade = relationship("ProfessionalGrade")
    institution = relationship("Institution")


class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)


class UserRole(Base):
    __tablename__ = "user_roles"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    role_id = Column(Integer, ForeignKey("roles.id"), primary_key=True)


class UserEmailVerification(Base):
    __tablename__ = "user_email_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_hash = Column(String(255), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    verified_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True))


class UserPasswordReset(Base):
    __tablename__ = "user_password_resets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_hash = Column(String(255), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True))


class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    refresh_token_hash = Column(String(255), nullable=False)
    ip_address = Column(String)
    user_agent = Column(Text)
    created_at = Column(DateTime(timezone=True))
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True))


class Person(Base):
    __tablename__ = "persons"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    title = Column(String(255))
    bio = Column(Text)
    photo_url = Column(Text)
    institution_id = Column(Integer, ForeignKey("institutions.id"))
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    institution = relationship("Institution")


class ContentItem(Base):
    __tablename__ = "content_items"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)
    content_type = Column(Enum(ContentItemType, name="content_item_type"), nullable=False)
    status = Column(Enum(ContentStatus, name="content_status"), nullable=False, default=ContentStatus.draft)
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
    event = relationship(
        "Event",
        uselist=False,
        back_populates="content_item",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    course = relationship(
        "Course",
        uselist=False,
        back_populates="content_item",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    publication = relationship(
        "Publication",
        uselist=False,
        back_populates="content_item",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id"))
    venue_name = Column(String(255))
    attendance_mode = Column(Enum(AttendanceMode, name="attendance_mode"), nullable=False, default=AttendanceMode.onsite)
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True), nullable=False)
    price_type = Column(Enum(PriceTypeEnum, name="price_type_enum"), nullable=False)
    price_amount = Column(Numeric(10, 2))
    emc_credits = Column(Integer)
    accreditation_status = Column(Enum(AccreditationStatusEnum, name="accreditation_status_enum"))
    event_page_url = Column(Text)
    registration_url = Column(Text)

    content_item = relationship("ContentItem", back_populates="event")
    city = relationship("City")


class EventSession(Base):
    __tablename__ = "event_sessions"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(Text)
    starts_at = Column(DateTime(timezone=True), nullable=False)
    ends_at = Column(DateTime(timezone=True), nullable=False)
    room_name = Column(String(255))

    event = relationship("Event", backref="sessions")


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    emc_credits = Column(Integer)
    valid_from = Column(DateTime(timezone=True))
    valid_until = Column(DateTime(timezone=True))
    enrollment_url = Column(Text)
    provider = Column(String(255))
    course_status = Column(Enum(CourseStatusEnum, name="course_status_enum"), nullable=False, default=CourseStatusEnum.draft)

    content_item = relationship("ContentItem", back_populates="course")


class CourseModule(Base):
    __tablename__ = "course_modules"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    display_order = Column(Integer, nullable=False)

    course = relationship("Course", backref="modules")


class CourseLesson(Base):
    __tablename__ = "course_lessons"

    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("course_modules.id"), nullable=False)
    title = Column(String(255), nullable=False)
    content_type = Column(Enum(LessonContentType, name="lesson_content_type"), nullable=False)
    content_url = Column(Text)
    body = Column(Text)
    duration_minutes = Column(Integer)
    display_order = Column(Integer, nullable=False)

    module = relationship("CourseModule", backref="lessons")


class Publication(Base):
    __tablename__ = "publications"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    logo_url = Column(Text)
    description = Column(Text)
    emc_credits_text = Column(Text)
    creditation_text = Column(Text)
    indexing_text = Column(Text)
    subscription_url = Column(Text)

    content_item = relationship("ContentItem", back_populates="publication")


class PublicationIssue(Base):
    __tablename__ = "publication_issues"

    id = Column(Integer, primary_key=True, index=True)
    publication_id = Column(Integer, ForeignKey("publications.id"), nullable=False)
    year = Column(Integer, nullable=False)
    issue_number = Column(Integer, nullable=False)
    issue_label = Column(String(100))
    cover_image_url = Column(Text)
    description = Column(Text)
    published_at = Column(DateTime(timezone=True))

    publication = relationship("Publication", backref="issues")


class ContentItemRevision(Base):
    __tablename__ = "content_item_revisions"

    id = Column(Integer, primary_key=True, index=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id"), nullable=False)
    title = Column(String(255), nullable=False)
    short_description = Column(Text)
    body = Column(Text)
    created_by_user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True))


class SavedContent(Base):
    __tablename__ = "saved_content"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_item_id = Column(Integer, ForeignKey("content_items.id"), nullable=False)
    saved_at = Column(DateTime(timezone=True))


class UserCourse(Base):
    __tablename__ = "user_courses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    progress_percent = Column(Integer, nullable=False, default=0)
    enrolled_at = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    status = Column(Enum(UserCourseStatus, name="user_course_status"), nullable=False)


class UserEventRegistration(Base):
    __tablename__ = "user_event_registrations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    registered_at = Column(DateTime(timezone=True))
    status = Column(Enum(RegistrationStatus, name="registration_status"), nullable=False)


class UserActivityLog(Base):
    __tablename__ = "user_activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action_type = Column(String(100), nullable=False)
    content_item_id = Column(Integer, ForeignKey("content_items.id"))
    metadata_json = Column("metadata", JSON)
    created_at = Column(DateTime(timezone=True))


class EmcCreditRule(Base):
    __tablename__ = "emc_credit_rules"

    id = Column(Integer, primary_key=True, index=True)
    source_type = Column(String(50), nullable=False)
    source_id = Column(Integer, nullable=False)
    points = Column(Integer, nullable=False)
    max_awards_per_user = Column(Integer, nullable=False, default=1)
    valid_from = Column(DateTime(timezone=True))
    valid_until = Column(DateTime(timezone=True))


class UserEmcPointLog(Base):
    __tablename__ = "user_emc_point_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    source_type = Column(String(100), nullable=False)
    source_id = Column(Integer, nullable=False)
    points = Column(Integer, nullable=False)
    awarded_at = Column(DateTime(timezone=True))


class UserEmcCertificate(Base):
    __tablename__ = "user_emc_certificates"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    source_type = Column(String(50), nullable=False)
    source_id = Column(Integer, nullable=False)
    certificate_number = Column(String(100), unique=True)
    issued_at = Column(DateTime(timezone=True))
    certificate_url = Column(Text)


class SubscriptionPlan(Base):
    __tablename__ = "subscription_plans"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False, unique=True)
    price = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(10), nullable=False, default="RON")
    billing_period = Column(String(20), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))


class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    subscription_plan_id = Column(Integer, ForeignKey("subscription_plans.id"), nullable=False)
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True))
    status = Column(Enum(SubscriptionStatus, name="subscription_status"), nullable=False)
    auto_renew = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True))


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    subscription_id = Column(Integer, ForeignKey("user_subscriptions.id"))
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(10), nullable=False, default="RON")
    provider = Column(String(100))
    provider_transaction_id = Column(String(255))
    status = Column(Enum(PaymentStatus, name="payment_status"), nullable=False)
    paid_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True))


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(BigInteger, primary_key=True, index=True)
    actor_user_id = Column(Integer, ForeignKey("users.id"))
    entity_type = Column(String(100), nullable=False)
    entity_id = Column(Integer, nullable=False)
    action = Column(String(50), nullable=False)
    old_data = Column(JSON)
    new_data = Column(JSON)
    created_at = Column(DateTime(timezone=True))


class EventGallery(Base):
    __tablename__ = "event_gallery"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    image_url = Column(Text, nullable=False)
    display_order = Column(Integer, nullable=False, default=0)


class AdDesignTemplate(Base):
    __tablename__ = "ad_design_templates"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(100), unique=True, nullable=False)
    name = Column(String(150), nullable=False)
    description = Column(Text)
    layout = Column(String(50), nullable=False)
    variant = Column(String(50), nullable=False)
    default_config = Column(JSONB, nullable=False, default=dict)
    preview_image_url = Column(Text)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))


class Ad(Base):
    __tablename__ = "ads"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    ad_type = Column(PGEnum(AdType, name="ad_type", create_type=False), nullable=False, default=AdType.other)
    status = Column(PGEnum(AdStatus, name="ad_status", create_type=False), nullable=False, default=AdStatus.draft)
    placement = Column(
        PGEnum(AdPlacement, name="ad_placement", create_type=False),
        nullable=False,
        default=AdPlacement.home_between_sections,
    )
    ad_design_template_id = Column(Integer, ForeignKey("ad_design_templates.id", ondelete="SET NULL"))
    design_config = Column(JSONB, nullable=False, default=dict)
    related_content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="SET NULL"))
    image_url = Column(Text)
    mobile_image_url = Column(Text)
    background_image_url = Column(Text)
    sponsor_name = Column(String(255))
    sponsor_logo_url = Column(Text)
    cta_label = Column(String(100))
    cta_url = Column(Text)
    priority = Column(Integer, nullable=False, default=0)
    starts_at = Column(DateTime(timezone=True))
    ends_at = Column(DateTime(timezone=True))
    is_active = Column(Boolean, nullable=False, default=True)
    created_by_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    updated_by_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))
    deleted_at = Column(DateTime(timezone=True))

    template = relationship("AdDesignTemplate")
    related_content_item = relationship("ContentItem")
