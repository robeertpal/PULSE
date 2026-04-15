import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Reîncărcăm variabilele de mediu
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./pulse.db")

# Engine options by backend type.
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}
elif "postgresql" in DATABASE_URL:
    # sslmode=require is typical for Azure PostgreSQL
    connect_args = {"sslmode": "require"}

engine = create_engine(
    DATABASE_URL, 
    connect_args=connect_args,
    pool_pre_ping=True, # Verifică conexiunea înainte de utilizare
    pool_recycle=3600
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependență pentru a obține sesiunea DB în endpoint-uri
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
