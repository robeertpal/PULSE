from database import SessionLocal
import models
from sqlalchemy.orm import joinedload

db = SessionLocal()
try:
    users = db.query(models.User).all()
    for user in users:
        rows = (
            db.query(
                models.Payment,
                models.Event.id.label("event_id"),
                models.UserEventRegistration.status.label("registration_status"),
                models.UserEventRegistration.ticket_code
            )
            .options(
                joinedload(models.Payment.payment_method),
                joinedload(models.Payment.content_item)
            )
            .outerjoin(models.Event, models.Event.content_item_id == models.Payment.content_item_id)
            .outerjoin(
                models.UserEventRegistration,
                (models.UserEventRegistration.event_id == models.Event.id) &
                (models.UserEventRegistration.user_id == user.id)
            )
            .filter(models.Payment.user_id == user.id)
            .order_by(
                models.Payment.paid_at.desc().nullslast(),
                models.Payment.created_at.desc()
            )
            .all()
        )
        for row, event_id, reg_status, ticket_code in rows:
            data = {
                "id": row.id,
                "amount": float(row.amount) if row.amount is not None else 0.0,
                "currency": row.currency,
                "provider": row.provider,
                "provider_transaction_id": row.provider_transaction_id,
                "status": row.status.value if row.status else None,
                "paid_at": row.paid_at,
                "created_at": row.created_at,
                "subscription_id": row.subscription_id,
                "payment_method_id": row.payment_method_id,
                "content_item_id": row.content_item_id,
                "content_title": row.content_item.title if row.content_item else None,
                "content_type": row.content_item.content_type.value if row.content_item and row.content_item.content_type else None,
                "event_id": event_id,
                "registration_status": reg_status.value if reg_status else None,
                "ticket_code": ticket_code,
            }
    print("Success")
except Exception as e:
    import traceback
    traceback.print_exc()
