import logging

from fastapi import Header, HTTPException
from firebase_admin import auth

log = logging.getLogger("auth")


def require_uid(authorization: str | None = Header(default=None)) -> str:
    """FastAPI dependency: verify the Firebase ID token and return the uid."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header.")

    token = authorization.removeprefix("Bearer ").strip()

    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as e:
        log.warning("Token verification failed: %s", e)
        raise HTTPException(status_code=401, detail="Invalid or expired token.") from e
