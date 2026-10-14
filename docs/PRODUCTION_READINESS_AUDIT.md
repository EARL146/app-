# BurgerBites — Production Readiness Audit

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[SECURITY]] · [[TESTING]] · [[NEXT_SESSION]]

Audit date: 2026-10-14. The audit covers the Flutter repository and local AMPPS tooling. This work does **not** declare the app production-ready.

## Database setup update (2026-10-14)

The user identified the phpMyAdmin database as `Burger_Bites`. Read-only inspection confirmed it was empty, so migration `001_initial_schema.sql` was applied there; MySQL reports the normalized database name as `burger_bites`. A restricted `burger_bites_app` account and ignored `backend/.env` were configured. A live PHP HTTP request to `GET /api/v1/products` returned HTTP 200 with an empty list. The optional sample catalog was not inserted, and `streetfood_db` was not changed. Port 8080 belongs to Tomcat, so run the API on port 8081. See [[DATABASE_SCHEMA]] and [[TESTING]].

## Architecture inspected

- Flutter 3.47.6 / Dart 3.13.5 mobile-first client. `lib/main.dart` starts `AppShell`; `AppRouter` maps screens; Provider holds cart and preview admin state.
- The existing client initially had no PHP API or SQL migrations. A dependency-free PHP 8/PDO API and isolated migration set were added under `backend/` to match authentication, profile, product-read, favorites, and COD-order paths.
- Flutter menu/search, order history, and admin product/order/customer screens still use `DemoData` or local state.
- AMPPS provides PHP 8.2, PDO MySQL, MySQL tooling, and Argon2id. Apache/MySQL were not listening during the original inspection.
- `streetfood_db` has no project configuration linking it to BurgerBites and remains untouched. The user-confirmed empty `Burger_Bites` database now contains the initial schema.
- The supplied Figma URL could not be opened in the available viewer. The provided screenshots remain visual references; the owner-supplied logo is bundled in the app.

## Work completed

- Added the supplied chef-burger logo and splash → greetings → sign-in/register flow.
- Removed hard-coded demo admin credentials. Customer registration cannot assign admin; an explicit PowerShell helper creates an admin account using a hidden password prompt after database setup.
- Flutter calls the PHP API for login, registration, session restore, logout, profile updates, favorites, and COD checkout. Refresh tokens rotate and are saved by the client.
- PHP uses Argon2id, opaque random access/refresh tokens stored as HMAC hashes, token expiry/rotation/revocation, rate limit counters, PDO prepared statements, exact-origin CORS, request size limits, safe errors, and server-derived roles.
- PHP routes implement user profiles, product reads, customer-scoped favorites, and transactional COD orders with server-read prices and stock.
- Added initial MySQL schema and optional development product seed matching `DemoData`. Migration `001` was applied to the confirmed empty database; optional seed migration `002` was not.
- Added Android Internet permission; local cleartext HTTP is allowed only in Android debug builds. Release API URLs require HTTPS.
- Added Flutter widget/cart tests and updated Obsidian system, API, database, security, setup, and audit notes.

## Feature status

| Feature | Status | Evidence / limit |
| --- | --- | --- |
| Logo and initial navigation | Implemented and tested | Startup widget test covers logo, greetings, and sign-in routing. Figma visual match is not verified. |
| Flutter format/analyze | Implemented and tested | Modified Dart files formatted; `flutter analyze --no-pub` reported no issues. |
| Flutter automated tests | Implemented and tested | 4 tests passed: startup route and cart math/availability. They do not cover a live API. |
| Customer/admin auth code | Implemented but not fully verified | Flutter and PHP registration/login/session routes exist and MySQL is configured. Full signup/login/session journeys remain untested. Admin account helper is present; no default credentials. |
| Profiles and favorites | Implemented but not fully verified | PHP endpoints are scoped to the bearer-token user; no DB integration test has run. Multiple saved addresses are not supported. |
| Product browse/search | Partially implemented | PHP public product list/detail API exists; Flutter menu/search still use local sample data. |
| Cart calculation | Implemented and tested as a preview | Provider math tested. Backend recomputes authoritative totals; no SQL order test ran. |
| COD order placement | Implemented but not fully verified | PHP transaction checks/decrements stock and writes snapshots; migration/database absent, no cancellation/restock lifecycle. |
| Admin product/order/customer operations | Not implemented | Flutter views are local preview data; PHP `/admin/*` routes are not implemented. Route gating in Flutter is not server authorization. |
| Google/Apple sign-in and online payment | Not implemented | Provider credentials/token verification and payment service/callbacks are absent. |
| MySQL schema | Configured locally | Seven core tables from migration `001` are installed in `burger_bites`; restricted account and `GET /products` DB/HTTP check passed. No sample data was inserted. |
| Android APK/runtime | Blocked | Gradle could not resolve `storage.googleapis.com`; no APK produced. No Android device/emulator connected. |
| Hosting protections | Not implemented | No public host/domain, TLS certificate, CDN/WAF/DDoS service, monitoring, or backup process configured. |

## Remaining work by priority

1. Test registration/login/refresh/logout, profile, favorites, and COD order against MySQL, including authorization, token expiry, duplicate registration, stock changes, and rollback cases.
2. Add verified menu data before enabling real ordering; do not treat optional development seed rows as real restaurant data.
3. Connect Flutter catalog, order history, and admin screens to API endpoints; implement admin product/category/inventory/order/customer operations with server role checks and audit events.
4. Implement multiple-address management and an order cancellation/status lifecycle that safely returns stock.
5. Decide the actual tax/delivery/stock rules and verify exact pricing with the owner.
6. Use the provided screenshots for design review; run layout checks on Android phone/emulator when available.
7. Retry the Android build after DNS/network access to `storage.googleapis.com` works; verify on a device.
8. Configure production host, HTTPS, DNS, firewall/proxy, backups/restoration, monitoring, and incident response after choosing a provider.

## Verification record

- `php -l` on all PHP files: passed.
- Local PHP HTTP configuration smoke check: passed; with no database settings, the app returned a safe JSON `503`. This verifies bootstrap/error handling only.
- MySQL setup and PHP database connection: passed. Verified all seven core tables through the restricted app account; `GET /api/v1/products` returned HTTP 200 with an empty list.
- `dart format` on modified Dart files: completed, 0 changes on final formatting pass.
- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --reporter expanded --no-pub`: passed, 4 tests.
- Android `flutter build apk --debug --no-pub`: failed while Gradle tried to download Flutter artifacts; DNS could not resolve `storage.googleapis.com`. No APK was produced.
- Signup/login, favorites, order integration journeys, payment, external login, deployment, and Android device tests were not performed.
- C: had about 0.32 GB free after Flutter tests; more space is needed before further builds.
- The earlier user-reported Edge compile error was disk-full (`errno 112`); the current Android attempt failed separately during network artifact download.
