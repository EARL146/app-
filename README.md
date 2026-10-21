# BurgerBites

BurgerBites is a Flutter ordering app with a PHP/MySQL API. The local working copy uses AMPPS database `burger_bites` (displayed as `Burger_Bites`) with seven core tables and a restricted API account. Local credentials are kept in ignored `backend/.env`. The app is not production-ready.

## Run the Flutter client

```powershell
flutter pub get
flutter devices
flutter run -d edge
```

For Android, connect a phone with USB debugging or start an emulator, then use its ID from `flutter devices`:

```powershell
flutter run -d <device-id>
```

Without an API URL, the app opens its branded start and demo browsing screens, while sign-in/register and server-backed actions show that setup is needed.

## Configure the local API

Follow [backend/README.md](backend/README.md) to run the local PHP API and create an administrator when needed. Do not use `streetfood_db`; it is unrelated to the confirmed BurgerBites database.

To run a separate Docker API/MySQL/Redis stack without replacing AMPPS, see [docs/DOCKER_REDIS.md](docs/DOCKER_REDIS.md). Its isolated API listens on `127.0.0.1:8082`; the Redis port is private to Docker.

Pass the API URL to Flutter. For Edge, fix the Flutter web port to `5000` and allow `http://localhost:5000` in the backend's local CORS list:

```powershell
flutter run -d edge --web-port=5000 --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1
```

For Android Emulator, the host computer is reachable at `10.0.2.2`:

```powershell
flutter run -d <device-id> --dart-define=BURGER_BITES_API_BASE_URL=http://10.0.2.2:8081/api/v1
```

The Android cleartext exception is limited to debug builds. Release builds require HTTPS.

## Verify

```powershell
dart format lib test
flutter analyze
flutter test
php -l backend/public/index.php
```

Flutter tests cover startup navigation and cart preview calculations. The local products API passed a database-backed HTTP smoke check; account and order journeys still need end-to-end testing. See [docs/TESTING.md](docs/TESTING.md) and [docs/PRODUCTION_READINESS_AUDIT.md](docs/PRODUCTION_READINESS_AUDIT.md).

## Current limitations

- PHP routes exist for registration, login, token refresh/revocation, profile reads/edits, products, favorites, and COD order creation. Admin product/order/customer APIs and customer order history are not implemented.
- Menu, search, order history, and admin management screens still use local preview data. API/database behavior is not end-to-end verified.
- Migration `001` is applied to the confirmed empty local `burger_bites` database; optional development products are not seeded. `streetfood_db` was not changed.
- There is no default admin credential. Use the secure PowerShell helper in `backend/tools` after setting up a dedicated database.
- Online payments and Google/Apple sign-in are not configured.
- The supplied screenshots and logo are available; the Figma URL could not be opened for exact visual comparison.
- No production host, domain, HTTPS/TLS certificate, CDN, WAF, DDoS protection, monitoring, or backup process is configured.

## Obsidian documentation

Open this project folder as an Obsidian vault and start at [docs/PROJECT_HOME.md](docs/PROJECT_HOME.md). Workflow notes cover integrations, Obsidian setup, and safe GitHub backup. See [docs/INTEGRATION_MAP.md](docs/INTEGRATION_MAP.md), [docs/OBSIDIAN_SETUP.md](docs/OBSIDIAN_SETUP.md), and [docs/BACKUP_WORKFLOW.md](docs/BACKUP_WORKFLOW.md).
