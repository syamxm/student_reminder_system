# Backend Deploy — Debian + Cloudflare Tunnel

## Overview

```
Flutter app
    │  HTTPS (Firebase JWT in header)
    ▼
api.yourdomain.com   ← Cloudflare Tunnel handles SSL
    │
    ▼
cloudflared (running on Debian)
    │
    ▼
localhost:8000       ← FastAPI / uvicorn
```

No nginx required. Cloudflare Tunnel handles SSL and routing directly.

The backend uses **Redis** for response caching (campuses, faculties, timetables)
and per-user rate limiting. Redis is **optional at runtime** — if it is
unreachable the backend fails open (skips cache + rate limiting and serves
directly from the UiTM upstream). Set `REDIS_URL` in `.env`
(default `redis://localhost:6379/0`).

Two ways to run it:
- **Docker Compose** (recommended, brings up Redis for you) — see the section at
  the end of this file.
- **systemd** (steps below) — install Redis separately:
  `doas apt install redis-server && doas systemctl enable --now redis-server`.

---

## Step 1 — System dependencies (on Debian)

```bash
doas apt update
doas apt install python3 python3-pip python3-venv git
```

---

## Step 2 — Clone the repo

```bash
git clone https://github.com/syamxm/student_reminder_system.git /opt/student-reminder-backend
cd /opt/student-reminder-backend/backend
```

To update later:
```bash
cd /opt/student-reminder-backend
git pull
doas systemctl restart student-reminder
```

---

## Step 3 — Python venv and dependencies

```bash
cd /opt/student-reminder-backend/backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

---

## Step 4 — Firebase service account key

1. Firebase Console → Project Settings → Service Accounts → **Generate new private key**
2. Download the JSON file
3. Copy it to the server (never commit this file):

```bash
# From your PC
scp serviceAccountKey.json user@your-debian-ip:/opt/student-reminder-backend/backend/serviceAccountKey.json
```

```bash
# On Debian — lock down permissions
chmod 600 /opt/student-reminder-backend/backend/serviceAccountKey.json
```

---

## Step 5 — Create .env file

```bash
cd /opt/student-reminder-backend/backend
cp .env.example .env
nano .env
```

Fill in:
```
GOOGLE_APPLICATION_CREDENTIALS=/opt/student-reminder-backend/backend/serviceAccountKey.json
ALLOWED_ORIGINS=https://api.yourdomain.com
```

---

## Step 6 — systemd service

```bash
doas cp /opt/student-reminder-backend/backend/student-reminder.service /etc/systemd/system/

# Edit WorkingDirectory and ExecStart paths if needed
doas nano /etc/systemd/system/student-reminder.service
```

Make sure these lines match your actual paths:
```
WorkingDirectory=/opt/student-reminder-backend/backend
EnvironmentFile=/opt/student-reminder-backend/backend/.env
ExecStart=/opt/student-reminder-backend/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
```

```bash
doas systemctl daemon-reload
doas systemctl enable student-reminder
doas systemctl start student-reminder
doas systemctl status student-reminder
```

Check it is running on port 8000:
```bash
curl http://localhost:8000/health
# Expected: {"status":"ok"}
```

---

## Step 7 — Cloudflare Tunnel

### Install cloudflared

```bash
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | doas tee /usr/share/keyrings/cloudflare-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared bookworm main" | doas tee /etc/apt/sources.list.d/cloudflared.list
doas apt update && doas apt install cloudflared
```

### Create and configure the tunnel

```bash
cloudflared tunnel login
cloudflared tunnel create student-reminder
```

Create the tunnel config file:
```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

```yaml
tunnel: student-reminder
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: api.yourdomain.com
    service: http://localhost:8000
  - service: http_status:404
```

Replace `<TUNNEL_ID>` with the ID printed by `cloudflared tunnel create`.

### Route DNS

```bash
cloudflared tunnel route dns student-reminder api.yourdomain.com
```

### Run as a service

```bash
doas cloudflared service install
doas systemctl enable cloudflared
doas systemctl start cloudflared
doas systemctl status cloudflared
```

---

## Step 8 — Test end-to-end

```bash
# Health check from anywhere
curl https://api.yourdomain.com/health
# Expected: {"status":"ok"}

# Timetable scrape (get a Firebase ID token from the app first)
curl -X POST https://api.yourdomain.com/api/timetable/scrape \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"matric_number": "2022123456", "semester_code": "20252"}'
```

---

## Step 9 — Update the Flutter app

In the Flutter app (Phase 3), set the base URL:
```
https://api.yourdomain.com
```

The app sends the user's Firebase ID token with every request. The backend verifies it — no other auth needed.

---

## Docker Compose (Redis + backend)

`docker-compose.yml` runs the FastAPI backend and Redis together. The backend
talks to Redis over the internal `redis` hostname, so `REDIS_URL` is set
automatically inside the container.

```bash
cd /opt/student-reminder-backend/backend

# .env still needed for ALLOWED_ORIGINS (GOOGLE_APPLICATION_CREDENTIALS and
# REDIS_URL are overridden by compose)
cp .env.example .env && nano .env

# Place the Firebase key next to the compose file (mounted read-only into the container)
# serviceAccountKey.json -> /app/serviceAccountKey.json

docker compose up --build -d
curl http://localhost:8000/health   # {"status":"ok"}
```

Point Cloudflare Tunnel at `http://localhost:8000` exactly as in the systemd
path. Inspect cache keys with:

```bash
docker compose exec redis redis-cli KEYS '*'
docker compose exec redis redis-cli TTL cfc:campuses
```

---

## Updating scraper.py after inspecting iCRESS HTML

1. Open `https://icress.uitm.edu.my/timetable/search.asp` in a browser
2. Open DevTools → Network → submit a real matric number
3. Inspect the POST request fields and the response HTML table
4. Update `scraper.py` — confirm field names, table selector, column order
5. Redeploy:

```bash
cd /opt/student-reminder-backend
git pull
doas systemctl restart student-reminder
```
