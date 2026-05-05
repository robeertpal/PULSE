from typing import Optional

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    firebase_uid: Optional[str] = None
    password: str

    first_name: str
    last_name: str
    cnp: str
    phone: str
    city_id: Optional[int] = None
    county_id: Optional[int] = None
    city_name: Optional[str] = None
    county_name: Optional[str] = None
    occupation_id: Optional[int] = None
    occupation_name: Optional[str] = None
    specialization_id: Optional[int] = None
    specialization_name: Optional[str] = None
    specialization_secondary_name: Optional[str] = None

    professional_grade_id: Optional[int] = None
    professional_grade_name: Optional[str] = None
    titlu_universitar: Optional[str] = None
    cuim: Optional[str] = None
    cod_parafa: Optional[str] = None
    professional_registration_code: Optional[str] = None
    sectia: Optional[str] = None

    acord_email: bool = False
    acord_sms: bool = False


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserLogout(BaseModel):
    session_token: str
