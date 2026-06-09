import main
from fastapi.testclient import TestClient

client = TestClient(main.app)
response = client.get("/")
print("Status:", response.status_code)
print("Body:", response.text)
