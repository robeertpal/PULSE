from pydantic import BaseModel


class UserCreate(BaseModel):
    email: str
    firebase_uid: str

    first_name: str
    last_name: str
    cnp: str
    phone: str
    cuim: str
    cod_parafa: str
    titlu_universitar: str

    city_id: int
    occupation_id: int
    specialization_id: int
    sectia: str = ""
    occupation_name: str = ""

    acord_email: bool = False
    acord_sms: bool = False


class UserLogin(BaseModel):
    firebase_uid: str
    email: str
