import os

import firebase_admin
from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import auth, credentials
from pydantic import BaseModel
from dotenv import load_dotenv

from scraper import IcressUnavailableError, ParseError, StudentNotFoundError, scrape_timetable

load_dotenv()

_cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not _cred_path:
    raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS env var is not set.")

firebase_admin.initialize_app(credentials.Certificate(_cred_path))

_allowed_origins = os.getenv("ALLOWED_ORIGINS", "").split(",")

app = FastAPI(title="Student Reminder Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _allowed_origins if o.strip()],
    allow_methods=["POST"],
    allow_headers=["Authorization", "Content-Type"],
)


class TimetableRequest(BaseModel):
    matric_number: str
    semester_code: str


def _verify_token(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header.")

    token = authorization.removeprefix("Bearer ").strip()

    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {e}") from e


@app.post("/api/timetable/scrape")
async def scrape(
    body: TimetableRequest,
    authorization: str | None = Header(default=None),
):
    _verify_token(authorization)

    matric = body.matric_number.strip()
    semester = body.semester_code.strip()

    if not matric:
        raise HTTPException(status_code=422, detail="matric_number is required.")
    if not semester:
        raise HTTPException(status_code=422, detail="semester_code is required.")

    try:
        result = scrape_timetable(matric, semester)
        return result
    except StudentNotFoundError:
        raise HTTPException(status_code=404, detail="student_not_found")
    except IcressUnavailableError:
        raise HTTPException(status_code=503, detail="iCRESS_unavailable")
    except ParseError as e:
        raise HTTPException(status_code=502, detail=f"parse_error: {e}")


@app.get("/health")
async def health():
    return {"status": "ok"}
