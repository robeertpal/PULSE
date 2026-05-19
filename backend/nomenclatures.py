from __future__ import annotations

from typing import Iterable, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

import models


OCCUPATIONS = [
    "Medic",
    "Medic Rezident",
    "Student",
    "Farmacist",
    "Asistent",
    "Medic Veterinar",
    "Psiholog",
    "Nutritionist-Dietetician",
    "Stomatolog",
    "Pensionar",
    "Alta ocupatie",
]


# Titluri universitare (folosite pentru câmpul `titlu_universitar`, dependente de ocupație)
ACADEMIC_TITLES = [
    "Fără titlu universitar",
    "Asistent universitar",
    "Preparator universitar",
    "Șef de lucrări",
    "Conferențiar",
    "Profesor universitar",
    "Altul",
]

# Grad profesional (apare pentru TOATE ocupațiile - opțiunile din poze)
PROFESSIONAL_GRADES = [
    'Asistent de Farmacie',
    'Asistent Medical',
    'Asistent Veterinar',
    'Biolog',
    'Cercetător Științific',
    'Conferențiar Universitar',
    'Director',
    'Director Adjunct',
    'Director General',
    'Director Medical',
    'Doctor in Medicina',
    'Doctor in stiinte medicale',
    'Farmacist',
    'Farmacist Diriginte',
    'Farmacist pensionar',
    'Farmacist Primar',
    'Farmacist Sef',
    'Farmacist Specialist',
    'Farmacolog',
    'Grad profesional',
    'Inspector',
    'Medic Pensionar',
    'Medic Primar',
    'Medic Rezident',
    'Medic Specialist',
    'Medic Stagiar',
    'Medic veterinar',
    'Sef Sectie',
    'Sef Clinica',
    'Sef Depozit',
    'Sef Laborator',
    'Sef Lucrari',
    'Sef Policlinica',
]


MEDICAL_SPECIALIZATIONS = [
    "Medicină de familie",
    "Boli infecțioase",
    "Alergologie",
    "Anatomie patologica",
    "Anestezie si terapie intensiva",
    "Balneofizioterapie",
    "Cardiologie",
    "Chirurgie cardiovasculara",
    "Chirurgie generala",
    "Chirurgie pediatrica",
    "Chirurgie maxilofaciala",
    "Chirurgie plastica",
    "Chirurgie toracica",
    "Chirurgie vasculara",
    "Dermato-venerologie",
    "Diabetologie/Nutritie si Boli Metabolice",
    "Ecografie",
    "Endocrinologie",
    "Epidemiologie",
    "Expertiza medicala",
    "Farmacologie Clinica",
    "Fiziokinetoterapie/Recuperare medicala",
    "Gastroenterologie",
    "Genetica medicala",
    "Geriatrie si gerontologie",
    "Hematologie",
    "Homeopatie",
    "Igiena si sanatate publica",
    "Imunologie clinica",
    "Medicina de familie",
    "Medicina de intreprindere",
    "Medicina de laborator",
    "Medicina de urgenta",
    "Medicina fizica si de reabilitare",
    "Medicina generala",
    "Medicina interna",
    "Medicina legala",
    "Medicina muncii",
    "Medicina nucleara",
    "Medicina scolara",
    "Medicina sportiva",
    "Medicina veterinara",
    "Nefrologie",
    "Neonatologie",
    "Neurochirurgie",
    "Neurologie",
    "Neurologie pediatrica",
    "Obstetrica-Ginecologie",
    "Oftalmologie",
    "Oncologie",
    "ORL",
    "Ortopedie pediatrica",
    "Ortopedie si traumatologie",
    "Pediatrie",
    "Planificare Familiala",
    "Pneumologie",
    "Psihiatrie",
    "Psihiatrie pediatrica",
    "Psihologie medicala",
    "Radiologie si imagistica medicala",
    "Radioterapie",
    "Reumatologie",
    "Sanatate publica",
    "Stomatologie",
    "Urologie",
]


SPECIALIZATION_GROUPS = {
    # For general 'medic' we exclude veterinary and stomatology to be stricter
    "medic": [s for s in MEDICAL_SPECIALIZATIONS if s.lower() not in ("medicina veterinara", "stomatologie")],
    "medic rezident": [s for s in MEDICAL_SPECIALIZATIONS if s.lower() not in ("medicina veterinara", "stomatologie")],
    "student": MEDICAL_SPECIALIZATIONS,
    "farmacist": ["Farmacie", "Farmacologie Clinica", "Homeopatie"],
    "asistent": ["Asistent medical", "Asistent de farmacie", "Fiziokinetoterapie/Recuperare medicala"],
    "medic veterinar": ["Medicina veterinara"],
    "psiholog": ["Psihologie medicala"],
    "nutritionist-dietetician": [
        "Diabetologie/Nutritie si Boli Metabolice",
        "Sanatate publica",
    ],
    "stomatolog": ["Stomatologie", "Chirurgie maxilofaciala"],
}


ALL_SPECIALIZATIONS = list(
    dict.fromkeys(
        MEDICAL_SPECIALIZATIONS
        + ["Farmacie", "Asistent medical", "Asistent de farmacie", "Psihologie medicala", "Stomatologie"]
    )
)


def normalize_key(value: Optional[str]) -> str:
    if value is None:
        return ""
    return " ".join(value.strip().lower().split())


def _ensure_rows(db: Session, model, names: Iterable[str]) -> None:
    existing = {
        row[0]
        for row in db.query(model.name)
        .filter(model.name.in_(list(names)))
        .all()
    }
    missing = [name for name in names if name not in existing]
    for name in missing:
        db.add(model(name=name))


def _reset_sequence(db: Session, table_name: str) -> None:
    db.execute(
        text(
            f"""
            SELECT setval(
                pg_get_serial_sequence('{table_name}', 'id'),
                COALESCE((SELECT MAX(id) FROM {table_name}), 0),
                true
            )
            """
        )
    )


def ensure_user_profile_columns(db: Session) -> None:
    statements = [
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS cuim VARCHAR(255)",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS cod_parafa VARCHAR(255)",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS professional_registration_code VARCHAR(255)",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS titlu_universitar VARCHAR(255)",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS specialization_secondary_name VARCHAR(255)",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS correspondence_address TEXT",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS institution_id INTEGER",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS acord_email BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS acord_sms BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS gdpr_consent BOOLEAN NOT NULL DEFAULT FALSE",
    ]
    for statement in statements:
        db.execute(text(statement))
    db.commit()


def seed_nomenclatures(db: Session) -> None:
    _reset_sequence(db, "occupations")
    _reset_sequence(db, "professional_grades")
    _reset_sequence(db, "specializations")
    _ensure_rows(db, models.Occupation, OCCUPATIONS)
    _ensure_rows(db, models.ProfessionalGrade, PROFESSIONAL_GRADES)
    _ensure_rows(db, models.Specialization, ALL_SPECIALIZATIONS)
    db.commit()


def allowed_specializations_for_occupation_name(occupation_name: Optional[str]) -> list[str]:
    key = normalize_key(occupation_name)
    if not key:
        return list(MEDICAL_SPECIALIZATIONS)
    return list(SPECIALIZATION_GROUPS.get(key, MEDICAL_SPECIALIZATIONS))
