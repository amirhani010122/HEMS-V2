# Running the backend (integrated with the Flutter app)

## 1. Install
```bash
cd energy_app_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## 2. MongoDB
Have MongoDB running locally (default `mongodb://localhost:27017`), or set
`MONGODB_URL` in a `.env` file (see `.env.example`).

## 3. Run
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API is served at `http://localhost:8000/api/v1`, which is exactly what the
Flutter app targets in development. Interactive docs: `http://localhost:8000/docs`.

On first startup three plans (Basic / Pro / Enterprise) are seeded automatically.

## Notes
- Auth uses JWT access + refresh tokens. `POST /auth/refresh` takes a JSON body
  `{"refresh_token": "..."}`.
- All responses use the snake_case field shapes the Flutter app parses.
- Device-facing IoT endpoints (`/devices/{id}/heartbeat|telemetry|commands`) are
  available for a simulator or real meter.
