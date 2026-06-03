from database import SessionLocal
import models
from main import get_my_payments
from fastapi.encoders import jsonable_encoder

db = SessionLocal()
try:
    users = db.query(models.User).all()
    for user in users:
        res = get_my_payments(user_id=user.id, db=db)
        encoded = jsonable_encoder(res)
    print("Success")
except Exception as e:
    import traceback
    traceback.print_exc()
