import argparse
import getpass
import hashlib
import secrets


DEFAULT_ITERATIONS = 120_000


def hash_password(password: str, salt: bytes | None = None, iterations: int = DEFAULT_ITERATIONS) -> str:
    salt = salt or secrets.token_bytes(16)
    derived_key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        iterations,
    )
    return f"pbkdf2_sha256${iterations}${salt.hex()}${derived_key.hex()}"


def main():
    parser = argparse.ArgumentParser(description="Generate ADMIN_PASSWORD_HASH for PULSE backend.")
    parser.add_argument("--password", help="Admin password. Omit to enter it without echo.")
    parser.add_argument("--iterations", type=int, default=DEFAULT_ITERATIONS)
    args = parser.parse_args()

    password = args.password
    if password is None:
        password = getpass.getpass("Admin password: ")
        confirm = getpass.getpass("Confirm admin password: ")
        if password != confirm:
            raise SystemExit("Passwords do not match.")

    if len(password) < 8:
        raise SystemExit("Password must have at least 8 characters.")

    print(hash_password(password, iterations=args.iterations))


if __name__ == "__main__":
    main()
