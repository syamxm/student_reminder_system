import json
import os
import urllib.error
import urllib.parse
import urllib.request

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
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# ── Campus / Faculty API constants ──────────────────────────────────────────
_CFC_URL = "https://simsweb4.uitm.edu.my/estudent/class_timetable/cfc/select.cfc"
_CFC_HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://simsweb4.uitm.edu.my/estudent/class_timetable/indexIllIl.cfm",
}
_CAMPUS_METHOD = "CAM_lII1II11I1lIIII11IIl1I111I"
_FACULTY_METHOD = "FAC_lII1II11I1lIIII11IIl1I111I"


class TimetableRequest(BaseModel):
    matric_number: str
    semester_code: str = ""


def _verify_token(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header.")

    token = authorization.removeprefix("Bearer ").strip()

    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {e}") from e


def _cfc_get(params: dict) -> list[dict]:
    url = _CFC_URL + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers=_CFC_HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
        data = json.loads(raw)
        items = data if isinstance(data, list) else data.get("results", [])
        return [i for i in items if isinstance(i, dict) and i.get("id") not in ("X", "", None)]
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Campus/faculty API unavailable: {e}")


@app.post("/api/timetable/scrape")
async def scrape(
    body: TimetableRequest,
    authorization: str | None = Header(default=None),
):
    _verify_token(authorization)

    matric = body.matric_number.strip()
    if not matric:
        raise HTTPException(status_code=422, detail="matric_number is required.")

    try:
        return scrape_timetable(matric, body.semester_code)
    except StudentNotFoundError:
        raise HTTPException(status_code=404, detail="student_not_found")
    except IcressUnavailableError:
        raise HTTPException(status_code=503, detail="iCRESS_unavailable")
    except ParseError as e:
        raise HTTPException(status_code=502, detail=f"parse_error: {e}")


@app.get("/api/campuses")
async def list_campuses(authorization: str | None = Header(default=None)):
    _verify_token(authorization)
    items = _cfc_get({"method": _CAMPUS_METHOD, "key": "All", "page": "1", "page_limit": "200"})
    return {"campuses": [{"code": i["id"], "name": i["text"]} for i in items]}


@app.get("/api/faculties")
async def list_faculties(
    campus: str,
    authorization: str | None = Header(default=None),
):
    _verify_token(authorization)
    if not campus:
        raise HTTPException(status_code=422, detail="campus query param is required.")
    items = _cfc_get({
        "method": _FACULTY_METHOD, "campus": campus,
        "key": "All", "page": "1", "page_limit": "200",
    })
    return {"faculties": [{"code": i["id"], "name": i["text"]} for i in items]}


@app.get("/health")
async def health():
    return {"status": "ok"}
