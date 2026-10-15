# BurgerBites — Production Readiness Audit

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[SECURITY]] · [[TESTING]] · [[NEXT_SESSION]]

Audit date: 2026-10-15. The audit covers the Flutter repository and local AMPPS tooling. This work does **not** declare the app production-ready.

## Database setup update (2026-10-14)

The user identified the phpMyAdmin database as `Burger_Bites`. Read-only inspection confirmed it was empty, so migration `001_initial_schema.sql` was applied there; MySQL reports the normalized database name as `burger_bites`. A restricted `burger_bites_app` account and ignored `backend/.env` were configured. A live PHP HTTP request to `GET /api/v1/products` returned HTTP 200 with an empty list. The optional sample catalog was not inserted, and `streetfood_db` was not changed. Port 8080 belongs to Tomcat, so run the API on port 8081. See [[DATABASE_SCHEMA]] and [[TESTING]].

Latest implementation update (2026-10-15): customer catalog/order history/settings/support and admin dashboard/order/product/customer/support flows now call SQL-backed PHP routes. Migration `003_app_workflows.sql` adds required fields/tables and has **not** been imported. The local PHP API was stopped during this latest pass, so these newly added routes have not had live integration checks.

## Architecture inspected

- Flutter 3.47.6 / Dart 3.13.5 mobile-first client. `lib/main.dart` starts `AppShell`; `AppRouter` maps screens; Provider manages session, catalog, orders, cart, and admin data.
- A dependency-free PHP 8/PDO API and versioned migrations under `backend/` support authentication, profiles/preferences, product catalog, favorites, COD orders/history, admin operations, and contact messages.
- The catalog/order/admin screens call the API in code; optional seed `002` and required workflow migration `003` are pending in phpMyAdmin.
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
| Flutter automated tests | Implemented and tested | 9 tests passed: startup, admin profile/password controls, customer address and notification preference settings, Contact screen verified-detail state, cart math/availability, customized cart merging, and per-configuration quantity changes. They do not cover live API calls. |
| Customer/admin auth code | Partially verified | Temporary customer registration, `/me`, logout, and customer-to-admin 403 boundary passed. Admin login, `/me`, readiness authorization, password change, and logout passed. Refresh/session restoration remain untested. One development admin exists; no default credentials are embedded. |
| Profile and default address | Partially verified | Customer profile `PUT /me` saved, loaded, and cleared the default address in a live temporary-account check; admin password change also passed. Multiple saved addresses are not supported. |
| Favorites | Connected in code, not live-verified | User-scoped API endpoints exist, but their database workflow has not been tested against a populated catalog. |
| Product browse/search | Connected in code | Flutter home/menu/search use the SQL catalog API; optional menu seed is not present. |
| Cart calculation | Implemented and tested as a preview | Provider math tested. Backend recomputes authoritative totals; no SQL order test ran. |
| COD order placement/history | Connected in code, not live-verified | Server validates customizations/prices/stock, saves orders, and supports customer pending cancellation with restock. Requires migration 003 for customization data/status values. |
| Admin product/order/customer/support | Connected in code, not live-verified | PHP role-checked routes cover dashboard, inventory CRUD/archive, order lifecycle, customer activation, and support inbox. Requires migration 003. Admin authentication and readiness authorization were smoke-tested. |
| Google/Apple sign-in and online payment | Not implemented | Provider credentials/token verification and payment service/callbacks are absent. |
| MySQL schema | Partially configured | Seven core tables from migration `001` are installed in `burger_bites`; workflow migration `003` and optional sample data `002` are pending. |
| Android APK/runtime | Blocked | Gradle could not resolve `storage.googleapis.com`; no APK produced. No Android device/emulator connected. |
| Hosting protections | Not implemented | No public host/domain, TLS certificate, CDN/WAF/DDoS service, monitoring, or backup process configured. |

## Remaining work by priority

1. Back up the confirmed `Burger_Bites` database, import migration `003` once, start the PHP API, and live-test auth, catalog, COD customization, history/cancel/restock, admin status/CRUD/customer/support routes.
2. Add verified menu data before enabling real ordering; do not treat optional development seed rows as real restaurant data.
3. Import optional sample catalog migration `002` only for a local preview; replace it with verified BurgerBites products/prices/stock before real orders.
4. Implement GCash/Maya only after sandbox credentials, webhook/callback details, and settlement rules are supplied; COD remains the only active payment method.
5. Decide actual tax/delivery/stock rules; complete notifications, GPS tracking, social sign-in, account recovery, app-wide localization/theme, image upload, and saved addresses. Calendar reminders are account-scoped SQL records in code but require migration 003 and live verification; they do not send alerts.
6. Use the provided screenshots for design review; run layout checks on Android phone/emulator when available.
7. Retry the Android build after DNS/network access to `storage.googleapis.com` works; verify on a device.
8. Configure production host, HTTPS, DNS, firewall/proxy, backups/restoration, monitoring, and incident response after choosing a provider.

## Verification record

- `php -l` on all PHP files: passed.
- Local PHP HTTP configuration smoke check: passed; with no database settings, the app returned a safe JSON `503`. This verifies bootstrap/error handling only.
- MySQL setup and PHP database connection: passed. Verified all seven core tables through the restricted app account; `GET /api/v1/products` returned HTTP 200 with an empty list.
- Read-only migration 003 preflight: passed for the live baseline columns and `order_items.uq_order_product` index referenced by its `ALTER TABLE` statements, compatible user/product foreign-key types and collations, and InnoDB engines. Migration has not been applied; this check does not verify the full import.
- `dart format` on modified Dart files: completed, 0 changes on final formatting pass.
- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --reporter expanded --no-pub`: earlier run passed, 4 tests.
- Latest 2026-10-15 UI follow-up: `dart format` completed; `flutter analyze --no-pub` passed; `flutter test --no-pub` passed 9 tests, including Contact details/form and Settings preference coverage. The Web build from the preceding customer-settings pass succeeded; it was not rerun after the Contact/About/Cart/Admin dashboard/Language/Theme/Settings updates. Earlier PHP source syntax and live auth/address API checks passed. The readiness endpoint reports migration 003 missing; cart/order/reminder/inventory/customer/favorites/support routes remain unverified until it is imported. Local Graphify is at 1,647 nodes, 2,627 edges, 108 communities and still reports the pre-existing Linux header parse warning.
- Android `flutter build apk --debug --no-pub`: failed while Gradle tried to download Flutter artifacts; DNS could not resolve `storage.googleapis.com`. No APK was produced.
- Favorites, order integration journeys, payment, external login, deployment, refresh/session restoration, and Android device tests were not performed. Customer registration and admin auth/profile-password API checks are recorded above.
- C: had about 0.32 GB free after Flutter tests; more space is needed before further builds.
- The earlier user-reported Edge compile error was disk-full (`errno 112`); the current Android attempt failed separately during network artifact download.
