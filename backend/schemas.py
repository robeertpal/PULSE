from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


class UserCreate(BaseModel):
    email: EmailStr
    firebase_uid: Optional[str] = Field(default=None, max_length=128)
    password: str = Field(min_length=8, max_length=128)

    first_name: str = Field(min_length=1, max_length=255)
    last_name: str = Field(min_length=1, max_length=255)
    cnp: str = Field(min_length=1, max_length=13)
    phone: str = Field(min_length=1, max_length=50)
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
    titlu_universitar: Optional[str] = Field(default=None, max_length=255)
    cuim: Optional[str] = Field(default=None, max_length=255)
    cod_parafa: Optional[str] = Field(default=None, max_length=255)
    professional_registration_code: Optional[str] = Field(default=None, max_length=255)
    sectia: Optional[str] = Field(default=None, max_length=255)

    acord_email: bool = False
    acord_sms: bool = False

    @field_validator(
        "first_name",
        "last_name",
        "cnp",
        "phone",
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


class AdminLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
