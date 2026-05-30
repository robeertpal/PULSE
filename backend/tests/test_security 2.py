import os
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_security.db")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("ALLOWED_ORIGINS", "http://localhost:5500,http://127.0.0.1:5500")
os.environ.setdefault("ADMIN_USERNAME", "admin@example.com")
os.environ.setdefault(
    "ADMIN_PASSWORD_HASH",
    "pbkdf2_sha256$120000$4a4d3d9bb8a844dca4d2f36b584f9071$3c8279f8268bf5d7124d07f8cf8f1f7cbfcfe2a0836bbd8bcb2a15ec28f4b082",
)
os.environ.setdefault("AI_MAX_INPUT_CHARS", "100")

from fastapi.testclient import TestClient

import main


client = TestClient(main.app)


def test_security_headers_are_present():
    response = client.get("/")

    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    assert "camera=()" in response.headers["permissions-policy"]


def test_cors_allows_configured_local_origin():
    response = client.options(
        "/health",
        headers={
            "Origin": "http://localhost:5500",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:5500"


def test_admin_endpoint_requires_token():
    response = client.get("/admin/dashboard/stats")

    assert response.status_code == 401


def test_admin_endpoint_rejects_invalid_token():
    response = client.get(
        "/admin/dashboard/stats",
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert response.status_code == 401


def test_saved_content_requires_authentication():
    response = client.get("/saved-content/ids")

    assert response.status_code == 401


def test_saved_content_uses_authenticated_user_not_query_user_id(monkeypatch):
    class FakeQuery:
        def filter(self, *args, **kwargs):
            return self

        def first(self):
            return None

    class FakeDb:
        def __init__(self):
            self.added = None

        def query(self, *args, **kwargs):
            return FakeQuery()

        def add(self, value):
            self.added = value

        def commit(self):
            pass

    fake_db = FakeDb()
    monkeypatch.setattr(main, "get_public_content_item_or_404", lambda db, content_item_id: SimpleNamespace(id=content_item_id))

    main.app.dependency_overrides[main.get_db] = lambda: fake_db
    main.app.dependency_overrides[main.get_current_user_id] = lambda: 7
    try:
        response = client.post("/saved-content/123?user_id=999")
    finally:
        main.app.dependency_overrides.clear()

    assert response.status_code == 200
    assert fake_db.added.user_id == 7
    assert fake_db.added.content_item_id == 123


def test_ai_summary_rejects_too_long_input(monkeypatch):
    item = SimpleNamespace(
        title="A",
        short_description="B",
        body="x" * 500,
        content_type=main.models.ContentItemType.article,
    )
    monkeypatch.setattr(main, "get_public_content_item_or_404", lambda db, content_item_id: item)

    response = client.post("/content-items/1/ai-summary")

    assert response.status_code == 413


def test_register_rejects_invalid_payload_before_db_access():
    response = client.post(
        "/api/register",
        json={
            "email": "not-an-email",
            "password": "short",
            "first_name": "",
            "last_name": "",
            "cnp": "",
            "phone": "",
        },
    )

    assert response.status_code == 422


def test_email_verification_delivery_failure_can_be_non_fatal():
    class FakeDb:
        def __init__(self):
            self.added = []

        def add(self, value):
            self.added.append(value)

        def flush(self):
            pass

    fake_db = FakeDb()

    with patch("main.send_email_verification_email", side_effect=RuntimeError("smtp down")):
        sent = main.create_email_verification(
            fake_db,
            user_id=123,
            to_email="doctor@example.com",
            now=main.datetime.utcnow(),
            raise_on_email_error=False,
        )

    assert sent is False
    assert len(fake_db.added) == 1


def test_smtp_config_accepts_render_email_env_names():
    with patch.dict(
        os.environ,
        {
            "SMTP_HOST": "smtp.example.com",
            "SMTP_PORT": "587",
            "SMTP_USER": "smtp-user@example.com",
            "SMTP_PASSWORD": "secret",
            "SMTP_FROM": "Pulse <no-reply@example.com>",
        },
        clear=True,
    ):
        config = main.get_smtp_config()

    assert config.host == "smtp.example.com"
    assert config.port == 587
    assert config.email_from == "Pulse <no-reply@example.com>"
    assert config.from_env_name == "SMTP_FROM"
    assert config.use_starttls is True
    assert config.use_ssl is False


def test_smtp_port_465_uses_ssl_without_starttls():
    smtp_context = MagicMock()
    smtp_client = MagicMock()
    smtp_context.__enter__.return_value = smtp_client

    with patch.dict(
        os.environ,
        {
            "SMTP_HOST": "smtp.example.com",
            "SMTP_PORT": "465",
            "SMTP_USER": "smtp-user@example.com",
            "SMTP_PASSWORD": "secret",
            "FROM_EMAIL": "no-reply@example.com",
        },
        clear=True,
    ), patch("main.smtplib.SMTP_SSL", return_value=smtp_context) as smtp_ssl, patch(
        "main.smtplib.SMTP"
    ) as smtp_plain:
        main.send_smtp_email(
            email_type="test",
            to_email="doctor@example.com",
            subject="Test",
            text_content="Test",
            html_content="<p>Test</p>",
        )

    smtp_ssl.assert_called_once_with("smtp.example.com", 465, timeout=20)
    smtp_plain.assert_not_called()
    smtp_client.starttls.assert_not_called()
    smtp_client.login.assert_called_once_with("smtp-user@example.com", "secret")
    assert smtp_client.send_message.called is True
