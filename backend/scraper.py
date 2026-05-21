import json
import urllib.error
import urllib.request

CDN_URL = "https://cdn.uitm.link/jadual/baru/{matric}.json"
_HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://mystudent.uitm.edu.my/",
}


class IcressUnavailableError(Exception):
    pass


class StudentNotFoundError(Exception):
    pass


class ParseError(Exception):
    pass


def scrape_timetable(matric_number: str, semester_code: str = "") -> dict:
    url = CDN_URL.format(matric=matric_number.strip().upper())
    req = urllib.request.Request(url, headers=_HEADERS)

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            raise StudentNotFoundError(f"No timetable found for matric: {matric_number}")
        raise IcressUnavailableError(f"CDN HTTP {e.code}: {e.reason}") from e
    except Exception as e:
        raise IcressUnavailableError(f"Could not reach timetable CDN: {e}") from e

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ParseError(f"Invalid JSON from CDN: {e}") from e

    if not isinstance(data, dict) or not data:
        raise StudentNotFoundError(f"Empty timetable for matric: {matric_number}")

    return _parse_response(matric_number, data)


def _parse_response(matric: str, data: dict) -> dict:
    subjects: dict[str, dict] = {}
    group_code: str | None = None
    schedule: dict[str, dict] = {}

    for date_key in sorted(data.keys()):
        day_data = data[date_key]
        if day_data is None:
            continue

        hari = day_data.get("hari", "")
        day_classes = []

        for cls in day_data.get("jadual", []):
            cid = cls.get("courseid", "")

            if not group_code:
                group_code = cls.get("groups")

            if cid and cid not in subjects:
                subjects[cid] = {
                    "courseid": cid,
                    "course_desc": cls.get("course_desc", ""),
                    "lecturer": cls.get("lecturer") or "",
                    "schedule": [],
                }

            if cid:
                slot = {
                    "day": hari,
                    "masa": cls.get("masa", ""),
                    "bilik": cls.get("bilik") or "",
                }
                if slot not in subjects[cid]["schedule"]:
                    subjects[cid]["schedule"].append(slot)
                if not subjects[cid]["lecturer"] and cls.get("lecturer"):
                    subjects[cid]["lecturer"] = cls["lecturer"]

            day_classes.append({
                "courseid": cid,
                "course_desc": cls.get("course_desc", ""),
                "masa": cls.get("masa", ""),
                "bilik": cls.get("bilik") or "",
                "lecturer": cls.get("lecturer") or "",
            })

        schedule[date_key] = {"hari": hari, "jadual": day_classes}

    if not subjects and not schedule:
        raise ParseError("Timetable data contains no class entries.")

    return {
        "matric": matric.strip().upper(),
        "group": group_code or "",
        "subjects": list(subjects.values()),
        "schedule": schedule,
    }
