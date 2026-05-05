from datetime import datetime
from datetime import timedelta
from decimal import Decimal
import enum
import hashlib
from io import BytesIO
import json
import logging
import os
import re
import secrets
from pathlib import Path
from typing import List, Optional
from uuid import uuid4

import httpx
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, File, Header, HTTPException, Query, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pypdf import PdfReader
from sqlalchemy import text
from sqlalchemy.orm import Session, joinedload

from database import get_db
import models
from schemas import UserCreate, UserLogin, UserLogout

try:
    from google import genai
except ImportError:
    genai = None

load_dotenv()

app = FastAPI(title="PULSE Backend API")
logger = logging.getLogger("pulse.admin")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5500",
        "http://127.0.0.1:5500",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "https://pulse-medichub.web.app",
    ],
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=[
        "Accept-Ranges",
        "Content-Disposition",
        "Content-Length",
        "Content-Range",
        "Content-Type",
        "ETag",
        "Last-Modified",
    ],
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


def get_user_model():
    user_model = model_class("User")
    if user_model is None:
        raise HTTPException(status_code=500, detail="User model is not available")
    return user_model


def get_user_session_model():
    session_model = model_class("UserSession")
    if session_model is None:
        raise HTTPException(status_code=500, detail="UserSession model is not available")
    return session_model


def get_current_user_id(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(default=None),
) -> int:
    if authorization is None:
        raise HTTPException(status_code=401, detail="Missing Authorization header")

    parts = authorization.strip().split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1].strip():
        raise HTTPException(status_code=401, detail="Invalid Authorization header")

    session_token = parts[1].strip()
    session_hash = hashlib.sha256(session_token.encode("utf-8")).hexdigest()
    session_model = get_user_session_model()
    user_model = get_user_model()

    session_record = (
        db.query(session_model)
        .filter(session_model.refresh_token_hash == session_hash)
        .filter(session_model.revoked_at.is_(None))
        .filter(session_model.expires_at > datetime.utcnow())
        .first()
    )
    if session_record is None:
        raise HTTPException(status_code=401, detail="Session is invalid or expired")

    user = db.query(user_model).filter(user_model.id == session_record.user_id).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=401, detail="User is inactive or missing")

    return user.id


def visible_content_query(db: Session):
    return (
        db.query(models.ContentItem)
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
    )


def visible_content_card_query(db: Session):
    return visible_content_query(db).options(
        joinedload(models.ContentItem.category),
        joinedload(models.ContentItem.specialization),
        joinedload(models.ContentItem.event).joinedload(models.Event.city),
        joinedload(models.ContentItem.course),
        joinedload(models.ContentItem.publication),
    )


def normalize_id_filter_values(values):
    if values is None:
        return []
    if not isinstance(values, (list, tuple, set)):
        return []
    return [value for value in values if value is not None]


def apply_content_filters(query, category_ids: Optional[List[int]] = None, specialization_ids: Optional[List[int]] = None):
    category_ids = normalize_id_filter_values(category_ids)
    specialization_ids = normalize_id_filter_values(specialization_ids)
    if category_ids:
        query = query.filter(models.ContentItem.category_id.in_(category_ids))
    if specialization_ids:
        query = query.filter(models.ContentItem.specialization_id.in_(specialization_ids))
    return query


def get_current_demo_user_id() -> int:
    # TODO: Replace demo user id with authenticated user once login is implemented.
    return 1


def hash_password(password: str, salt: bytes | None = None) -> str:
    salt = salt or secrets.token_bytes(16)
    iterations = 120_000
    derived_key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        iterations,
    )
    return f"pbkdf2_sha256${iterations}${salt.hex()}${derived_key.hex()}"


def verify_password(password: str, password_hash: str) -> bool:
    try:
        algorithm, iterations_str, salt_hex, derived_key_hex = password_hash.split("$")
        if algorithm != "pbkdf2_sha256":
            return False
        iterations = int(iterations_str)
        salt = bytes.fromhex(salt_hex)
        expected_key = bytes.fromhex(derived_key_hex)
        candidate_key = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt,
            iterations,
        )
        return secrets.compare_digest(candidate_key, expected_key)
    except Exception:
        return False


def create_session_token() -> str:
    return uuid4().hex


def ensure_demo_user_exists(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is not None:
        return

    now = datetime.utcnow()
    db.add(
        models.User(
            id=user_id,
            email=f"demo-doctor-{user_id}@pulse.local",
            password_hash="demo-auth-placeholder",
            is_active=True,
            created_at=now,
            updated_at=now,
        )
    )
    db.commit()


def _normalize_name(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    normalized = value.strip()
    return normalized or None


def _resolve_county_id(db: Session, payload: UserCreate) -> Optional[int]:
    if payload.county_id is not None:
        county = db.query(models.County).filter(models.County.id == payload.county_id).first()
        if county is None:
            raise HTTPException(status_code=422, detail="County id is invalid")
        return county.id

    county_name = _normalize_name(payload.county_name)
    if county_name is None:
        return None

    county = db.query(models.County).filter(models.County.name.ilike(county_name)).first()
    if county is not None:
        return county.id

    county = models.County(name=county_name)
    db.add(county)
    db.flush()
    return county.id


def _resolve_city_id(db: Session, payload: UserCreate, county_id: Optional[int]) -> int:
    if payload.city_id is not None:
        city = db.query(models.City).filter(models.City.id == payload.city_id).first()
        if city is None:
            raise HTTPException(status_code=422, detail="City id is invalid")
        if county_id is not None and city.county_id != county_id:
            raise HTTPException(status_code=422, detail="City does not belong to selected county")
        return city.id

    city_name = _normalize_name(payload.city_name)
    if city_name is None:
        raise HTTPException(status_code=422, detail="City is required")
    if county_id is None:
        raise HTTPException(status_code=422, detail="County is required when city is provided manually")

    city = (
        db.query(models.City)
        .filter(models.City.county_id == county_id)
        .filter(models.City.name.ilike(city_name))
        .first()
    )
    if city is not None:
        return city.id

    city = models.City(name=city_name, county_id=county_id)
    db.add(city)
    db.flush()
    return city.id


def _resolve_occupation_id(db: Session, payload: UserCreate) -> int:
    if payload.occupation_id is not None:
        occupation = db.query(models.Occupation).filter(models.Occupation.id == payload.occupation_id).first()
        if occupation is None:
            raise HTTPException(status_code=422, detail="Occupation id is invalid")
        return occupation.id

    occupation_name = _normalize_name(payload.occupation_name)
    if occupation_name is None:
        raise HTTPException(status_code=422, detail="Occupation is required")

    occupation = db.query(models.Occupation).filter(models.Occupation.name.ilike(occupation_name)).first()
    if occupation is None:
        raise HTTPException(status_code=422, detail="Occupation name is invalid")
    return occupation.id


def _resolve_specialization_id(db: Session, payload: UserCreate) -> Optional[int]:
    if payload.specialization_id is not None:
        specialization = (
            db.query(models.Specialization)
            .filter(models.Specialization.id == payload.specialization_id)
            .first()
        )
        if specialization is None:
            raise HTTPException(status_code=422, detail="Specialization id is invalid")
        return specialization.id

    specialization_name = _normalize_name(payload.specialization_name)
    if specialization_name is None:
        return None

    specialization = (
        db.query(models.Specialization)
        .filter(models.Specialization.name.ilike(specialization_name))
        .first()
    )
    if specialization is None:
        raise HTTPException(status_code=422, detail="Specialization name is invalid")
    return specialization.id


def _resolve_professional_grade_id(db: Session, payload: UserCreate) -> Optional[int]:
    if payload.professional_grade_id is not None:
        grade = (
            db.query(models.ProfessionalGrade)
            .filter(models.ProfessionalGrade.id == payload.professional_grade_id)
            .first()
        )
        if grade is None:
            raise HTTPException(status_code=422, detail="Professional grade id is invalid")
        return grade.id

    grade_name = _normalize_name(payload.professional_grade_name or payload.titlu_universitar)
    if grade_name is None:
        return None

    grade = (
        db.query(models.ProfessionalGrade)
        .filter(models.ProfessionalGrade.name.ilike(grade_name))
        .first()
    )
    if grade is None:
        raise HTTPException(status_code=422, detail="Professional grade name is invalid")
    return grade.id


def get_public_content_item_or_404(db: Session, content_item_id: int):
    item = (
        visible_content_card_query(db)
        .filter(models.ContentItem.id == content_item_id)
        .first()
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Content item not found")
    return item


AI_SUMMARY_DISCLAIMER = "Rezumat generat automat. Verificați articolul original pentru decizii profesionale."


def clean_ai_summary_text(value: Optional[str]) -> str:
    if not value:
        return ""
    return (
        re.sub(r"<[^>]*>", " ", value)
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .strip()
    )


def build_ai_summary_input(item):
    title = clean_ai_summary_text(item.title)
    short_description = clean_ai_summary_text(item.short_description)
    body = clean_ai_summary_text(item.body)
    article_text = "\n\n".join(part for part in [short_description, body] if part)

    if not article_text:
        raise HTTPException(
            status_code=400,
            detail="Nu există suficient conținut pentru rezumat.",
        )

    return "\n\n".join(
        part
        for part in [
            f"Titlu: {title}" if title else None,
            f"Descriere: {short_description}" if short_description else None,
            f"Conținut: {body}" if body else None,
        ]
        if part
    )


def parse_ai_summary_response(raw_text: str):
    cleaned = raw_text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?", "", cleaned, flags=re.IGNORECASE).strip()
        cleaned = re.sub(r"```$", "", cleaned).strip()

    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        return {"summary": cleaned, "key_points": []}

    if not isinstance(data, dict):
        return {"summary": cleaned, "key_points": []}

    summary = str(data.get("summary") or "").strip()
    raw_key_points = data.get("key_points") or []
    key_points = []
    if isinstance(raw_key_points, list):
        key_points = [
            str(point).strip()
            for point in raw_key_points
            if str(point).strip()
        ]

    return {"summary": summary, "key_points": key_points[:5]}


def parse_plain_ai_summary_response(raw_text: str):
    cleaned = raw_text.strip()
    if not cleaned:
        return {"summary": "", "key_points": []}

    payload = parse_ai_summary_response(cleaned)
    if payload["summary"] and payload["summary"] != cleaned:
        return payload

    key_points = []
    summary_lines = []
    in_key_points = False
    for line in cleaned.splitlines():
        stripped = line.strip()
        if not stripped:
            if summary_lines and not in_key_points:
                summary_lines.append("")
            continue

        normalized = stripped.lower().rstrip(":")
        if normalized in {"idei cheie", "puncte cheie", "key points"}:
            in_key_points = True
            continue
        if normalized in {"rezumat", "summary"}:
            in_key_points = False
            continue

        bullet_match = re.match(r"^[-*•]\s*(.+)$", stripped)
        if bullet_match:
            point = bullet_match.group(1).strip()
            if point:
                key_points.append(point)
            continue

        if in_key_points:
            key_points.append(stripped)
        else:
            summary_lines.append(stripped)

    summary = "\n".join(summary_lines).strip() or cleaned
    return {"summary": summary, "key_points": key_points[:5]}


def build_gemini_summary_prompt(summary_input: str):
    return (
        "Ești un asistent medical editorial pentru medici.\n"
        "Generează un rezumat scurt, clar și util în limba română, bazat "
        "exclusiv pe articolul de mai jos.\n"
        "Nu inventa fapte, nu completa informații lipsă și nu oferi diagnostic, "
        "recomandări de tratament sau decizii clinice.\n"
        "Rezumatul trebuie să fie mai scurt decât articolul și să evidențieze "
        "ideile importante.\n"
        "Răspunde simplu în acest format:\n"
        "Rezumat: <un paragraf scurt>\n"
        "Idei cheie:\n"
        "- <idee importantă>\n"
        "- <idee importantă>\n\n"
        f"Disclaimer de afișat în aplicație: {AI_SUMMARY_DISCLAIMER}\n\n"
        f"Articol:\n{summary_input}"
    )


def generate_ai_summary_payload(summary_input: str):
    provider = os.getenv("AI_PROVIDER", "gemini").strip().lower()
    api_key = os.getenv("GEMINI_API_KEY")
    if provider != "gemini" or not api_key or genai is None:
        raise HTTPException(
            status_code=503,
            detail="Serviciul AI nu este configurat momentan.",
        )

    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    prompt_text = build_gemini_summary_prompt(summary_input)

    try:
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model=model,
            contents=prompt_text,
        )
        payload = parse_plain_ai_summary_response(response.text or "")
    except Exception:
        logger.exception("Gemini AI summary generation failed")
        raise HTTPException(
            status_code=503,
            detail="Serviciul AI nu este disponibil momentan. Încearcă din nou mai târziu.",
        )

    if not payload["summary"]:
        raise HTTPException(
            status_code=503,
            detail="Serviciul AI nu este disponibil momentan. Încearcă din nou mai târziu.",
        )

    return payload, model


def download_publication_issue_pdf_bytes(issue: models.PublicationIssue) -> bytes:
    pdf_url = (issue.issue_url or "").strip()
    if not pdf_url:
        raise HTTPException(
            status_code=404,
            detail="PDF-ul ediției nu este disponibil momentan.",
        )

    if not (pdf_url.startswith("http://") or pdf_url.startswith("https://")):
        raise HTTPException(
            status_code=422,
            detail="URL-ul PDF configurat pentru ediție nu este valid.",
        )

    try:
        with httpx.Client(timeout=45.0, follow_redirects=True) as client:
            response = client.get(
                pdf_url,
                headers={
                    "Accept": "application/pdf",
                    "User-Agent": "PULSE/1.0",
                },
            )
    except httpx.HTTPError as exc:
        logger.warning("Publication issue PDF download failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.",
        )

    content_type = response.headers.get("content-type", "").split(";")[0].strip().lower()
    if response.status_code != 200 or content_type != "application/pdf":
        raise HTTPException(
            status_code=502,
            detail="Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.",
        )

    return response.content


def extract_pdf_text(pdf_bytes: bytes, max_pages: int = 40, max_chars: int = 24000) -> str:
    try:
        reader = PdfReader(BytesIO(pdf_bytes))
        parts = []
        for page in reader.pages[:max_pages]:
            text = clean_ai_summary_text(page.extract_text() or "")
            if text:
                parts.append(text)
            if sum(len(part) for part in parts) >= max_chars:
                break
    except Exception:
        logger.exception("Publication issue PDF text extraction failed")
        raise HTTPException(
            status_code=422,
            detail="Textul PDF-ului nu a putut fi extras pentru rezumat.",
        )

    text = "\n\n".join(parts)
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        raise HTTPException(
            status_code=422,
            detail="PDF-ul nu conține suficient text pentru rezumat.",
        )
    return text[:max_chars]


def build_publication_issue_summary_input(issue: models.PublicationIssue, pdf_text: str):
    publication_name = clean_ai_summary_text(issue.publication.name if issue.publication else "")
    issue_label = clean_ai_summary_text(issue.issue_label)
    description = clean_ai_summary_text(issue.description)

    return "\n\n".join(
        part
        for part in [
            f"Publicație: {publication_name}" if publication_name else None,
            f"Ediție: {issue_label}" if issue_label else None,
            f"An: {issue.year}",
            f"Număr: {issue.issue_number}",
            f"Descriere: {description}" if description else None,
            f"Conținut extras din PDF: {pdf_text}",
        ]
        if part
    )


def public_content_ordering():
    return (
        models.ContentItem.is_featured.desc(),
        models.ContentItem.published_at.desc().nullslast(),
        models.ContentItem.created_at.desc().nullslast(),
    )


def serialize_content_card(item):
    data = {
        "id": item.id,
        "title": item.title,
        "slug": item.slug,
        "content_type": serialize_value(item.content_type),
        "short_description": item.short_description,
        "body": item.body,
        "thumbnail_url": item.thumbnail_url,
        "hero_image_url": item.hero_image_url,
        "category_id": item.category_id,
        "category_name": item.category.name if item.category else None,
        "specialization_id": item.specialization_id,
        "specialization_name": item.specialization.name if item.specialization else None,
        "published_at": serialize_value(item.published_at),
        "created_at": serialize_value(item.created_at),
        "is_featured": item.is_featured,
        "source_url": item.source_url,
        "author_name": item.author_name,
    }

    if item.event:
        data["event"] = {
            "start_date": serialize_value(item.event.start_date),
            "city_name": item.event.city.name if item.event.city else None,
            "venue_name": item.event.venue_name,
            "emc_credits": item.event.emc_credits,
            "event_page_url": item.event.event_page_url,
            "registration_url": item.event.registration_url,
        }
        data.update(
            {
                "start_date": data["event"]["start_date"],
                "city_name": data["event"]["city_name"],
                "venue_name": item.event.venue_name,
                "emc_credits": item.event.emc_credits,
            }
        )

    if item.course:
        data["course"] = {
            "emc_credits": item.course.emc_credits,
            "provider": item.course.provider,
            "valid_until": serialize_value(item.course.valid_until),
            "enrollment_url": item.course.enrollment_url,
        }
        data.update(
            {
                "emc_credits": item.course.emc_credits,
                "provider": item.course.provider,
                "valid_until": data["course"]["valid_until"],
            }
        )

    if item.publication:
        data["publication"] = {
            "id": item.publication.id,
            "publication_id": item.publication.id,
            "name": item.publication.name,
            "logo_url": item.publication.logo_url,
            "description": item.publication.description,
            "emc_credits_text": item.publication.emc_credits_text,
            "creditation_text": item.publication.creditation_text,
            "indexing_text": item.publication.indexing_text,
            "subscription_url": item.publication.subscription_url,
        }
        data.update(
            {
                "publication_id": item.publication.id,
                "publication_name": item.publication.name,
                "name": item.publication.name,
                "logo_url": item.publication.logo_url,
                "description": item.publication.description,
                "emc_credits_text": item.publication.emc_credits_text,
                "creditation_text": item.publication.creditation_text,
                "indexing_text": item.publication.indexing_text,
                "subscription_url": item.publication.subscription_url,
            }
        )

    return data


def serialize_publication_issue(issue: models.PublicationIssue, include_publication: bool = True):
    publication = issue.publication if include_publication else None
    return {
        "id": issue.id,
        "publication_id": issue.publication_id,
        "publication_name": publication.name if publication else None,
        "publication_logo_url": publication.logo_url if publication else None,
        "publication_description": publication.description if publication else None,
        "publication_emc_credits_text": publication.emc_credits_text if publication else None,
        "publication_creditation_text": publication.creditation_text if publication else None,
        "publication_indexing_text": publication.indexing_text if publication else None,
        "publication_subscription_url": publication.subscription_url if publication else None,
        "year": issue.year,
        "issue_number": issue.issue_number,
        "issue_label": issue.issue_label,
        "cover_image_url": issue.cover_image_url,
        "description": issue.description,
        "published_at": serialize_value(issue.published_at),
        "issue_url": issue.issue_url,
        "pdf_url": issue.issue_url,
        "document_url": issue.issue_url,
    }


def public_publication_query(db: Session):
    return (
        db.query(models.Publication)
        .join(models.ContentItem, models.ContentItem.id == models.Publication.content_item_id)
        .options(joinedload(models.Publication.content_item))
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
        .filter(models.ContentItem.content_type == models.ContentItemType.publication)
    )


def get_public_publication_or_404(db: Session, publication_id: int):
    publication = (
        public_publication_query(db)
        .filter(models.Publication.id == publication_id)
        .first()
    )
    if publication is None:
        raise HTTPException(status_code=404, detail="Publication not found")
    return publication


def public_publication_issue_query(db: Session):
    return (
        db.query(models.PublicationIssue)
        .join(models.Publication, models.Publication.id == models.PublicationIssue.publication_id)
        .join(models.ContentItem, models.ContentItem.id == models.Publication.content_item_id)
        .options(joinedload(models.PublicationIssue.publication))
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
        .filter(models.ContentItem.content_type == models.ContentItemType.publication)
    )


def get_public_publication_issue_or_404(db: Session, issue_id: int):
    issue = (
        public_publication_issue_query(db)
        .filter(models.PublicationIssue.id == issue_id)
        .first()
    )
    if issue is None:
        raise HTTPException(status_code=404, detail="Publication issue not found")
    return issue


def serialize_mapping(row):
    return {key: serialize_value(value) for key, value in dict(row).items()}


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
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = query.offset(skip).limit(limit).all()
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/content-items/{content_item_id}")
def get_content_item_detail(
    content_item_id: int,
    db: Session = Depends(get_db),
):
    item = get_public_content_item_or_404(db, content_item_id)
    data = serialize_model(item, include_relationships=True)
    card_data = serialize_content_card(item)
    for key, value in card_data.items():
        if data.get(key) is None:
            data[key] = value
    return data


@app.post("/content-items/{content_item_id}/ai-summary")
def generate_content_ai_summary(
    content_item_id: int,
    db: Session = Depends(get_db),
):
    item = get_public_content_item_or_404(db, content_item_id)
    if item.content_type not in {
        models.ContentItemType.article,
        models.ContentItemType.news,
    }:
        raise HTTPException(
            status_code=400,
            detail="Rezumatul AI este disponibil momentan doar pentru articole și știri.",
        )

    summary_input = build_ai_summary_input(item)
    payload, model = generate_ai_summary_payload(summary_input)

    return {
        "content_item_id": content_item_id,
        "summary": payload["summary"],
        "key_points": payload["key_points"],
        "disclaimer": AI_SUMMARY_DISCLAIMER,
        "model": model,
    }


@app.get("/featured-content")
def get_featured_content(
    limit: int = Query(default=10, le=50),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = (
            visible_content_card_query(db)
            .filter(models.ContentItem.is_featured == True)
        )
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
            )
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/articles")
def get_articles(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(models.ContentItem.content_type == models.ContentItemType.article)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(models.ContentItem.published_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_model(item, include_relationships=True) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/news")
def get_news(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(models.ContentItem.content_type == models.ContentItemType.news)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(*public_content_ordering())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/courses")
def get_courses(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(models.ContentItem.content_type == models.ContentItemType.course)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(*public_content_ordering())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/events")
def get_events(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(models.ContentItem.content_type == models.ContentItemType.event)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(*public_content_ordering())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/courses-events")
def get_courses_events(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(
            models.ContentItem.content_type.in_(
                [models.ContentItemType.course, models.ContentItemType.event]
            )
        )
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(*public_content_ordering())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/publications")
def get_publications(
    skip: int = 0,
    limit: int = Query(default=50, le=200),
    category_ids: Optional[List[int]] = Query(default=None),
    specialization_ids: Optional[List[int]] = Query(default=None),
    db: Session = Depends(get_db),
):
    try:
        query = visible_content_card_query(db).filter(models.ContentItem.content_type == models.ContentItemType.publication)
        query = apply_content_filters(query, category_ids, specialization_ids)
        items = (
            query
            .order_by(*public_content_ordering())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return [serialize_content_card(item) for item in items]
    except Exception as e:
        return {"error": str(e)}


@app.get("/publications/{publication_id}/issues")
def get_publication_issues_for_publication(
    publication_id: int,
    db: Session = Depends(get_db),
):
    get_public_publication_or_404(db, publication_id)
    issues = (
        db.query(models.PublicationIssue)
        .options(joinedload(models.PublicationIssue.publication))
        .filter(models.PublicationIssue.publication_id == publication_id)
        .order_by(
            models.PublicationIssue.year.desc(),
            models.PublicationIssue.issue_number.desc(),
        )
        .all()
    )
    return [serialize_publication_issue(issue) for issue in issues]


@app.get("/publication-issues/{issue_id}")
def get_publication_issue_detail(
    issue_id: int,
    db: Session = Depends(get_db),
):
    issue = get_public_publication_issue_or_404(db, issue_id)
    return serialize_publication_issue(issue)


@app.post("/publication-issues/{issue_id}/ai-summary")
def generate_publication_issue_ai_summary(
    issue_id: int,
    db: Session = Depends(get_db),
):
    issue = get_public_publication_issue_or_404(db, issue_id)
    pdf_bytes = download_publication_issue_pdf_bytes(issue)
    pdf_text = extract_pdf_text(pdf_bytes)
    summary_input = build_publication_issue_summary_input(issue, pdf_text)
    payload, model = generate_ai_summary_payload(summary_input)

    return {
        "publication_issue_id": issue_id,
        "summary": payload["summary"],
        "key_points": payload["key_points"],
        "disclaimer": AI_SUMMARY_DISCLAIMER,
        "model": model,
    }


def build_publication_issue_pdf_response(
    issue_id: int,
    range_header: Optional[str],
    db: Session,
    include_body: bool = True,
):
    issue = get_public_publication_issue_or_404(db, issue_id)
    pdf_url = (issue.issue_url or "").strip()

    if not pdf_url:
        raise HTTPException(
            status_code=404,
            detail="PDF-ul ediției nu este disponibil momentan.",
        )

    if not (pdf_url.startswith("http://") or pdf_url.startswith("https://")):
        raise HTTPException(
            status_code=422,
            detail="URL-ul PDF configurat pentru ediție nu este valid.",
        )

    request_headers = {
        "Accept": "application/pdf",
        "User-Agent": "PULSE/1.0",
    }
    if range_header:
        request_headers["Range"] = range_header

    try:
        with httpx.Client(timeout=30.0, follow_redirects=True) as client:
            if include_body:
                upstream = client.get(pdf_url, headers=request_headers)
            else:
                upstream = client.head(pdf_url, headers=request_headers)
    except httpx.HTTPError as exc:
        logger.warning("Publication issue PDF fetch failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.",
        )

    if upstream.status_code not in (200, 206):
        raise HTTPException(
            status_code=502,
            detail="Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.",
        )

    content_type = upstream.headers.get("content-type", "").split(";")[0].strip().lower()
    looks_like_pdf_url = pdf_url.split("?", 1)[0].lower().endswith(".pdf")
    if content_type != "application/pdf" and not looks_like_pdf_url:
        raise HTTPException(
            status_code=502,
            detail="Documentul nu a putut fi deschis. Verifică fișierul PDF sau încearcă din nou.",
        )

    response_headers = {
        "Cache-Control": "private, max-age=300",
        "Content-Disposition": f'inline; filename="publication-issue-{issue_id}.pdf"',
        "Accept-Ranges": upstream.headers.get("accept-ranges", "bytes"),
    }
    for source_name, target_name in (
        ("content-range", "Content-Range"),
        ("content-length", "Content-Length"),
        ("etag", "ETag"),
        ("last-modified", "Last-Modified"),
    ):
        value = upstream.headers.get(source_name)
        if value:
            response_headers[target_name] = value

    return Response(
        content=upstream.content if include_body else b"",
        status_code=upstream.status_code,
        media_type="application/pdf",
        headers=response_headers,
    )


@app.get("/publication-issues/{issue_id}/pdf")
def get_publication_issue_pdf(
    issue_id: int,
    range_header: Optional[str] = Header(default=None, alias="Range"),
    db: Session = Depends(get_db),
):
    return build_publication_issue_pdf_response(issue_id, range_header, db)


@app.head("/publication-issues/{issue_id}/pdf")
def head_publication_issue_pdf(
    issue_id: int,
    range_header: Optional[str] = Header(default=None, alias="Range"),
    db: Session = Depends(get_db),
):
    return build_publication_issue_pdf_response(
        issue_id,
        range_header,
        db,
        include_body=False,
    )


@app.get("/saved-content/ids")
def get_saved_content_ids(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_demo_user_id),
):
    rows = (
        db.query(models.SavedContent.content_item_id)
        .join(
            models.ContentItem,
            models.ContentItem.id == models.SavedContent.content_item_id,
        )
        .filter(models.SavedContent.user_id == user_id)
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
        .all()
    )
    return [row[0] for row in rows]


@app.get("/saved-content")
def get_saved_content(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_demo_user_id),
):
    saved_rows = (
        db.query(models.SavedContent)
        .join(
            models.ContentItem,
            models.ContentItem.id == models.SavedContent.content_item_id,
        )
        .filter(models.SavedContent.user_id == user_id)
        .filter(models.ContentItem.is_active == True)
        .filter(models.ContentItem.deleted_at.is_(None))
        .filter(models.ContentItem.status == models.ContentStatus.published)
        .order_by(models.SavedContent.saved_at.desc().nullslast())
        .all()
    )
    content_item_ids = [saved.content_item_id for saved in saved_rows]
    if not content_item_ids:
        return []

    content_items = (
        visible_content_card_query(db)
        .filter(models.ContentItem.id.in_(content_item_ids))
        .all()
    )
    content_by_id = {item.id: item for item in content_items}

    items = []
    for saved in saved_rows:
        item = content_by_id.get(saved.content_item_id)
        if item is None:
            continue
        data = serialize_content_card(item)
        data["is_saved"] = True
        data["saved_at"] = serialize_value(saved.saved_at)
        items.append(data)
    return items


@app.post("/saved-content/{content_item_id}")
def save_content(
    content_item_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_demo_user_id),
):
    get_public_content_item_or_404(db, content_item_id)
    ensure_demo_user_exists(db, user_id)

    existing = (
        db.query(models.SavedContent)
        .filter(models.SavedContent.user_id == user_id)
        .filter(models.SavedContent.content_item_id == content_item_id)
        .first()
    )
    if existing is None:
        db.add(
            models.SavedContent(
                user_id=user_id,
                content_item_id=content_item_id,
                saved_at=datetime.utcnow(),
            )
        )
        db.commit()

    return {
        "content_item_id": content_item_id,
        "is_saved": True,
        "message": "Content saved",
    }


@app.delete("/saved-content/{content_item_id}")
def remove_saved_content(
    content_item_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_demo_user_id),
):
    existing = (
        db.query(models.SavedContent)
        .filter(models.SavedContent.user_id == user_id)
        .filter(models.SavedContent.content_item_id == content_item_id)
        .first()
    )
    if existing is not None:
        db.delete(existing)
        db.commit()

    return {
        "content_item_id": content_item_id,
        "is_saved": False,
        "message": "Content removed from saved",
    }


@app.get("/ads")
def get_public_ads(
    placement: Optional[str] = None,
    limit: int = Query(default=3, ge=1, le=10),
    db: Session = Depends(get_db),
):
    try:
        query = text(
            """
            SELECT
                public_ads.id,
                public_ads.title,
                public_ads.description,
                public_ads.ad_type::text AS ad_type,
                public_ads.placement::text AS placement,
                public_ads.related_content_item_id,
                public_ads.related_content_type::text AS related_content_type,
                public_ads.related_content_slug,
                public_ads.related_content_title,
                public_ads.image_url,
                public_ads.mobile_image_url,
                public_ads.background_image_url,
                public_ads.sponsor_name,
                public_ads.sponsor_logo_url,
                public_ads.cta_label,
                public_ads.cta_url,
                public_ads.priority,
                public_ads.starts_at,
                public_ads.ends_at,
                public_ads.ad_design_template_id,
                public_ads.template_code,
                public_ads.template_name,
                public_ads.template_layout,
                public_ads.template_variant,
                public_ads.template_default_config,
                public_ads.design_config,
                ads.title_font_preset_id,
                COALESCE(selected_font.code, default_font.code) AS title_font_code,
                COALESCE(selected_font.font_key, default_font.font_key) AS title_font_key,
                COALESCE(selected_font.name, default_font.name) AS title_font_name,
                COALESCE(selected_font.flutter_font_family, default_font.flutter_font_family) AS title_flutter_font_family,
                public_ads.created_at,
                public_ads.updated_at
            FROM active_ads_public AS public_ads
            JOIN ads ON ads.id = public_ads.id
            LEFT JOIN ad_font_presets AS selected_font
                ON selected_font.id = ads.title_font_preset_id
                AND selected_font.is_active = TRUE
            LEFT JOIN LATERAL (
                SELECT code, font_key, name, flutter_font_family
                FROM ad_font_presets
                WHERE is_active = TRUE
                ORDER BY
                    CASE
                        WHEN code = 'default_pulse' THEN 0
                        WHEN font_key = 'default' THEN 1
                        ELSE 2
                    END,
                    id ASC,
                    name ASC
                LIMIT 1
            ) AS default_font ON TRUE
            WHERE (:placement IS NULL OR public_ads.placement::text = :placement)
            ORDER BY public_ads.priority DESC, public_ads.created_at DESC
            LIMIT :limit
            """
        )
        rows = db.execute(query, {"placement": placement, "limit": limit}).mappings().all()
        return [serialize_mapping(row) for row in rows]
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Nu s-au putut încărca reclamele publice din active_ads_public: {e}",
        ) from e


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

@app.post("/api/register")
def register_user(payload: UserCreate, db: Session = Depends(get_db)):
    user_model = get_user_model()
    existing_user = db.query(user_model).filter(user_model.email == payload.email).first()
    if existing_user is not None:
        raise HTTPException(status_code=409, detail="An account with this email already exists")

    if not payload.password or len(payload.password) < 8:
        raise HTTPException(status_code=422, detail="Password must have at least 8 characters")

    county_id = _resolve_county_id(db, payload)
    city_id = _resolve_city_id(db, payload, county_id)
    occupation_id = _resolve_occupation_id(db, payload)
    specialization_id = _resolve_specialization_id(db, payload)
    professional_grade_id = _resolve_professional_grade_id(db, payload)

    missing = []
    if not payload.first_name:
        missing.append("first_name")
    if not payload.last_name:
        missing.append("last_name")
    if not payload.cnp:
        missing.append("cnp")
    if not payload.phone:
        missing.append("phone")
    if city_id is None:
        missing.append("city")
    if occupation_id is None:
        missing.append("occupation")
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"Missing or invalid required fields: {','.join(missing)}",
        )

    now = datetime.utcnow()
    user = user_model(
        email=payload.email,
        password_hash=hash_password(payload.password),
        is_active=True,
        created_at=now,
        updated_at=now,
    )
    db.add(user)
    db.flush()

    profile_kwargs = {
        "user_id": user.id,
        "first_name": payload.first_name,
        "last_name": payload.last_name,
        "cnp": payload.cnp,
        "phone": payload.phone,
        "city_id": city_id,
        "occupation_id": occupation_id,
        "specialization_id": specialization_id,
        "professional_grade_id": professional_grade_id,
        "created_at": now,
        "updated_at": now,
    }
    optional_profile_fields = {
        "cod_parafa": payload.cod_parafa or payload.professional_registration_code,
        "cuim": payload.cuim,
        "titlu_universitar": payload.titlu_universitar or payload.professional_grade_name,
        "specialization_secondary_name": payload.specialization_secondary_name,
    }
    for field_name, value in optional_profile_fields.items():
        if hasattr(models.UserProfile, field_name):
            profile_kwargs[field_name] = value

    db.add(models.UserProfile(**profile_kwargs))
    db.commit()

    return {
        "message": "User registered successfully",
        "user_id": user.id,
    }


@app.post("/api/login")
def login_user(payload: UserLogin, db: Session = Depends(get_db)):
    user_model = get_user_model()
    session_model = get_user_session_model()

    user = db.query(user_model).filter(user_model.email == payload.email).first()
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    now = datetime.utcnow()
    session_token = create_session_token()
    db.add(
        session_model(
            user_id=user.id,
            refresh_token_hash=hashlib.sha256(session_token.encode("utf-8")).hexdigest(),
            created_at=now,
            expires_at=now + timedelta(days=30),
        )
    )
    user.last_login_at = now
    user.updated_at = now
    db.commit()

    return {
        "message": "Login successful",
        "user_id": user.id,
        "session_token": session_token,
    }


@app.post("/api/logout")
def logout_user(payload: UserLogout, db: Session = Depends(get_db)):
    session_model = get_user_session_model()
    session_hash = hashlib.sha256(payload.session_token.encode("utf-8")).hexdigest()

    session_record = (
        db.query(session_model)
        .filter(session_model.refresh_token_hash == session_hash)
        .filter(session_model.revoked_at.is_(None))
        .first()
    )
    if session_record is None:
        raise HTTPException(status_code=404, detail="Session not found")

    session_record.revoked_at = datetime.utcnow()
    db.commit()

    return {"message": "Logout successful"}


@app.get("/api/me/profile")
def get_my_profile(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user_model = get_user_model()
    user = db.query(user_model).filter(user_model.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    profile = (
        db.query(models.UserProfile)
        .filter(models.UserProfile.user_id == user_id)
        .options(
            joinedload(models.UserProfile.city).joinedload(models.City.county),
            joinedload(models.UserProfile.occupation),
            joinedload(models.UserProfile.specialization),
            joinedload(models.UserProfile.professional_grade),
        )
        .first()
    )
    if profile is None:
        raise HTTPException(status_code=404, detail="User profile not found")

    profile_data = serialize_model(profile, include_relationships=True)
    secondary_specialization = getattr(profile, "specialization_secondary_name", None)
    if secondary_specialization is not None:
        profile_data["specialization_secondary_name"] = secondary_specialization

    return {
        "user": serialize_model(user),
        "profile": profile_data,
        "display_name": f"{profile.first_name} {profile.last_name}".strip(),
        "email": user.email,
        "phone": profile.phone,
        "county_name": profile.city.county.name if getattr(profile.city, "county", None) else None,
        "city_name": profile.city.name if profile.city else None,
        "occupation_name": profile.occupation.name if profile.occupation else None,
        "specialization_name": profile.specialization.name if profile.specialization else None,
        "professional_grade_name": profile.professional_grade.name if profile.professional_grade else None,
    }


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
        issues = (
            public_publication_issue_query(db)
            .order_by(
                models.PublicationIssue.year.desc(),
                models.PublicationIssue.issue_number.desc(),
            )
            .all()
        )
        return [serialize_publication_issue(issue) for issue in issues]
    except Exception as e:
        return {"error": str(e)}


# -------------------------
# USER ACTIVITY
# -------------------------

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

from pydantic import BaseModel, ConfigDict, Field
from typing import Any, Dict, Optional, List
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


class PublicationIssueCreatePayload(BaseModel):
    year: int
    issue_number: int
    issue_label: Optional[str] = None
    cover_image_url: Optional[str] = None
    description: Optional[str] = None
    published_at: Optional[datetime] = None
    issue_url: Optional[str] = None


class PublicationIssueUpdatePayload(BaseModel):
    year: Optional[int] = None
    issue_number: Optional[int] = None
    issue_label: Optional[str] = None
    cover_image_url: Optional[str] = None
    description: Optional[str] = None
    published_at: Optional[datetime] = None
    issue_url: Optional[str] = None


class CourseAdminPayload(ContentItemBase):
    course: CourseDetailsPayload = Field(default_factory=CourseDetailsPayload)


class EventAdminPayload(ContentItemBase):
    event: EventDetailsPayload = Field(default_factory=EventDetailsPayload)


class PublicationAdminPayload(ContentItemBase):
    publication: PublicationDetailsPayload = Field(default_factory=PublicationDetailsPayload)


class AdDesignTemplateRead(BaseModel):
    id: int
    code: str
    name: str
    description: Optional[str] = None
    layout: str
    variant: str
    default_config: Dict[str, Any] = Field(default_factory=dict)
    preview_image_url: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class AdFontPresetRead(BaseModel):
    id: int
    code: str
    font_key: str
    name: str
    flutter_font_family: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class AdBase(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: Optional[str] = None
    description: Optional[str] = None
    ad_type: Optional[str] = None
    status: Optional[str] = None
    placement: Optional[str] = None
    ad_design_template_id: Optional[int] = None
    title_font_preset_id: Optional[int] = None
    design_config: Optional[Dict[str, Any]] = None
    related_content_item_id: Optional[int] = None
    image_url: Optional[str] = None
    mobile_image_url: Optional[str] = None
    background_image_url: Optional[str] = None
    sponsor_name: Optional[str] = None
    sponsor_logo_url: Optional[str] = None
    cta_label: Optional[str] = None
    cta_url: Optional[str] = None
    priority: Optional[int] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    is_active: Optional[bool] = None
    created_by_user_id: Optional[int] = None
    updated_by_user_id: Optional[int] = None


class AdCreate(AdBase):
    title: str
    ad_type: str = "other"
    status: str = "draft"
    placement: str = "home_between_sections"
    design_config: Dict[str, Any] = Field(default_factory=dict)
    priority: int = 0
    is_active: bool = True


class AdUpdate(AdBase):
    pass


class AdRead(AdBase):
    id: int
    ad_type: str
    status: str
    placement: str
    design_config: Dict[str, Any] = Field(default_factory=dict)
    priority: int
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None


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


def serialize_admin_specialized_content_item(item: models.ContentItem, child_attr: Optional[str] = None):
    data = serialize_model(item)
    if item.category:
        category_data = serialize_model(item.category)
        data["category"] = category_data
        data["category_name"] = category_data.get("name")
    if item.specialization:
        specialization_data = serialize_model(item.specialization)
        data["specialization"] = specialization_data
        data["specialization_name"] = specialization_data.get("name")

    if child_attr:
        child = getattr(item, child_attr, None)
        data[child_attr] = serialize_model(child, include_relationships=True) if child else None
    return data


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


def log_admin_action(method: str, path: str, target_id: int, payload=None, update_data=None):
    logger.warning(
        "admin_action method=%s path=%s target_id=%s payload=%s update_data=%s",
        method,
        path,
        target_id,
        payload,
        update_data,
    )


AD_FIELDS = [
    "title",
    "description",
    "ad_type",
    "status",
    "placement",
    "ad_design_template_id",
    "title_font_preset_id",
    "design_config",
    "related_content_item_id",
    "image_url",
    "mobile_image_url",
    "background_image_url",
    "sponsor_name",
    "sponsor_logo_url",
    "cta_label",
    "cta_url",
    "priority",
    "starts_at",
    "ends_at",
    "is_active",
    "created_by_user_id",
    "updated_by_user_id",
]

RELEVANT_AD_CONTENT_TYPES = {"publication", "event", "course", "article", "news"}


def ad_data(item: BaseModel, exclude_unset: bool = False):
    data = pydantic_dump(item, exclude_unset=exclude_unset)
    payload = {key: data[key] for key in AD_FIELDS if key in data}
    for nullable_actor_field in ("created_by_user_id", "updated_by_user_id"):
        if payload.get(nullable_actor_field) is None:
            payload.pop(nullable_actor_field, None)
    return payload


def normalize_ad_data(data: dict):
    normalized = dict(data)
    if "ad_type" in normalized:
        normalized["ad_type"] = enum_value(models.AdType, normalized["ad_type"], "ad_type")
    if "status" in normalized:
        normalized["status"] = enum_value(models.AdStatus, normalized["status"], "status")
    if "placement" in normalized:
        normalized["placement"] = enum_value(models.AdPlacement, normalized["placement"], "placement")
    if normalized.get("design_config") is None:
        normalized["design_config"] = {}
    return normalized


def enum_or_value(value):
    return serialize_value(value)


def serialize_ad_template(template: models.AdDesignTemplate):
    if not template:
        return None
    return serialize_model(template)


def serialize_ad_font_preset(font: models.AdFontPreset):
    if not font:
        return None
    return serialize_model(font)


def serialize_content_option(item: models.ContentItem):
    return {
        "id": item.id,
        "title": item.title,
        "content_type": serialize_value(item.content_type),
        "slug": item.slug,
        "status": serialize_value(item.status),
        "is_active": item.is_active,
        "published_at": serialize_value(item.published_at),
    }


def serialize_ad(ad: models.Ad):
    data = serialize_model(ad)
    template = serialize_ad_template(ad.template)
    title_font = serialize_ad_font_preset(ad.title_font)
    related_content = ad.related_content_item

    data["template"] = template
    data["template_name"] = template.get("name") if template else None
    data["template_code"] = template.get("code") if template else None
    data["title_font"] = title_font
    data["title_font_code"] = title_font.get("code") if title_font else None
    data["title_font_key"] = title_font.get("font_key") if title_font else None
    data["title_font_name"] = title_font.get("name") if title_font else None
    data["title_flutter_font_family"] = title_font.get("flutter_font_family") if title_font else None
    data["related_content_title"] = related_content.title if related_content else None
    data["related_content_type"] = serialize_value(related_content.content_type) if related_content else None
    data["related_content_slug"] = related_content.slug if related_content else None
    return data


def get_ad_or_404(db: Session, ad_id: int):
    ad = (
        db.query(models.Ad)
        .options(
            joinedload(models.Ad.template),
            joinedload(models.Ad.title_font),
            joinedload(models.Ad.related_content_item),
        )
        .filter(models.Ad.id == ad_id)
        .filter(models.Ad.deleted_at.is_(None))
        .first()
    )
    if not ad:
        raise HTTPException(status_code=404, detail="Reclamă negăsită")
    return ad


def validate_ad_dates(starts_at, ends_at):
    if starts_at and ends_at and starts_at > ends_at:
        raise HTTPException(status_code=400, detail="starts_at trebuie să fie înainte de ends_at")


def validate_ad_template(db: Session, template_id: Optional[int]):
    if template_id is None:
        return None
    template = db.query(models.AdDesignTemplate).filter(models.AdDesignTemplate.id == template_id).first()
    if not template:
        raise HTTPException(status_code=400, detail="ad_design_template_id nu există")
    return template


def validate_ad_font_preset(db: Session, font_preset_id: Optional[int]):
    if font_preset_id is None:
        return None
    font = (
        db.query(models.AdFontPreset)
        .filter(models.AdFontPreset.id == font_preset_id)
        .filter(models.AdFontPreset.is_active == True)
        .first()
    )
    if not font:
        raise HTTPException(status_code=400, detail="title_font_preset_id nu există")
    return font


def validate_related_content(db: Session, content_item_id: Optional[int], ad_type: str):
    if content_item_id is None:
        return None

    content_item = (
        db.query(models.ContentItem)
        .filter(models.ContentItem.id == content_item_id)
        .filter(models.ContentItem.deleted_at.is_(None))
        .first()
    )
    if not content_item:
        raise HTTPException(status_code=400, detail="related_content_item_id nu există")

    content_type = serialize_value(content_item.content_type)
    if ad_type != "other" and content_type != ad_type:
        raise HTTPException(
            status_code=400,
            detail=f"Content asociat incompatibil: reclama este '{ad_type}', content item este '{content_type}'",
        )
    return content_item


def validate_ad_target(status: str, ad_type: str, related_content_item_id: Optional[int], cta_url: Optional[str]):
    if status == "active" and ad_type != "other" and not related_content_item_id and not cta_url:
        raise HTTPException(
            status_code=400,
            detail="Pentru reclame active non-other este necesar related_content_item_id sau cta_url",
        )


def validate_ad_payload(db: Session, data: dict, existing_ad: Optional[models.Ad] = None):
    candidate = {}
    if existing_ad:
        for field in AD_FIELDS:
            candidate[field] = getattr(existing_ad, field)
    candidate.update(data)

    ad_type = enum_or_value(candidate.get("ad_type") or models.AdType.other)
    status = enum_or_value(candidate.get("status") or models.AdStatus.draft)
    starts_at = candidate.get("starts_at")
    ends_at = candidate.get("ends_at")
    related_content_item_id = candidate.get("related_content_item_id")
    cta_url = candidate.get("cta_url")

    validate_ad_dates(starts_at, ends_at)
    validate_ad_template(db, candidate.get("ad_design_template_id"))
    validate_ad_font_preset(db, candidate.get("title_font_preset_id"))
    validate_related_content(db, related_content_item_id, ad_type)
    validate_ad_target(status, ad_type, related_content_item_id, cta_url)


def apply_ad_data(db_ad: models.Ad, data: dict):
    for key, value in data.items():
        setattr(db_ad, key, value)


@app.get("/admin/ad-design-templates")
def admin_get_ad_design_templates(db: Session = Depends(get_db)):
    try:
        templates = (
            db.query(models.AdDesignTemplate)
            .filter(models.AdDesignTemplate.is_active == True)
            .order_by(models.AdDesignTemplate.id.asc(), models.AdDesignTemplate.code.asc(), models.AdDesignTemplate.name.asc())
            .all()
        )
        return [serialize_model(template) for template in templates]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/ad-font-presets")
def admin_get_ad_font_presets(db: Session = Depends(get_db)):
    try:
        presets = (
            db.query(models.AdFontPreset)
            .filter(models.AdFontPreset.is_active == True)
            .order_by(models.AdFontPreset.id.asc(), models.AdFontPreset.name.asc())
            .all()
        )
        return [serialize_model(preset) for preset in presets]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/content-options")
def admin_get_content_options(
    type: str = Query(default="all"),
    db: Session = Depends(get_db),
):
    requested_type = (type or "all").lower()
    allowed = RELEVANT_AD_CONTENT_TYPES | {"all"}
    if requested_type not in allowed:
        allowed_values = ", ".join(sorted(allowed))
        raise HTTPException(status_code=400, detail=f"type invalid. Valori acceptate: {allowed_values}")

    try:
        query = (
            db.query(models.ContentItem)
            .filter(models.ContentItem.deleted_at.is_(None))
            .filter(models.ContentItem.content_type.in_([models.ContentItemType(value) for value in RELEVANT_AD_CONTENT_TYPES]))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
        )
        if requested_type != "all":
            query = query.filter(models.ContentItem.content_type == models.ContentItemType(requested_type))

        return [serialize_content_option(item) for item in query.all()]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/ads")
def admin_get_ads(db: Session = Depends(get_db)):
    try:
        ads = (
            db.query(models.Ad)
            .options(
                joinedload(models.Ad.template),
                joinedload(models.Ad.title_font),
                joinedload(models.Ad.related_content_item),
            )
            .filter(models.Ad.deleted_at.is_(None))
            .order_by(models.Ad.created_at.desc().nullslast())
            .all()
        )
        return [serialize_ad(ad) for ad in ads]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/ads/{id}")
def admin_get_ad(id: int, db: Session = Depends(get_db)):
    try:
        ad = get_ad_or_404(db, id)
        return serialize_ad(ad)
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.post("/admin/ads")
def admin_create_ad(item: AdCreate, db: Session = Depends(get_db)):
    try:
        data = normalize_ad_data(ad_data(item))
        data.setdefault("status", models.AdStatus.draft)
        data.setdefault("placement", models.AdPlacement.home_between_sections)
        data.setdefault("priority", 0)
        data.setdefault("is_active", True)
        data.setdefault("design_config", {})

        validate_ad_payload(db, data)
        db_ad = models.Ad(**data)
        db.add(db_ad)
        db.commit()
        db.refresh(db_ad)
        return serialize_ad(db_ad)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.put("/admin/ads/{id}")
def admin_update_ad(id: int, item: AdUpdate, db: Session = Depends(get_db)):
    try:
        db_ad = get_ad_or_404(db, id)
        data = normalize_ad_data(ad_data(item, exclude_unset=True))
        validate_ad_payload(db, data, existing_ad=db_ad)
        log_admin_action("PUT", f"/admin/ads/{id}", id, pydantic_dump(item, exclude_unset=True), data)

        apply_ad_data(db_ad, data)
        db.commit()
        db.refresh(db_ad)
        return serialize_ad(db_ad)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.patch("/admin/ads/{id}/archive")
def admin_archive_ad(id: int, db: Session = Depends(get_db)):
    try:
        db_ad = get_ad_or_404(db, id)
        log_admin_action(
            "PATCH",
            f"/admin/ads/{id}/archive",
            id,
            payload={},
            update_data={"status": "archived", "is_active": False},
        )
        db_ad.status = models.AdStatus.archived
        db_ad.is_active = False
        db.commit()
        db.refresh(db_ad)
        return serialize_ad(db_ad)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.delete("/admin/ads/{id}")
def admin_delete_ad(id: int, db: Session = Depends(get_db)):
    try:
        db_ad = get_ad_or_404(db, id)
        log_admin_action(
            "DELETE",
            f"/admin/ads/{id}",
            id,
            payload=None,
            update_data={"delete": "hard_delete_ads_only"},
        )
        db.delete(db_ad)
        db.commit()
        return {"success": True, "message": "Ad deleted permanently"}
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e

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


@app.get("/admin/articles")
def admin_get_articles(db: Session = Depends(get_db)):
    try:
        items = (
            db.query(models.ContentItem)
            .options(
                joinedload(models.ContentItem.category),
                joinedload(models.ContentItem.specialization),
            )
            .filter(models.ContentItem.content_type == models.ContentItemType.article)
            .filter(models.ContentItem.deleted_at.is_(None))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
            .all()
        )
        return [serialize_admin_specialized_content_item(item) for item in items]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/news")
def admin_get_news(db: Session = Depends(get_db)):
    try:
        items = (
            db.query(models.ContentItem)
            .options(
                joinedload(models.ContentItem.category),
                joinedload(models.ContentItem.specialization),
            )
            .filter(models.ContentItem.content_type == models.ContentItemType.news)
            .filter(models.ContentItem.deleted_at.is_(None))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
            .all()
        )
        return [serialize_admin_specialized_content_item(item) for item in items]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


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
        log_admin_action("PUT", f"/admin/content-items/{id}", id, pydantic_dump(item, exclude_unset=True), update_data)

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
        log_admin_action(
            "PATCH",
            f"/admin/content-items/{id}/archive",
            id,
            payload={},
            update_data={"status": "archived", "is_active": False},
        )
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
        log_admin_action("DELETE", f"/admin/content-items/{id}", id, payload=None, update_data={"delete": "content_items only"})
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
    logger.warning(
        "child_update model=Course child_id=%s content_item_id=%s update_data=%s",
        db_course.id,
        db_course.content_item_id,
        data,
    )
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
    logger.warning(
        "child_update model=Event child_id=%s content_item_id=%s update_data=%s",
        db_event.id,
        db_event.content_item_id,
        data,
    )
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
    logger.warning(
        "child_update model=Publication child_id=%s content_item_id=%s update_data=%s",
        db_publication.id,
        db_publication.content_item_id,
        data,
    )
    for key, value in data.items():
        setattr(db_publication, key, value)


def get_admin_publication_or_404(db: Session, publication_id: int):
    publication = (
        db.query(models.Publication)
        .options(joinedload(models.Publication.content_item))
        .filter(models.Publication.id == publication_id)
        .first()
    )
    if publication is None:
        raise HTTPException(status_code=404, detail="Publicația nu a fost găsită")
    return publication


def get_admin_publication_issue_or_404(db: Session, issue_id: int):
    issue = (
        db.query(models.PublicationIssue)
        .options(joinedload(models.PublicationIssue.publication))
        .filter(models.PublicationIssue.id == issue_id)
        .first()
    )
    if issue is None:
        raise HTTPException(status_code=404, detail="Ediția nu a fost găsită")
    return issue


def validate_publication_issue_values(year: Optional[int], issue_number: Optional[int]):
    if year is None or issue_number is None:
        raise HTTPException(status_code=400, detail="Anul și numărul ediției sunt obligatorii")
    if year < 1900 or year > 2100:
        raise HTTPException(status_code=400, detail="Anul ediției este invalid")
    if issue_number < 1:
        raise HTTPException(status_code=400, detail="Numărul ediției trebuie să fie pozitiv")


def validate_publication_issue_url(issue_url: Optional[str]):
    if issue_url in (None, ""):
        return
    if not (issue_url.startswith("http://") or issue_url.startswith("https://")):
        raise HTTPException(
            status_code=400,
            detail="URL ediție / PDF trebuie să înceapă cu http:// sau https://",
        )


def ensure_publication_issue_unique(
    db: Session,
    publication_id: int,
    year: int,
    issue_number: int,
    exclude_issue_id: Optional[int] = None,
):
    query = (
        db.query(models.PublicationIssue)
        .filter(models.PublicationIssue.publication_id == publication_id)
        .filter(models.PublicationIssue.year == year)
        .filter(models.PublicationIssue.issue_number == issue_number)
    )
    if exclude_issue_id is not None:
        query = query.filter(models.PublicationIssue.id != exclude_issue_id)
    if query.first() is not None:
        raise HTTPException(
            status_code=400,
            detail="Există deja o ediție pentru această publicație, an și număr",
        )


def publication_issue_data(payload: BaseModel, exclude_unset: bool = False):
    data = pydantic_dump(payload, exclude_unset=exclude_unset)
    allowed = {
        "year",
        "issue_number",
        "issue_label",
        "cover_image_url",
        "description",
        "published_at",
        "issue_url",
    }
    result = {key: value for key, value in data.items() if key in allowed}
    if "issue_url" in result and isinstance(result["issue_url"], str):
        result["issue_url"] = result["issue_url"].strip() or None
    validate_publication_issue_url(result.get("issue_url"))
    return result


@app.get("/admin/events")
def admin_get_events(db: Session = Depends(get_db)):
    try:
        items = (
            db.query(models.ContentItem)
            .options(
                joinedload(models.ContentItem.category),
                joinedload(models.ContentItem.specialization),
                joinedload(models.ContentItem.event).joinedload(models.Event.city),
            )
            .filter(models.ContentItem.content_type == models.ContentItemType.event)
            .filter(models.ContentItem.deleted_at.is_(None))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
            .all()
        )
        return [serialize_admin_specialized_content_item(item, "event") for item in items]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


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
        log_admin_action(
            "PUT",
            f"/admin/events/{content_item_id}",
            content_item_id,
            pydantic_dump(item, exclude_unset=True),
        )
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
    try:
        items = (
            db.query(models.ContentItem)
            .options(
                joinedload(models.ContentItem.category),
                joinedload(models.ContentItem.specialization),
                joinedload(models.ContentItem.course),
            )
            .filter(models.ContentItem.content_type == models.ContentItemType.course)
            .filter(models.ContentItem.deleted_at.is_(None))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
            .all()
        )
        return [serialize_admin_specialized_content_item(item, "course") for item in items]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


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
        log_admin_action(
            "PUT",
            f"/admin/courses/{content_item_id}",
            content_item_id,
            pydantic_dump(item, exclude_unset=True),
        )
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
    try:
        items = (
            db.query(models.ContentItem)
            .options(
                joinedload(models.ContentItem.category),
                joinedload(models.ContentItem.specialization),
                joinedload(models.ContentItem.publication),
            )
            .filter(models.ContentItem.content_type == models.ContentItemType.publication)
            .filter(models.ContentItem.deleted_at.is_(None))
            .order_by(
                models.ContentItem.published_at.desc().nullslast(),
                models.ContentItem.created_at.desc().nullslast(),
                models.ContentItem.title.asc(),
            )
            .all()
        )
        return [serialize_admin_specialized_content_item(item, "publication") for item in items]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.get("/admin/publications/{publication_id}/issues")
def admin_get_publication_issues(publication_id: int, db: Session = Depends(get_db)):
    try:
        get_admin_publication_or_404(db, publication_id)
        issues = (
            db.query(models.PublicationIssue)
            .options(joinedload(models.PublicationIssue.publication))
            .filter(models.PublicationIssue.publication_id == publication_id)
            .order_by(
                models.PublicationIssue.year.desc(),
                models.PublicationIssue.issue_number.desc(),
            )
            .all()
        )
        return [serialize_publication_issue(issue) for issue in issues]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.post("/admin/publications/{publication_id}/issues")
def admin_create_publication_issue(
    publication_id: int,
    item: PublicationIssueCreatePayload,
    db: Session = Depends(get_db),
):
    try:
        get_admin_publication_or_404(db, publication_id)
        validate_publication_issue_values(item.year, item.issue_number)
        ensure_publication_issue_unique(db, publication_id, item.year, item.issue_number)
        db_issue = models.PublicationIssue(
            publication_id=publication_id,
            **publication_issue_data(item),
        )
        db.add(db_issue)
        db.commit()
        db.refresh(db_issue)
        return serialize_publication_issue(db_issue)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


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


@app.put("/admin/publication-issues/{issue_id}")
def admin_update_publication_issue(
    issue_id: int,
    item: PublicationIssueUpdatePayload,
    db: Session = Depends(get_db),
):
    try:
        db_issue = get_admin_publication_issue_or_404(db, issue_id)
        data = publication_issue_data(item, exclude_unset=True)
        candidate_year = data.get("year", db_issue.year)
        candidate_issue_number = data.get("issue_number", db_issue.issue_number)
        validate_publication_issue_values(candidate_year, candidate_issue_number)
        ensure_publication_issue_unique(
            db,
            db_issue.publication_id,
            candidate_year,
            candidate_issue_number,
            exclude_issue_id=issue_id,
        )
        for key, value in data.items():
            setattr(db_issue, key, value)
        db.commit()
        db.refresh(db_issue)
        return serialize_publication_issue(db_issue)
    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e)) from e


@app.delete("/admin/publication-issues/{issue_id}")
def admin_delete_publication_issue(issue_id: int, db: Session = Depends(get_db)):
    try:
        db_issue = get_admin_publication_issue_or_404(db, issue_id)
        db.delete(db_issue)
        db.commit()
        return {"success": True, "message": "Ediția a fost ștearsă"}
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
        log_admin_action(
            "PUT",
            f"/admin/publications/{content_item_id}",
            content_item_id,
            pydantic_dump(item, exclude_unset=True),
        )
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
