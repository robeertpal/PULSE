from database import SessionLocal
import models
from main import apply_current_price_to_payload

db = SessionLocal()
event = db.query(models.Event).filter(models.Event.id == 3).first()
if event:
    item = event.content_item
    data = {
        "price_type": event.price_type.value if event.price_type else None,
        "price_amount": float(event.price_amount) if event.price_amount else None,
        "pricing_rules": []
    }
    for r in item.pricing_rules:
        data["pricing_rules"].append({
            "id": r.id,
            "type": r.type.value if r.type else None,
            "price": float(r.price),
            "start_date": r.start_date,
            "end_date": r.end_date,
        })
    apply_current_price_to_payload(data, data)
    print("Applied price type:", data.get("price_type"))
    print("Applied price amount:", data.get("price_amount"))
