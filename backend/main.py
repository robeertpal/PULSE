from datetime import datetime
from decimal import Decimal
import enum
import os

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db
import models

load_dotenv()

app = FastAPI(title="PULSE Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
        data[column.name] = serialize_value(getattr(obj, column.name))

    if include_relationships:
        if hasattr(obj, "category") and getattr(obj, "category", None):
            data["category"] = serialize_model(obj.category)
        if hasattr(obj, "specialization") and getattr(obj, "specialization", None):
            data["specialization"] = serialize_model(obj.specialization)
        if hasattr(obj, "event") and getattr(obj, "event", None):
            data["event"] = serialize_model(obj.event)
        if hasattr(obj, "course") and getattr(obj, "course", None):
            data["course"] = serialize_model(obj.course)
        if hasattr(obj, "publication") and getattr(obj, "publication", None):
            publication_data = serialize_model(obj.publication)
            if hasattr(obj.publication, "issues") and getattr(obj.publication, "issues", None):
                publication_data["issues"] = [serialize_model(issue) for issue in obj.publication.issues]
            data["publication"] = publication_data

    return data


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
        items = db.query(models.ContentItem).offset(skip).limit(limit).all()
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/featured-content")
def get_featured_content(
    limit: int = Query(default=10, le=50),
    db: Session = Depends(get_db),
):
    try:
        items = (
            db.query(models.ContentItem)
            .filter(models.ContentItem.is_featured == True)
            .filter(models.ContentItem.is_active == True)
            .order_by(models.ContentItem.published_at.desc())
            .limit(limit)
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
            db.query(models.ContentItem)
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
            db.query(models.ContentItem)
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
            db.query(models.ContentItem)
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
            db.query(models.ContentItem)
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
            db.query(models.ContentItem)
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
            db.query(models.ContentItem)
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
        return [serialize_model(item) for item in db.query(models.User).all()]
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

from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy import func

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
    is_featured: bool = False
    is_active: bool = True
    published_at: Optional[datetime] = None

class ContentItemCreate(ContentItemBase):
    pass

class ContentItemUpdate(ContentItemBase):
    title: Optional[str] = None
    slug: Optional[str] = None
    content_type: Optional[str] = None

@app.get("/admin/dashboard/stats")
def get_admin_dashboard_stats(db: Session = Depends(get_db)):
    try:
        articles_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.article).count()
        news_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.news).count()
        courses_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.course).count()
        events_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.event).count()
        publications_count = db.query(models.ContentItem).filter(models.ContentItem.content_type == models.ContentItemType.publication).count()
        users_count = db.query(models.User).count()
        
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
            "recent_content": [serialize_model(item) for item in recent_items]
        }
    except Exception as e:
        return {"error": str(e)}

@app.get("/admin/content-items")
def admin_get_content_items(db: Session = Depends(get_db)):
    try:
        items = db.query(models.ContentItem).order_by(models.ContentItem.created_at.desc()).all()
        return [serialize_model(item) for item in items]
    except Exception as e:
        return {"error": str(e)}

@app.post("/admin/content-items")
def admin_create_content_item(item: ContentItemCreate, db: Session = Depends(get_db)):
    try:
        db_item = models.ContentItem(
            title=item.title,
            slug=item.slug,
            content_type=models.ContentItemType(item.content_type),
            status=models.ContentStatus(item.status),
            short_description=item.short_description,
            body=item.body,
            category_id=item.category_id,
            specialization_id=item.specialization_id,
            hero_image_url=item.hero_image_url,
            thumbnail_url=item.thumbnail_url,
            author_name=item.author_name,
            source_url=item.source_url,
            is_featured=item.is_featured,
            is_active=item.is_active,
            published_at=item.published_at
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return serialize_model(db_item)
    except Exception as e:
        db.rollback()
        return {"error": str(e)}

@app.get("/admin/content-items/{id}")
def admin_get_content_item(id: int, db: Session = Depends(get_db)):
    try:
        item = db.query(models.ContentItem).filter(models.ContentItem.id == id).first()
        if not item:
            return {"error": "Not found"}
        return serialize_model(item, include_relationships=True)
    except Exception as e:
        return {"error": str(e)}

@app.put("/admin/content-items/{id}")
def admin_update_content_item(id: int, item: ContentItemUpdate, db: Session = Depends(get_db)):
    try:
        db_item = db.query(models.ContentItem).filter(models.ContentItem.id == id).first()
        if not db_item:
            return {"error": "Not found"}
        
        update_data = item.dict(exclude_unset=True)
        if "content_type" in update_data:
            update_data["content_type"] = models.ContentItemType(update_data["content_type"])
        if "status" in update_data:
            update_data["status"] = models.ContentStatus(update_data["status"])
            
        for key, value in update_data.items():
            setattr(db_item, key, value)
            
        db.commit()
        db.refresh(db_item)
        return serialize_model(db_item)
    except Exception as e:
        db.rollback()
        return {"error": str(e)}

@app.patch("/admin/content-items/{id}/archive")
def admin_archive_content_item(id: int, db: Session = Depends(get_db)):
    try:
        db_item = db.query(models.ContentItem).filter(models.ContentItem.id == id).first()
        if not db_item:
            return {"error": "Not found"}
        db_item.status = models.ContentStatus.archived
        db_item.is_active = False
        db.commit()
        return {"success": True}
    except Exception as e:
        db.rollback()
        return {"error": str(e)}

@app.delete("/admin/content-items/{id}")
def admin_delete_content_item(id: int, db: Session = Depends(get_db)):
    try:
        db_item = db.query(models.ContentItem).filter(models.ContentItem.id == id).first()
        if not db_item:
            return {"error": "Not found"}
        db.delete(db_item)
        db.commit()
        return {"success": True}
    except Exception as e:
        db.rollback()
        return {"error": str(e)}

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

@app.get("/admin/events")
def admin_get_events(db: Session = Depends(get_db)):
    return get_events(db=db, skip=0, limit=1000)

@app.get("/admin/courses")
def admin_get_courses(db: Session = Depends(get_db)):
    return get_courses(db=db, skip=0, limit=1000)

@app.get("/admin/publications")
def admin_get_publications(db: Session = Depends(get_db)):
    return get_publications(db=db, skip=0, limit=1000)

