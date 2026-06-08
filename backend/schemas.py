from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


def normalize_email_value(value):
    if isinstance(value, str):
        return value.strip().lower()
    return value


class UserCreate(BaseModel):
    email: str = Field(min_length=1, max_length=255)
    firebase_uid: Optional[str] = Field(default=None, max_length=128)
    password: str = Field(min_length=8, max_length=128)

    first_name: str = Field(max_length=255)
    last_name: str = Field(max_length=255)
    cnp: str = Field(max_length=32)
    phone: str = Field(max_length=50)
    correspondence_address: Optional[str] = Field(default=None, max_length=1000)
    city_id: Optional[int] = Field(default=None, gt=0)
    county_id: Optional[int] = Field(default=None, gt=0)
    city_name: Optional[str] = Field(default=None, max_length=255)
    county_name: Optional[str] = Field(default=None, max_length=255)
    occupation_id: Optional[int] = Field(default=None, gt=0)
    occupation_name: Optional[str] = Field(default=None, max_length=255)
    specialization_id: Optional[int] = Field(default=None, gt=0)
    specialization_name: Optional[str] = Field(default=None, max_length=255)
    specialization_secondary_name: Optional[str] = Field(default=None, max_length=255)

    professional_grade_id: Optional[int] = Field(default=None, gt=0)
    professional_grade_name: Optional[str] = Field(default=None, max_length=255)
    institution_id: Optional[int] = Field(default=None, gt=0)
    titlu_universitar: Optional[str] = Field(default=None, max_length=255)
    cuim: Optional[str] = Field(default=None, max_length=255)
    cod_parafa: Optional[str] = Field(default=None, max_length=255)
    professional_registration_code: Optional[str] = Field(default=None, max_length=255)
    sectia: Optional[str] = Field(default=None, max_length=255)
    interest_ids: List[int] = Field(default_factory=list)

    acord_email: bool = False
    acord_sms: bool = False
    gdpr_consent: bool = False

    @field_validator(
        "first_name",
        "last_name",
        "cnp",
        "phone",
        "correspondence_address",
        "city_name",
        "county_name",
        "occupation_name",
        "specialization_name",
        "specialization_secondary_name",
        "professional_grade_name",
        "titlu_universitar",
        "cuim",
        "cod_parafa",
        "professional_registration_code",
        "sectia",
        mode="before",
    )
    @classmethod
    def strip_text(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value

    @field_validator("email", mode="before")
    @classmethod
    def strip_email(cls, value):
        return normalize_email_value(value)


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)


class UserInterestsUpdate(BaseModel):
    interest_ids: List[int] = Field(default_factory=list)


class UserLogout(BaseModel):
    session_token: str = Field(min_length=16, max_length=512)


class UserInterestsUpdate(BaseModel):
    interest_ids: List[int] = Field(default_factory=list)


class UserActivityCreate(BaseModel):
    action_type: str = Field(min_length=1, max_length=100)
    content_item_id: Optional[int] = Field(default=None, gt=0)
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class FollowTargetPayload(BaseModel):
    target_type: str = Field(min_length=1, max_length=50)
    target_id: int = Field(gt=0)


CONTENT_SUBMISSION_TYPES = {"article", "news", "course", "event"}


class ContentSubmissionBase(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    content_type: Optional[str] = Field(default=None, min_length=1, max_length=50)
    category_id: Optional[int] = Field(default=None, gt=0)
    specialization_id: Optional[int] = Field(default=None, gt=0)
    summary: Optional[str] = Field(default=None, max_length=2000)
    body: Optional[str] = Field(default=None, min_length=1)
    image_url: Optional[str] = Field(default=None, max_length=2000)
    source_url: Optional[str] = Field(default=None, max_length=2000)

    @field_validator("title", "content_type", "summary", "body", "image_url", "source_url", mode="before")
    @classmethod
    def strip_submission_text(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value

    @field_validator("content_type")
    @classmethod
    def validate_submission_type(cls, value):
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in CONTENT_SUBMISSION_TYPES:
            allowed = ", ".join(sorted(CONTENT_SUBMISSION_TYPES))
            raise ValueError(f"content_type invalid. Valori acceptate: {allowed}")
        return normalized

    @field_validator("image_url", "source_url")
    @classmethod
    def validate_submission_url(cls, value):
        if value is None or value == "":
            return None
        if not (value.startswith("http://") or value.startswith("https://")):
            raise ValueError("URL-ul trebuie sa inceapa cu http:// sau https://")
        return value


class ContentSubmissionCreate(ContentSubmissionBase):
    title: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=50)
    body: str = Field(min_length=1)


class ContentSubmissionUpdate(ContentSubmissionBase):
    pass


class ContentSubmissionReviewPayload(BaseModel):
    review_notes: Optional[str] = Field(default=None, max_length=4000)

    @field_validator("review_notes", mode="before")
    @classmethod
    def strip_review_notes(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class ContentReportCreate(BaseModel):
    reason: str = Field(min_length=1, max_length=50)
    details: Optional[str] = Field(default=None, max_length=4000)

    @field_validator("reason", "details", mode="before")
    @classmethod
    def strip_report_text(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class ContentReportUpdate(BaseModel):
    status: str = Field(min_length=1, max_length=30)
    admin_note: Optional[str] = Field(default=None, max_length=4000)

    @field_validator("status", "admin_note", mode="before")
    @classmethod
    def strip_update_text(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class EmailVerificationVerify(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)

    @field_validator("otp_code", mode="before")
    @classmethod
    def strip_otp_code(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class EmailVerificationResend(BaseModel):
    email: EmailStr

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)


class PasswordResetRequest(BaseModel):
    email: EmailStr

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)


class PasswordResetVerify(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)

    @field_validator("otp_code", mode="before")
    @classmethod
    def strip_otp_code(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return normalize_email_value(value)

    @field_validator("otp_code", mode="before")
    @classmethod
    def strip_otp_code(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class AdminLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
