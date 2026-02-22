import re
import secrets
import string


def generate_username(email: str) -> str:
    """
    Derive a Kubernetes-safe username from an email address.

    alex.chen@example.com  →  alex-chen
    john.doe+test@example.com  →  john-doe-test
    """
    local = email.split("@")[0]
    username = re.sub(r"[^a-z0-9]", "-", local.lower())
    username = re.sub(r"-+", "-", username).strip("-")
    return username


def generate_password(length: int = 16) -> str:
    """Generate a random alphanumeric password."""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))
