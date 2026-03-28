import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, Text, ForeignKey, 
    Numeric, DateTime, Enum as SAEnum, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.sql import func

Base = declarative_base()

class ContentItemType(enum.Enum):
    article = "article"
    news = "news"
    course = "course"
    event = "event"
    publication = "publication"


# ==========================================
# NOMENCLATOARE (Liste Statice și Geografie)
# ==========================================

class County(Base):
    __tablename__ = "counties"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    
    cities = relationship("City", back_populates="county")

class City(Base):
    __tablename__ = "cities"
    id = Column(Integer, primary_key=True)
    county_id = Column(Integer, ForeignKey("counties.id", ondelete="RESTRICT"), nullable=False)
    name = Column(String(255), nullable=False)
    
    county = relationship("County", back_populates="cities")
    institutions = relationship("Institution", back_populates="city")

class Occupation(Base):
    __tablename__ = "occupations"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)

class Specialization(Base):
    __tablename__ = "specializations"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)

class Interest(Base):
    __tablename__ = "interests"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), unique=True, nullable=False)

class ProfessionalGrade(Base):
    __tablename__ = "professional_grades"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)

class Institution(Base):
    __tablename__ = "institutions"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id", ondelete="RESTRICT"), nullable=False)
    address = Column(Text, nullable=True)
    type = Column(String(100), nullable=True)

    city = relationship("City", back_populates="institutions")

class ContentCategory(Base):
    __tablename__ = "content_categories"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)


# ==========================================
# DOMENIUL USER
# ==========================================

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    saved_contents = relationship("SavedContent", back_populates="user")
    activity_logs = relationship("UserActivityLog", back_populates="user")
    recommendations = relationship("Recommendation", back_populates="user")

class UserProfile(Base):
    __tablename__ = "user_profiles"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    cnp = Column(String(13), nullable=True)
    phone = Column(String(50), nullable=True)
    correspondence_address = Column(Text, nullable=True)
    
    city_id = Column(Integer, ForeignKey("cities.id", ondelete="RESTRICT"), nullable=False)
    occupation_id = Column(Integer, ForeignKey("occupations.id", ondelete="RESTRICT"), nullable=False)
    specialization_id = Column(Integer, ForeignKey("specializations.id", ondelete="SET NULL"), nullable=True)
    professional_grade_id = Column(Integer, ForeignKey("professional_grades.id", ondelete="SET NULL"), nullable=True)
    institution_id = Column(Integer, ForeignKey("institutions.id", ondelete="SET NULL"), nullable=True)
    
    total_emc_points = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    user = relationship("User", back_populates="profile")
    city = relationship("City")
    occupation = relationship("Occupation")
    specialization = relationship("Specialization")
    professional_grade = relationship("ProfessionalGrade")
    institution = relationship("Institution")
    
    # Interesul este vizibil direct pe entitatea profil, așa cum s-a cerut
    interests = relationship("Interest", secondary="user_profile_interests")

class UserProfileInterest(Base):
    __tablename__ = "user_profile_interests"
    user_profile_id = Column(Integer, ForeignKey("user_profiles.id", ondelete="CASCADE"), primary_key=True)
    interest_id = Column(Integer, ForeignKey("interests.id", ondelete="CASCADE"), primary_key=True)


# ==========================================
# DOMENIUL CONTENT
# ==========================================

class ContentItem(Base):
    __tablename__ = "content_items"
    id = Column(Integer, primary_key=True)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False)
    content_type = Column(SAEnum(ContentItemType), nullable=False)
    
    short_description = Column(Text, nullable=True)
    body = Column(Text, nullable=True)
    
    category_id = Column(Integer, ForeignKey("content_categories.id", ondelete="SET NULL"), nullable=True)
    specialization_id = Column(Integer, ForeignKey("specializations.id", ondelete="SET NULL"), nullable=True)
    
    hero_image_url = Column(Text, nullable=True)
    thumbnail_url = Column(Text, nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True)
    author_name = Column(String(255), nullable=True)
    source_url = Column(Text, nullable=True)
    
    is_featured = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relații adăugate expres către nomenclatoare
    category = relationship("ContentCategory")
    specialization = relationship("Specialization")

    event = relationship("Event", back_populates="content_item", uselist=False)
    course = relationship("Course", back_populates="content_item", uselist=False)
    publication = relationship("Publication", back_populates="content_item", uselist=False)

class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id", ondelete="SET NULL"), nullable=True)
    
    venue_name = Column(String(255), nullable=True)
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True), nullable=False)
    
    price_type = Column(String(50), nullable=False)
    price_amount = Column(Numeric(10, 2), nullable=True)
    emc_credits = Column(Integer, nullable=True)
    accreditation_status = Column(String(100), nullable=True)
    event_page_url = Column(Text, nullable=True)
    registration_url = Column(Text, nullable=True)

    content_item = relationship("ContentItem", back_populates="event")
    city = relationship("City")

class Course(Base):
    __tablename__ = "courses"
    id = Column(Integer, primary_key=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    emc_credits = Column(Integer, nullable=True)
    valid_from = Column(DateTime(timezone=True), nullable=True)
    valid_until = Column(DateTime(timezone=True), nullable=True)
    enrollment_url = Column(Text, nullable=True)
    provider = Column(String(255), nullable=True)
    course_status = Column(String(50), nullable=True)

    content_item = relationship("ContentItem", back_populates="course")

class Publication(Base):
    __tablename__ = "publications"
    id = Column(Integer, primary_key=True)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    name = Column(String(255), nullable=False)
    logo_url = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    
    emc_credits_text = Column(Text, nullable=True)
    creditation_text = Column(Text, nullable=True)
    indexing_text = Column(Text, nullable=True)
    subscription_url = Column(Text, nullable=True)

    content_item = relationship("ContentItem", back_populates="publication")
    issues = relationship("PublicationIssue", back_populates="publication", cascade="all, delete-orphan")

class PublicationIssue(Base):
    __tablename__ = "publication_issues"
    id = Column(Integer, primary_key=True)
    publication_id = Column(Integer, ForeignKey("publications.id", ondelete="CASCADE"), nullable=False)
    
    year = Column(Integer, nullable=False)
    issue_number = Column(Integer, nullable=False)
    issue_label = Column(String(100), nullable=True)
    cover_image_url = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (UniqueConstraint('publication_id', 'year', 'issue_number', name='uq_publication_issue'),)
    publication = relationship("Publication", back_populates="issues")

# ==========================================
# RECOMANDARI, ACTIVITATE & EMC
# ==========================================

class Recommendation(Base):
    __tablename__ = "recommendations"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), nullable=False)
    score = Column(Numeric(5, 2), nullable=True)
    reasoning = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (UniqueConstraint('user_id', 'content_item_id', name='uq_user_recommendation'),)
    user = relationship("User", back_populates="recommendations")
    content_item = relationship("ContentItem")

class UserActivityLog(Base):
    __tablename__ = "user_activity_logs"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    action_type = Column(String(100), nullable=False)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="SET NULL"), nullable=True)
    metadata_info = Column("metadata", JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User", back_populates="activity_logs")

class UserEmcPointLog(Base):
    __tablename__ = "user_emc_point_logs"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    source_type = Column(String(100), nullable=False)
    source_id = Column(Integer, nullable=False)
    points = Column(Integer, nullable=False)
    awarded_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User")


# ==========================================
# INTERSECȚII M:N (USER & CONTENT)
# ==========================================

class SavedContent(Base):
    __tablename__ = "saved_content"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    content_item_id = Column(Integer, ForeignKey("content_items.id", ondelete="CASCADE"), nullable=False)
    saved_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    __table_args__ = (UniqueConstraint('user_id', 'content_item_id', name='uq_user_saved_content'),)
    user = relationship("User", back_populates="saved_contents")
    content_item = relationship("ContentItem")

class UserCourse(Base):
    __tablename__ = "user_courses"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    
    progress_percent = Column(Integer, default=0, nullable=False)
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(50), nullable=False)

    __table_args__ = (UniqueConstraint('user_id', 'course_id', name='uq_user_course'),)
    
    user = relationship("User")
    course = relationship("Course")

class UserEventRegistration(Base):
    __tablename__ = "user_event_registrations"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    event_id = Column(Integer, ForeignKey("events.id", ondelete="CASCADE"), nullable=False)
    
    registered_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    status = Column(String(50), nullable=False)

    __table_args__ = (UniqueConstraint('user_id', 'event_id', name='uq_user_event_registration'),)

    user = relationship("User")
    event = relationship("Event")
