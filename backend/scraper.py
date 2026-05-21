import requests
from bs4 import BeautifulSoup

ICRESS_URL = "https://icress.uitm.edu.my/timetable/search.asp"

# TODO: Inspect the actual iCRESS form with browser dev tools and confirm:
# 1. The exact POST field names (matric, semester)
# 2. Whether a session cookie / VIEWSTATE is required first
# 3. The HTML table structure in the response


class IcressUnavailableError(Exception):
    pass


class StudentNotFoundError(Exception):
    pass


class ParseError(Exception):
    pass


def scrape_timetable(matric_number: str, semester_code: str) -> dict:
    session = requests.Session()
    session.headers.update({
        "User-Agent": "Mozilla/5.0",
        "Referer": ICRESS_URL,
    })

    try:
        # Step 1: GET the search page to pick up any session cookies / VIEWSTATE
        get_resp = session.get(ICRESS_URL, timeout=15)
        get_resp.raise_for_status()
    except requests.RequestException as e:
        raise IcressUnavailableError(f"Could not reach iCRESS: {e}") from e

    soup_get = BeautifulSoup(get_resp.text, "lxml")

    # Build POST payload
    # TODO: Confirm actual field names by inspecting the <form> in iCRESS HTML
    payload: dict = {
        "no_matric": matric_number,
        "semester": semester_code,
    }

    # Carry over any hidden VIEWSTATE / ASP.NET fields if present
    for hidden in soup_get.select("input[type=hidden]"):
        name = hidden.get("name")
        value = hidden.get("value", "")
        if name:
            payload[name] = value

    try:
        post_resp = session.post(ICRESS_URL, data=payload, timeout=15)
        post_resp.raise_for_status()
    except requests.RequestException as e:
        raise IcressUnavailableError(f"iCRESS POST failed: {e}") from e

    return _parse_response(post_resp.text)


def _parse_response(html: str) -> dict:
    soup = BeautifulSoup(html, "lxml")

    # TODO: Verify the actual table/selector used by iCRESS for results.
    # Common patterns: <table class="table">, <table id="timetable">, etc.
    # Inspect the response HTML to confirm.

    # Detect "not found" responses
    page_text = soup.get_text().lower()
    not_found_markers = ["no record", "not found", "tiada rekod", "maklumat tidak dijumpai"]
    if any(marker in page_text for marker in not_found_markers):
        raise StudentNotFoundError("No timetable found for this student.")

    # Extract campus and faculty from page header
    # TODO: Confirm the actual element containing campus/faculty info
    campus = _extract_text(soup, ["td.campus", ".campus", "#campus"]) or ""
    faculty = _extract_text(soup, ["td.faculty", ".faculty", "#faculty"]) or ""

    # Find the timetable data table
    # TODO: Update selector to match actual iCRESS HTML
    table = soup.select_one("table.table, table#timetable, table")
    if table is None:
        raise ParseError("Could not find timetable table in iCRESS response.")

    subjects = []
    rows = table.select("tr")

    for row in rows[1:]:  # skip header row
        cells = [td.get_text(strip=True) for td in row.select("td")]

        # TODO: Confirm column order from actual iCRESS HTML
        # Expected order: [no, subjectCode, subjectName, groupCode, day, startTime, endTime, room, mode]
        if len(cells) < 8:
            continue

        subjects.append({
            "subjectCode": cells[1],
            "subjectName": cells[2],
            "groupCode": cells[3],
            "day": cells[4],
            "startTime": _parse_time(cells[5]),
            "endTime": _parse_time(cells[6]),
            "room": cells[7],
            "mode": cells[8] if len(cells) > 8 else "Face to Face",
        })

    if not subjects:
        raise ParseError("Table found but no subject rows could be parsed.")

    return {
        "campus": campus,
        "faculty": faculty,
        "subjects": subjects,
    }


def _extract_text(soup: BeautifulSoup, selectors: list[str]) -> str | None:
    for selector in selectors:
        el = soup.select_one(selector)
        if el:
            return el.get_text(strip=True)
    return None


def _parse_time(raw: str) -> str:
    raw = raw.strip().replace(".", ":")
    if len(raw) == 4 and raw.isdigit():
        return f"{raw[:2]}:{raw[2:]}"
    return raw
