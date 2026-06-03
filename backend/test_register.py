from database import SessionLocal
import models
from main import pay_and_register_for_event, EventPaymentRegisterPayload

db = SessionLocal()
try:
    payload = EventPaymentRegisterPayload(payment_method_id=1) # guessing payment method id
    # wait, if I run this it will commit to db!
    # I can just rollback.
    user_id = 1
    event_id = 3
    pay_and_register_for_event(event_id=event_id, payload=payload, db=db, user_id=user_id)
except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    db.rollback()
