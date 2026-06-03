import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import models

engine = create_engine('sqlite:///./pulse.db') # Assuming sqlite, I'll check first. Wait, let's just see database.py
