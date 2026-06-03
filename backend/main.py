import json
import os
import urllib.error
import urllib.parse
import urllib.request
from contextlib import asynccontextmanager

import firebase_admin
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import credentials
from pydantic import BaseModel
from dotenv import load_dotenv

from cache import close_cache, get_json, init_cache, set_json
from rate_limit import RateLimit
from scraper import IcressUnavailableError, ParseError, StudentNotFoundError, scrape_timetable

load_dotenv()

_cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not _cred_path:
    raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS env var is not set.")

firebase_admin.initialize_app(credentials.Certificate(_cred_path))

_allowed_origins = os.getenv("ALLOWED_ORIGINS", "").split(",")

# ── Cache TTLs (seconds) ─────────────────────────────────────────────────────
_TTL_CFC = 24 * 60 * 60      # campuses / faculties: near-static
_TTL_TIMETABLE = 6 * 60 * 60  # timetable: can change mid-semester


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_cache()
    yield
    await close_cache()


app = FastAPI(title="Student Reminder Backend", lifespan=lifespan)

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
    uid: str = Depends(RateLimit("scrape", 10, 60)),
):
    matric = body.matric_number.strip()
    if not matric:
        raise HTTPException(status_code=422, detail="matric_number is required.")

    cache_key = f"timetable:{matric.upper()}:{body.semester_code}"
    cached = await get_json(cache_key)
    if cached is not None:
        return cached

    try:
        result = scrape_timetable(matric, body.semester_code)
    except StudentNotFoundError:
        raise HTTPException(status_code=404, detail="student_not_found")
    except IcressUnavailableError:
        raise HTTPException(status_code=503, detail="iCRESS_unavailable")
    except ParseError as e:
        raise HTTPException(status_code=502, detail=f"parse_error: {e}")

    await set_json(cache_key, result, _TTL_TIMETABLE)
    return result


@app.get("/api/campuses")
async def list_campuses(uid: str = Depends(RateLimit("campuses", 30, 60))):
    cache_key = "cfc:campuses"
    cached = await get_json(cache_key)
    if cached is not None:
        return cached

    items = _cfc_get({"method": _CAMPUS_METHOD, "key": "All", "page": "1", "page_limit": "200"})
    result = {"campuses": [{"code": i["id"], "name": i["text"]} for i in items]}
    await set_json(cache_key, result, _TTL_CFC)
    return result


@app.get("/api/faculties")
async def list_faculties(
    campus: str,
    uid: str = Depends(RateLimit("faculties", 30, 60)),
):
    if not campus:
        raise HTTPException(status_code=422, detail="campus query param is required.")

    cache_key = f"cfc:faculties:{campus}"
    cached = await get_json(cache_key)
    if cached is not None:
        return cached

    items = _cfc_get({
        "method": _FACULTY_METHOD, "campus": campus,
        "key": "All", "page": "1", "page_limit": "200",
    })
    result = {"faculties": [{"code": i["id"], "name": i["text"]} for i in items]}
    await set_json(cache_key, result, _TTL_CFC)
    return result


@app.get("/health")
async def health():
    return {"status": "ok"}
