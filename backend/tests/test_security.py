import os
import unittest
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


class SecurityTests(unittest.TestCase):
    def tearDown(self):
        main.app.dependency_overrides.clear()

    def test_security_headers_are_present(self):
        response = client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers["x-content-type-options"], "nosniff")
        self.assertEqual(response.headers["x-frame-options"], "DENY")
        self.assertEqual(response.headers["referrer-policy"], "strict-origin-when-cross-origin")
        self.assertIn("camera=()", response.headers["permissions-policy"])

    def test_cors_allows_configured_local_origin(self):
        response = client.options(
            "/health",
            headers={
                "Origin": "http://localhost:5500",
                "Access-Control-Request-Method": "GET",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers["access-control-allow-origin"], "http://localhost:5500")

    def test_admin_endpoint_requires_token(self):
        response = client.get("/admin/dashboard/stats")

        self.assertEqual(response.status_code, 401)

    def test_admin_endpoint_rejects_invalid_token(self):
        response = client.get(
            "/admin/dashboard/stats",
            headers={"Authorization": "Bearer invalid-token"},
        )

        self.assertEqual(response.status_code, 401)

    def test_saved_content_requires_authentication(self):
        response = client.get("/saved-content/ids")

        self.assertEqual(response.status_code, 401)

    def test_saved_content_uses_authenticated_user_not_query_user_id(self):
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
        main.app.dependency_overrides[main.get_db] = lambda: fake_db
        main.app.dependency_overrides[main.get_current_user_id] = lambda: 7

        with patch(
            "main.get_public_content_item_or_404",
            lambda db, content_item_id: SimpleNamespace(id=content_item_id),
        ):
            response = client.post("/saved-content/123?user_id=999")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(fake_db.added.user_id, 7)
        self.assertEqual(fake_db.added.content_item_id, 123)

    def test_ai_summary_rejects_too_long_input(self):
        item = SimpleNamespace(
            title="A",
            short_description="B",
            body="x" * 500,
            content_type=main.models.ContentItemType.article,
        )
        with patch("main.get_public_content_item_or_404", lambda db, content_item_id: item):
            response = client.post("/content-items/1/ai-summary")

        self.assertEqual(response.status_code, 413)

    def test_register_rejects_invalid_payload_before_db_access(self):
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

        self.assertEqual(response.status_code, 422)

    def test_email_verification_delivery_failure_can_be_non_fatal(self):
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

        self.assertFalse(sent)
        self.assertEqual(len(fake_db.added), 1)

    def test_smtp_config_accepts_render_email_env_names(self):
        with patch.dict(
            os.environ,
            {
                "EMAIL_PROVIDER": "smtp",
                "SMTP_HOST": "smtp.example.com",
                "SMTP_PORT": "587",
                "SMTP_USER": "smtp-user@example.com",
                "SMTP_PASSWORD": "secret",
                "SMTP_FROM": "Pulse <no-reply@example.com>",
            },
            clear=True,
        ):
            config = main.get_smtp_config()

        self.assertEqual(config.provider, "smtp")
        self.assertEqual(config.host, "smtp.example.com")
        self.assertEqual(config.port, 587)
        self.assertEqual(config.email_from, "Pulse <no-reply@example.com>")
        self.assertEqual(config.from_env_name, "SMTP_FROM")
        self.assertTrue(config.use_starttls)
        self.assertFalse(config.use_ssl)

    def test_brevo_smtp_config_defaults_and_sender_name(self):
        with patch.dict(
            os.environ,
            {
                "EMAIL_PROVIDER": "brevo_smtp",
                "SMTP_USER": "login@smtp-brevo.com",
                "SMTP_PASSWORD": "secret",
                "EMAIL_FROM": "pulse.medichub@gmail.com",
                "SMTP_FROM": "fallback@example.com",
                "EMAIL_FROM_NAME": "PULSE",
                "EMAIL_REPLY_TO": "reply@example.com",
            },
            clear=True,
        ):
            config = main.get_smtp_config()

        self.assertEqual(config.provider, "brevo_smtp")
        self.assertEqual(config.host, "smtp-relay.brevo.com")
        self.assertEqual(config.port, 587)
        self.assertEqual(config.email_from, "pulse.medichub@gmail.com")
        self.assertEqual(config.from_env_name, "EMAIL_FROM")
        self.assertEqual(config.sender_header, "PULSE <pulse.medichub@gmail.com>")
        self.assertEqual(config.email_reply_to, "reply@example.com")
        self.assertTrue(config.use_starttls)
        self.assertFalse(config.use_ssl)
        self.assertFalse(config.force_ipv4)

    def test_bool_env_parses_false_values_as_false(self):
        false_values = ["false", "0", "no", "off", ""]
        for value in false_values:
            with self.subTest(value=value), patch.dict(os.environ, {"SMTP_FORCE_IPV4": value}, clear=True):
                self.assertFalse(main.parse_bool_env("SMTP_FORCE_IPV4", True))

    def test_smtp_port_465_uses_ssl_without_starttls(self):
        smtp_client = MagicMock()

        with patch.dict(
            os.environ,
            {
                "SMTP_HOST": "smtp.example.com",
                "SMTP_PORT": "465",
                "SMTP_USER": "smtp-user@example.com",
                "SMTP_PASSWORD": "secret",
                "FROM_EMAIL": "no-reply@example.com",
                "SMTP_FORCE_IPV4": "false",
            },
            clear=True,
        ), patch("main.smtplib.SMTP_SSL", return_value=smtp_client) as smtp_ssl, patch(
            "main.smtplib.SMTP"
        ) as smtp_plain, patch("main.ssl.create_default_context", return_value=MagicMock()) as ssl_context:
            main.send_smtp_email(
                email_type="test",
                to_email="doctor@example.com",
                subject="Test",
                text_content="Test",
                html_content="<p>Test</p>",
            )

        smtp_ssl.assert_called_once_with("smtp.example.com", 465, timeout=20, context=ssl_context.return_value)
        smtp_plain.assert_not_called()
        smtp_client.starttls.assert_not_called()
        smtp_client.login.assert_called_once_with("smtp-user@example.com", "secret")
        self.assertTrue(smtp_client.send_message.called)
        smtp_client.quit.assert_called_once()

    def test_ipv4_smtp_ssl_socket_wraps_ipv4_with_sni(self):
        ssl_context = MagicMock()
        smtp = main.IPv4SMTP_SSL.__new__(main.IPv4SMTP_SSL)
        smtp.context = ssl_context

        with patch(
            "main.socket.getaddrinfo",
            return_value=[(None, None, None, "", ("142.250.102.109", 465))],
        ) as getaddrinfo, patch(
            "main.socket.create_connection",
            return_value=MagicMock(),
        ) as create_connection:
            smtp._get_socket("smtp.example.com", 465, 20)

        getaddrinfo.assert_called_once_with("smtp.example.com", 465, main.socket.AF_INET, main.socket.SOCK_STREAM)
        create_connection.assert_called_once_with(("142.250.102.109", 465), 20)
        ssl_context.wrap_socket.assert_called_once_with(create_connection.return_value, server_hostname="smtp.example.com")

    def test_ipv4_smtp_socket_uses_ipv4_address(self):
        smtp = main.IPv4SMTP.__new__(main.IPv4SMTP)

        with patch(
            "main.socket.getaddrinfo",
            return_value=[(None, None, None, "", ("142.250.102.109", 587))],
        ) as getaddrinfo, patch(
            "main.socket.create_connection",
            return_value=MagicMock(),
        ) as create_connection:
            smtp._get_socket("smtp.example.com", 587, 20)

        getaddrinfo.assert_called_once_with("smtp.example.com", 587, main.socket.AF_INET, main.socket.SOCK_STREAM)
        create_connection.assert_called_once_with(("142.250.102.109", 587), 20)

    def test_smtp_force_ipv4_starttls_flow_uses_ipv4_class(self):
        smtp_client = MagicMock()

        with patch("main.IPv4SMTP", return_value=smtp_client) as smtp_ipv4, patch.dict(
            os.environ,
            {
                "SMTP_HOST": "smtp.example.com",
                "SMTP_PORT": "587",
                "SMTP_USER": "smtp-user@example.com",
                "SMTP_PASSWORD": "secret",
                "FROM_EMAIL": "no-reply@example.com",
                "SMTP_STARTTLS": "true",
                "SMTP_FORCE_IPV4": "true",
            },
            clear=True,
        ), patch("main.ssl.create_default_context", return_value=MagicMock()) as ssl_context:
            main.send_smtp_email(
                email_type="test",
                to_email="doctor@example.com",
                subject="Test",
                text_content="Test",
                html_content="<p>Test</p>",
            )

        smtp_ipv4.assert_called_once_with("smtp.example.com", 587, timeout=20)
        smtp_client.starttls.assert_called_once_with(context=ssl_context.return_value)
        self.assertEqual(smtp_client.ehlo.call_count, 2)
        smtp_client.login.assert_called_once_with("smtp-user@example.com", "secret")
        smtp_client.quit.assert_called_once()

    def test_smtp_quit_failure_after_send_does_not_fail_delivery(self):
        smtp_client = MagicMock()
        smtp_client.quit.side_effect = TimeoutError("quit timed out")

        with patch.dict(
            os.environ,
            {
                "EMAIL_PROVIDER": "brevo_smtp",
                "SMTP_USER": "login@smtp-brevo.com",
                "SMTP_PASSWORD": "secret",
                "EMAIL_FROM": "pulse.medichub@gmail.com",
                "EMAIL_REPLY_TO": "pulse.medichub@gmail.com",
            },
            clear=True,
        ), patch("main.smtplib.SMTP", return_value=smtp_client), patch(
            "main.ssl.create_default_context", return_value=MagicMock()
        ):
            main.send_smtp_email(
                email_type="test",
                to_email="doctor@example.com",
                subject="Test",
                text_content="Test",
                html_content="<p>Test</p>",
            )

        smtp_client.send_message.assert_called_once()
        sent_message = smtp_client.send_message.call_args.args[0]
        self.assertEqual(sent_message["From"], "pulse.medichub@gmail.com")
        self.assertEqual(sent_message["Reply-To"], "pulse.medichub@gmail.com")

    def test_smtp_force_ipv4_errors_clearly_without_ipv4_address(self):
        with patch("main.socket.getaddrinfo", return_value=[]):
            with self.assertRaisesRegex(RuntimeError, "has no IPv4 address"):
                main.resolve_smtp_ipv4("smtp.example.com", 587)


if __name__ == "__main__":
    unittest.main()
