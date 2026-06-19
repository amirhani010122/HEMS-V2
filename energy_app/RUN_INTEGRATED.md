# Running the Flutter app (integrated with the FastAPI backend)

## 1. Point at the backend
`lib/core/config/environment.dart` controls the base URL. In `development`
(the default) it is `http://localhost:8000/api/v1`.

- Android emulator: change the dev URL to `http://10.0.2.2:8000/api/v1`.
- Physical device: use your machine's LAN IP, e.g. `http://192.168.1.x:8000/api/v1`.

## 2. Run
```bash
cd energy_app
flutter pub get
flutter run
```

## Notes
- Models are plain Dart (no `build_runner` / codegen step required).
- JSON parsing is null-defensive and reads the backend's snake_case keys.
- The auth interceptor automatically refreshes the access token on a 401 and
  retries the original request once; on refresh failure it clears the session.
