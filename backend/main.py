from datetime import datetime
from decimal import Decimal
import enum
import os
import re
from pathlib import Path
from uuid import uuid4

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db
import models

load_dotenv()

app = FastAPI(title="PULSE Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5500",
        "http://127.0.0.1:5500",
        "https://pulse-medichub.web.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def serialize_value(value):
    if isinstance(value, enum.Enum):
        return value.value
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime):
        return value.isoformat()
    return value


def serialize_model(obj, include_relationships: bool = False):
    if obj is None:
        return None

    data = {}
    for column in obj.__table__.columns:
        data[column.name] = serialize_value(getattr(obj, column.key))

    if include_relationships:
        if hasattr(obj, "category") and getattr(obj, "category", None):
            category_data = serialize_model(obj.category)
            data["category"] = category_data
            data["category_name"] = category_data.get("name")
        if hasattr(obj, "specialization") and getattr(obj, "specialization", None):
            specialization_data = serialize_model(obj.specialization)
            data["specialization"] = specialization_data
            data["specialization_name"] = specialization_data.get("name")
        if hasattr(obj, "city") and getattr(obj, "city", None):
            city_data = serialize_model(obj.city)
            data["city"] = city_data
            data["city_name"] = city_data.get("name")
        if hasattr(obj, "event") and getattr(obj, "event", None):
            data["event"] = serialize_model(obj.event, include_relationships=True)
        if hasattr(obj, "course") and getattr(obj, "course", None):
            data["course"] = serialize_model(obj.course)
        if hasattr(obj, "publication") and getattr(obj, "publication", None):
            publication_data = serialize_model(obj.publication)
            if hasattr(obj.publication, "issues") and getattr(obj.publication, "issues", None):
                publication_data["issues"] = [serialize_model(issue) for issue in obj.publication.issues]
            data["publication"] = publication_data

    return data


def model_class(name: str):
    return getattr(models, name, None)


def count_model(db: Session, name: str) -> int:
    model = model_class(name)
    if model is None:
        return 0
    return db.query(model).count()


def visible_content_query(db: Session):
    return (
        db.query(models.ContentItem)
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
    )


@app.get("/")
def root():
    return {
        "message": "PULSE API is running",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "docs": "/docs",
    }


@app.get("/health")
def health(db: Session = Depends(get_db)):
    result = {
        "status": "online",
        "database": "disconnected",
        "error": None,
    }

    try:
        db.execute(text("SELECT 1"))
        result["database"] = "connected"
    except Exception as e:
        result["status"] = "degraded"
        result["error"] = str(e)

    return result


# -------------------------
# CONTENT
# -------------------------

@app.get("/content-items")
def get_content_items(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = visible_content_query(db).offset(skip).limit(limit).all()
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/featured-content")
def get_featured_content(
    limit: int = Query(default=5, le=50),
    db: Session = Depends(get_db),
):
    try:
        effective_limit = min(limit, 5)
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.is_featured == True)
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
            )
            .limit(effective_limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/articles")
def get_articles(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.content_type == models.ContentItemType.article)
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/news")
def get_news(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.content_type == models.ContentItemType.news)
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/courses")
def get_courses(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.content_type == models.ContentItemType.course)
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/events")
def get_events(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.content_type == models.ContentItemType.event)
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/courses-events")
def get_courses_events(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(
                models.ContentItem.content_type.in_(
                    [models.ContentItemType.course, models.ContentItemType.event]
                )
            )
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/publications")
def get_publications(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    try:
        items = (
            visible_content_query(db)
            .filter(models.ContentItem.content_type == models.ContentItemType.publication)
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# NOMENCLATURE TABLES
# -------------------------

@app.get("/counties")
def get_counties(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.County).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/cities")
def get_cities(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.City).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/occupations")
def get_occupations(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Occupation).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/specializations")
def get_specializations(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Specialization).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/interests")
def get_interests(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Interest).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/professional-grades")
def get_professional_grades(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.ProfessionalGrade).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/institutions")
def get_institutions(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Institution).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/content-categories")
def get_content_categories(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.ContentCategory).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# EVENT GALLERY
# -------------------------

@app.get("/event-gallery")
def get_event_gallery(
    db: Session = Depends(get_db)
):
    try:
        items = (
            db.query(models.EventGallery)
            .order_by(models.EventGallery.display_order.asc())
            .all()
        )
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}

# -------------------------
# USERS / AUTH
# -------------------------

@app.get("/users")
def get_users(db: Session = Depends(get_db)):
    try:
        user_model = model_class("User")
        if user_model is None:
            return []
        return [serialize_model(item) for item in db.query(user_model).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-profiles")
def get_user_profiles(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserProfile).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/roles")
def get_roles(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Role).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-roles")
def get_user_roles(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserRole).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-email-verifications")
def get_user_email_verifications(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserEmailVerification).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-password-resets")
def get_user_password_resets(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserPasswordReset).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-sessions")
def get_user_sessions(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserSession).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# PERSONS
# -------------------------

@app.get("/persons")
def get_persons(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Person).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# EVENTS
# -------------------------

@app.get("/event-details")
def get_event_details(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Event).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/event-sessions")
def get_event_sessions(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.EventSession).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# COURSES
# -------------------------

@app.get("/course-details")
def get_course_details(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Course).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/course-modules")
def get_course_modules(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.CourseModule).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/course-lessons")
def get_course_lessons(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.CourseLesson).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# PUBLICATIONS
# -------------------------

@app.get("/publication-details")
def get_publication_details(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Publication).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/publication-issues")
def get_publication_issues(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.PublicationIssue).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# USER ACTIVITY
# -------------------------

@app.get("/saved-content")
def get_saved_content(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.SavedContent).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-courses")
def get_user_courses(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserCourse).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-event-registrations")
def get_user_event_registrations(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserEventRegistration).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-activity-logs")
def get_user_activity_logs(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserActivityLog).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# EMC
# -------------------------

@app.get("/emc-credit-rules")
def get_emc_credit_rules(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.EmcCreditRule).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-emc-point-logs")
def get_user_emc_point_logs(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserEmcPointLog).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-emc-certificates")
def get_user_emc_certificates(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserEmcCertificate).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# SUBSCRIPTIONS & PAYMENTS
# -------------------------

@app.get("/subscription-plans")
def get_subscription_plans(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.SubscriptionPlan).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/user-subscriptions")
def get_user_subscriptions(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.UserSubscription).all()]
    except Exception as e:
        return {"error": str(e)}


@app.get("/payments")
def get_payments(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.Payment).all()]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# AUDIT
# -------------------------

@app.get("/audit-logs")
def get_audit_logs(db: Session = Depends(get_db)):
    try:
        return [serialize_model(item) for item in db.query(models.AuditLog).all()]
    except Exception as e:
        return {"error": str(e)}
# -------------------------
# ADMIN ENDPOINTS
# -------------------------

from pydantic import BaseModel, Field
from typing import Optional, List
from sqlalchemy import func

IMAGE_ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
IMAGE_ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
PDF_ALLOWED_CONTENT_TYPES = {"application/pdf"}
PDF_ALLOWED_EXTENSIONS = {".pdf"}
IMAGE_MAX_SIZE = 5 * 1024 * 1024
PDF_MAX_SIZE = 25 * 1024 * 1024


def get_azure_upload_config():
    connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME")
    public_base_url = os.getenv("AZURE_STORAGE_PUBLIC_BASE_URL")

    missing = [
        name
        for name, value in {
            "AZURE_STORAGE_CONNECTION_STRING": connection_string,
            "AZURE_STORAGE_CONTAINER_NAME": container_name,
            "AZURE_STORAGE_PUBLIC_BASE_URL": public_base_url,
        }.items()
        if not value
    ]
    if missing:
        raise HTTPException(
            status_code=500,
            detail=f"Azure upload configuration missing: {', '.join(missing)}",
        )

    return connection_string, container_name, public_base_url.rstrip("/")


def sanitize_filename(filename: str):
    stem = Path(filename or "upload").stem.lower()
    suffix = Path(filename or "").suffix.lower()
    stem = re.sub(r"[^a-z0-9._-]+", "-", stem)
    stem = re.sub(r"-+", "-", stem).strip("-._")
    return f"{stem or 'upload'}{suffix}"


def validate_upload_file(file: UploadFile, allowed_content_types: set, allowed_extensions: set):
    content_type = (file.content_type or "").lower()
    sanitized_name = sanitize_filename(file.filename or "upload")
    extension = Path(sanitized_name).suffix.lower()

    if content_type not in allowed_content_types:
        allowed = ", ".join(sorted(allowed_content_types))
        raise HTTPException(status_code=400, detail=f"Tip fișier neacceptat. Tipuri permise: {allowed}")
    if extension not in allowed_extensions:
        allowed = ", ".join(sorted(allowed_extensions))
        raise HTTPException(status_code=400, detail=f"Extensie fișier neacceptată. Extensii permise: {allowed}")

    return sanitized_name, content_type


async def read_limited_upload(file: UploadFile, max_size: int):
    data = await file.read(max_size + 1)
    if not data:
        raise HTTPException(status_code=400, detail="Fișierul este gol")
    if len(data) > max_size:
        raise HTTPException(status_code=413, detail=f"Fișierul depășește limita de {max_size // (1024 * 1024)}MB")
    return data


def generate_blob_name(folder: str, file_name: str):
    now = datetime.utcnow()
    return f"{folder}/{now:%Y/%m}/{uuid4()}-{file_name}"


def upload_to_azure_blob(blob_name: str, data: bytes, content_type: str):
    connection_string, container_name, public_base_url = get_azure_upload_config()

    try:
        from azure.storage.blob import BlobServiceClient, ContentSettings
    except ImportError as exc:
        raise HTTPException(
            status_code=500,
            detail="Pachetul azure-storage-blob nu este instalat pe server",
        ) from exc

    service_client = BlobServiceClient.from_connection_string(connection_string)
    blob_client = service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_client.upload_blob(
        data,
        overwrite=False,
        content_settings=ContentSettings(content_type=content_type),
    )

    return f"{public_base_url}/{blob_name}"


async def handle_upload(
    file: UploadFile,
    folder: str,
    max_size: int,
    allowed_content_types: set,
    allowed_extensions: set,
):
    file_name, content_type = validate_upload_file(file, allowed_content_types, allowed_extensions)
    data = await read_limited_upload(file, max_size)
    blob_name = generate_blob_name(folder, file_name)
    url = upload_to_azure_blob(blob_name, data, content_type)
    return {
        "url": url,
        "file_name": file_name,
        "blob_name": blob_name,
        "content_type": content_type,
    }


@app.post("/admin/uploads/image")
async def admin_upload_image(file: UploadFile = File(...)):
    return await handle_upload(
        file=file,
        folder="images",
        max_size=IMAGE_MAX_SIZE,
        allowed_content_types=IMAGE_ALLOWED_CONTENT_TYPES,
        allowed_extensions=IMAGE_ALLOWED_EXTENSIONS,
    )


@app.post("/admin/uploads/pdf")
async def admin_upload_pdf(file: UploadFile = File(...)):
    return await handle_upload(
        file=file,
        folder="documents",
        max_size=PDF_MAX_SIZE,
        allowed_content_types=PDF_ALLOWED_CONTENT_TYPES,
        allowed_extensions=PDF_ALLOWED_EXTENSIONS,
    )

class ContentItemBase(BaseModel):
    title: str
    slug: str
    content_type: str
    status: str = "draft"
    short_description: Optional[str] = None
    body: Optional[str] = None
    category_id: Optional[int] = None
    specialization_id: Optional[int] = None
    hero_image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    author_name: Optional[str] = None
    source_url: Optional[str] = None
    seo_title: Optional[str] = None
    seo_description: Optional[str] = None
    canonical_url: Optional[str] = None
    is_featured: bool = False
    is_active: bool = True
    published_at: Optional[datetime] = None

class ContentItemCreate(ContentItemBase):
    pass

class ContentItemUpdate(ContentItemBase):
    title: Optional[str] = None
    slug: Optional[str] = None
    content_type: Optional[str] = None


class CourseDetailsPayload(BaseModel):
    emc_credits: Optional[int] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    enrollment_url: Optional[str] = None
    provider: Optional[str] = None
    course_status: str = "draft"


class EventDetailsPayload(BaseModel):
    city_id: Optional[int] = None
    venue_name: Optional[str] = None
    attendance_mode: str = "onsite"
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    price_type: str = "free"
    price_amount: Optional[float] = None
    emc_credits: Optional[int] = None
    accreditation_status: Optional[str] = None
    event_page_url: Optional[str] = None
    registration_url: Optional[str] = None


class PublicationDetailsPayload(BaseModel):
    name: Optional[str] = None
    logo_url: Optional[str] = None
    description: Optional[str] = None
    emc_credits_text: Optional[str] = None
    creditation_text: Optional[str] = None
    indexing_text: Optional[str] = None
    subscription_url: Optional[str] = None


class CourseAdminPayload(ContentItemBase):
    course: CourseDetailsPayload = Field(default_factory=CourseDetailsPayload)


class EventAdminPayload(ContentItemBase):
    event: EventDetailsPayload = Field(default_factory=EventDetailsPayload)


class PublicationAdminPayload(ContentItemBase):
    publication: PublicationDetailsPayload = Field(default_factory=PublicationDetailsPayload)


CONTENT_ITEM_FIELDS = [
    "title",
    "slug",
    "content_type",
    "status",
    "short_description",
    "body",
    "category_id",
    "specialization_id",
    "hero_image_url",
    "thumbnail_url",
    "author_name",
    "source_url",
    "seo_title",
    "seo_description",
    "canonical_url",
    "is_featured",
    "is_active",
    "published_at",
]


def enum_value(enum_class, value, field_name: str):
    if value in (None, ""):
        return None
    try:
        return enum_class(value)
    except ValueError as exc:
        allowed = ", ".join(item.value for item in enum_class)
        raise HTTPException(status_code=400, detail=f"{field_name} invalid. Valori acceptate: {allowed}") from exc


def pydantic_dump(item: BaseModel, exclude_unset: bool = False):
    return item.model_dump(exclude_unset=exclude_unset)


def content_item_data(item: BaseModel, exclude_unset: bool = False):
    data = pydantic_dump(item, exclude_unset=exclude_unset)
    return {key: data[key] for key in CONTENT_ITEM_FIELDS if key in data}


def normalize_content_item_data(data: dict):
    normalized = dict(data)
    if "content_type" in normalized:
        normalized["content_type"] = enum_value(models.ContentItemType, normalized["content_type"], "content_type")
    if "status" in normalized:
        normalized["status"] = enum_value(models.ContentStatus, normalized["status"], "status")
    return normalized


def serialize_content_item(item: models.ContentItem):
    return serialize_model(item, include_relationships=True)


def create_content_item(db: Session, item: BaseModel, expected_type: str):
    data = content_item_data(item)
    data["content_type"] = expected_type
    db_item = models.ContentItem(**normalize_content_item_data(data))
    db.add(db_item)
    db.flush()
    return db_item


def update_content_item(db_item: models.ContentItem, item: BaseModel, expected_type: str):
    data = content_item_data(item, exclude_unset=True)
    data["content_type"] = expected_type
    for key, value in normalize_content_item_data(data).items():
        setattr(db_item, key, value)


def get_content_item_or_404(db: Session, content_item_id: int):
    db_item = db.query(models.ContentItem).filter(models.ContentItem.id == content_item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Content item not found")
    return db_item


def ensure_content_type(db_item: models.ContentItem, expected_type: str):
    current_type = serialize_value(db_item.content_type)
    if current_type != expected_type:
        raise HTTPException(
            status_code=400,
            detail=f"Content item {db_item.id} este '{current_type}', nu '{expected_type}'",
        )


def child_update_data(details: BaseModel, allowed_fields: set):
    data = pydantic_dump(details, exclude_unset=True)
    data.pop("id", None)
    data.pop("content_item_id", None)
    return {key: value for key, value in data.items() if key in allowed_fields}

@app.get("/admin/dashboard/stats")
def get_admin_dashboard_stats(db: Session = Depends(get_db)):
    try:
        articles_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.article).count()
        news_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.news).count()
        courses_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.course).count()
        events_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.event).count()
        publications_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.publication).count()
        users_count = count_model(db, "User")
        
        recent_items = db.query(models.ContentItem).order_by(models.ContentItem.created_at.desc()).limit(5).all()
        
        return {
            "stats": {
                "articles": articles_count,
                "news": news_count,
                "courses": courses_count,
                "events": events_count,
                "publications": publications_count,
                "users": users_count
            },
            "recent_content": [serialize_content_item(item) for item in recent_items]
        }
    except Exception as e:
        return {"error": str(e)}

@app.get("/admin/content-items")
def admin_get_content_items(db: Session = Depends(get_db)):
    try:
        items = db.query(models.ContentItem).order_by(models.ContentItem.created_at.desc()).all()
        return [serialize_content_item(item) for item in items]
    except Exception as e:
        return {"error": str(e)}

@app.post("/admin/content-items")
def admin_create_content_item(item: ContentItemCreate, db: Session = Depends(get_db)):
    try:
        db_item = models.ContentItem(**normalize_content_item_data(content_item_data(item)))
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

@app.get("/admin/content-items/{id}")
def admin_get_content_item(id: int, db: Session = Depends(get_db)):
    try:
        item = get_content_item_or_404(db, id)
        return serialize_content_item(item)
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

@app.put("/admin/content-items/{id}")
def admin_update_content_item(id: int, item: ContentItemUpdate, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, id)
        update_data = normalize_content_item_data(content_item_data(item, exclude_unset=True))

        for key, value in update_data.items():
            setattr(db_item, key, value)
            
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

@app.patch("/admin/content-items/{id}/archive")
def admin_archive_content_item(id: int, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, id)
        db_item.status = models.ContentStatus.archived
        db_item.is_active = False
        db.commit()
        return {"success": True}
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

@app.delete("/admin/content-items/{id}")
def admin_delete_content_item(id: int, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, id)
        db.delete(db_item)
        db.commit()
        return {"success": True}
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

@app.get("/admin/categories")
def admin_get_categories(db: Session = Depends(get_db)):
    return get_content_categories(db)

@app.get("/admin/specializations")
def admin_get_specializations(db: Session = Depends(get_db)):
    return get_specializations(db)

@app.get("/admin/cities")
def admin_get_cities(db: Session = Depends(get_db)):
    return get_cities(db)

@app.get("/admin/users")
def admin_get_users(db: Session = Depends(get_db)):
    return get_users(db)


def update_course_details(db_course: models.Course, details: CourseDetailsPayload):
    data = child_update_data(
        details,
        {
            "emc_credits",
            "valid_from",
            "valid_until",
            "enrollment_url",
            "provider",
            "course_status",
        },
    )
    if "course_status" in data:
        data["course_status"] = enum_value(models.CourseStatusEnum, data["course_status"], "course_status")
    for key, value in data.items():
        setattr(db_course, key, value)


def update_event_details(db_event: models.Event, details: EventDetailsPayload, require_dates: bool = False):
    data = child_update_data(
        details,
        {
            "city_id",
            "venue_name",
            "attendance_mode",
            "start_date",
            "end_date",
            "price_type",
            "price_amount",
            "emc_credits",
            "accreditation_status",
            "event_page_url",
            "registration_url",
        },
    )
    if require_dates and not (data.get("start_date") and data.get("end_date")):
        raise HTTPException(status_code=400, detail="start_date și end_date sunt obligatorii pentru evenimente")
    if require_dates:
        data.setdefault("attendance_mode", "onsite")
        data.setdefault("price_type", "free")
    if "attendance_mode" in data:
        data["attendance_mode"] = enum_value(models.AttendanceMode, data["attendance_mode"], "attendance_mode")
    if "price_type" in data:
        data["price_type"] = enum_value(models.PriceTypeEnum, data["price_type"], "price_type")
    if "accreditation_status" in data:
        data["accreditation_status"] = enum_value(models.AccreditationStatusEnum, data["accreditation_status"], "accreditation_status")
    for key, value in data.items():
        setattr(db_event, key, value)


def update_publication_details(db_publication: models.Publication, details: PublicationDetailsPayload, fallback_title: str):
    data = child_update_data(
        details,
        {
            "name",
            "logo_url",
            "description",
            "emc_credits_text",
            "creditation_text",
            "indexing_text",
            "subscription_url",
        },
    )
    if not data.get("name"):
        data["name"] = fallback_title
    for key, value in data.items():
        setattr(db_publication, key, value)


@app.get("/admin/events")
def admin_get_events(db: Session = Depends(get_db)):
    return get_events(db=db, skip=0, limit=1000)


@app.post("/admin/events")
def admin_create_event(item: EventAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = create_content_item(db, item, "event")
        db_event = models.Event(content_item_id=db_item.id)
        update_event_details(db_event, item.event, require_dates=True)
        db.add(db_event)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.put("/admin/events/{content_item_id}")
def admin_update_event(content_item_id: int, item: EventAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, content_item_id)
        ensure_content_type(db_item, "event")
        update_content_item(db_item, item, "event")
        db_event = db.query(models.Event).filter(models.Event.content_item_id == content_item_id).first()
        if not db_event:
            raise HTTPException(status_code=404, detail="Event details not found for this content item")
        update_event_details(db_event, item.event, require_dates=False)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/courses")
def admin_get_courses(db: Session = Depends(get_db)):
    return get_courses(db=db, skip=0, limit=1000)


@app.post("/admin/courses")
def admin_create_course(item: CourseAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = create_content_item(db, item, "course")
        db_course = models.Course(content_item_id=db_item.id)
        update_course_details(db_course, item.course)
        db.add(db_course)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.put("/admin/courses/{content_item_id}")
def admin_update_course(content_item_id: int, item: CourseAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, content_item_id)
        ensure_content_type(db_item, "course")
        update_content_item(db_item, item, "course")
        db_course = db.query(models.Course).filter(models.Course.content_item_id == content_item_id).first()
        if not db_course:
            raise HTTPException(status_code=404, detail="Course details not found for this content item")
        update_course_details(db_course, item.course)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/publications")
def admin_get_publications(db: Session = Depends(get_db)):
    return get_publications(db=db, skip=0, limit=1000)


@app.post("/admin/publications")
def admin_create_publication(item: PublicationAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = create_content_item(db, item, "publication")
        db_publication = models.Publication(content_item_id=db_item.id)
        update_publication_details(db_publication, item.publication, db_item.title)
        db.add(db_publication)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.put("/admin/publications/{content_item_id}")
def admin_update_publication(content_item_id: int, item: PublicationAdminPayload, db: Session = Depends(get_db)):
    try:
        db_item = get_content_item_or_404(db, content_item_id)
        ensure_content_type(db_item, "publication")
        update_content_item(db_item, item, "publication")
        db_publication = db.query(models.Publication).filter(models.Publication.content_item_id == content_item_id).first()
        if not db_publication:
            raise HTTPException(status_code=404, detail="Publication details not found for this content item")
        update_publication_details(db_publication, item.publication, db_item.title)
        db.commit()
        db.refresh(db_item)
        return serialize_content_item(db_item)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e
