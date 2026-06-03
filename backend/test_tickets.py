import sys
from database import SessionLocal
import models
from sqlalchemy.orm import joinedload

db = SessionLocal()
try:
    user_id = 1
    rows = (
        db.query(models.UserEventRegistration, models.Event)
        .join(models.Event, models.UserEventRegistration.event_id == models.Event.id)
        .options(
            joinedload(models.Event.content_item),
            joinedload(models.Event.city)
        )
        .filter(
            models.UserEventRegistration.user_id == user_id,
            models.UserEventRegistration.ticket_code.isnot(None)
        )
        .order_by(models.UserEventRegistration.registered_at.desc())
        .all()
    )
    print("Tickets:")
    for reg, event in rows:
        print(reg.ticket_code, event.content_item.title)
except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    db.close()
