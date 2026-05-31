from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


class UserCreate(BaseModel):
    email: EmailStr
    firebase_uid: Optional[str] = Field(default=None, max_length=128)
    password: str = Field(min_length=8, max_length=128)

    first_name: str = Field(min_length=1, max_length=255)
    last_name: str = Field(min_length=1, max_length=255)
    cnp: str = Field(min_length=1, max_length=13)
    phone: str = Field(min_length=1, max_length=50)
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


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserLogout(BaseModel):
    session_token: str = Field(min_length=16, max_length=512)


class UserInterestsUpdate(BaseModel):
    interest_ids: List[int] = Field(default_factory=list)


class UserActivityCreate(BaseModel):
    action_type: str = Field(min_length=1, max_length=100)
    content_item_id: Optional[int] = Field(default=None, gt=0)
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class EmailVerificationVerify(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)

    @field_validator("otp_code", mode="before")
    @classmethod
    def strip_otp_code(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class EmailVerificationResend(BaseModel):
    email: EmailStr


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetVerify(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)

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

    @field_validator("otp_code", mode="before")
    @classmethod
    def strip_otp_code(cls, value):
        if isinstance(value, str):
            return value.strip()
        return value


class AdminLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
