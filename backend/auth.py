from fastapi import Header, HTTPException
from firebase_admin import auth


def require_uid(authorization: str | None = Header(default=None)) -> str:
    """FastAPI dependency: verify the Firebase ID token and return the uid."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header.")

    token = authorization.removeprefix("Bearer ").strip()

    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {e}") from e
