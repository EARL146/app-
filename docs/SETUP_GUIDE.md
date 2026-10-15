# Setup Guide

[[PROJECT_HOME]] · [[TESTING]] · [[KNOWN_ISSUES]] · [[API_SPEC]] · [[DATABASE_SCHEMA]]

## Flutter client

```powershell
Set-Location 'C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites'
flutter pub get
flutter devices
flutter run -d edge
```

For Android, connect a USB-debugging phone or start an emulator and use the device ID printed by `flutter devices`.

## Local API and database

The PHP API and SQL migrations are in `backend/`. The local database and API settings are already configured. Follow [backend/README.md](../backend/README.md) for setup details. Current database state:

- `Burger_Bites` (`burger_bites`) has the seven core schema tables from migration `001`.
- API account `burger_bites_app` has least-privilege CRUD grants and is configured in ignored `backend/.env`.
- Optional sample products from migration `002` were not added.
- Required workflow migration `003_app_workflows.sql` is still pending. The current database already has migration 001; do not import 001 again. Export a SQL backup first, then import only 003 once through phpMyAdmin's Import tab while `Burger_Bites` is selected. Admin More → App Information reports readiness afterward.
- Start PHP on port 8081. Port 8080 is occupied by Tomcat on this computer. An admin account is created separately using the hidden-password helper; there is no default credential.

Run Edge against the API with a stable browser origin:

```powershell
flutter run -d edge --web-port=5000 --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1
```

`backend/.env` already allows `http://localhost:5000`. For Android Emulator, use `http://10.0.2.2:8081/api/v1`. Release builds require HTTPS. Do not expose a development server publicly.

## Obsidian

Open the project folder as a vault and select `docs/PROJECT_HOME.md`. If needed, choose **Open folder as vault** and use the project directory above. New notes are directed to `docs/` by `.obsidian/app.json`.

## Configuration safety

The local database connection was verified. Keep `backend/.env`, OAuth credentials, and payment secrets out of Git and Obsidian.
