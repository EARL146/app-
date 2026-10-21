# Testing and Verification

[[PROJECT_HOME]] · [[SETUP_GUIDE]] · [[KNOWN_ISSUES]] · [[SCREEN_IMPLEMENTATION_STATUS]]

## Results from 2026-10-14

| Check | Result | Evidence / scope |
| --- | --- | --- |
| `flutter pub get` | Passed | User's terminal output showed dependencies resolved. Package update notices were informational. |
| `dart format` on modified Dart files | Passed | Final run formatted 26 files; 0 changes needed. |
| `flutter analyze --no-pub` | Passed | No issues found (9.2 seconds). |
| `flutter test --reporter expanded --no-pub` | Passed | 4 tests: initial splash/greetings/sign-in navigation and cart merging, totals, unavailable product, and quantity removal. |
| `php -l` across all `backend/**/*.php` | Passed | No PHP syntax errors. Does not test SQL or runtime DB behavior. |
| PHP HTTP configuration smoke check | Passed | Initial configuration check returned safe JSON `503` before DB setup. |
| MySQL schema setup | Passed | Confirmed `burger_bites` was empty, applied migration `001`, and verified the seven core tables through the restricted API account. |
| PHP/PDO database connection | Passed | API database code connected as `burger_bites_app`; `information_schema` showed seven tables. No secrets were printed. |
| PHP HTTP products route | Passed | Temporary PHP server returned HTTP 200 and `{"products":[],"limit":20,"offset":0}` from MySQL-backed `GET /api/v1/products`; no sample products were seeded. |
| Android `flutter build apk --debug --no-pub` | Failed before app compilation | Gradle could not resolve `storage.googleapis.com` to download Flutter engine artifacts; automatic retry was stopped. No APK was produced. |
| Android device journey | Not run | `flutter devices` showed Windows and Edge only; no phone/emulator. |
| `flutter run -d edge` from user's terminal | Previously failed | User saw Dart unable to write `app.dill` because C: ran out of space (`errno 112`). |

## Test coverage limits

The Flutter tests do not exercise API calls, secure storage, login/register forms, profile editing, favorites persistence, checkout server responses, SQL, or cross-account access. The admin auth/session smoke check validates the local admin and readiness route only; it does not cover order, inventory, customer, support, cart, or reminder workflows. PHP lint checks syntax only. The Android build did not produce an installable APK.

## Results from 2026-10-15

| Check | Result | Evidence / scope |
| --- | --- | --- |
| `flutter analyze --no-pub` | Passed | No issues found after customer/admin workflow updates. |
| `flutter test --no-pub` | Passed | 10 tests: startup, admin profile controls, admin store-profile fields, customer address and notification preferences, contact screen details, cart totals/availability, customized cart merging, and customized-line quantity changes. |
| `flutter build web --no-pub` | Passed | Built `build/web` for Edge. Flutter's Wasm dry run reported `flutter_secure_storage_web` imports unsupported by Wasm; the standard JavaScript Web build succeeded. |
| `php -l` across `backend/src/*.php` | Passed | No syntax errors in all 5 source files. |
| Edge-origin PHP API/CORS check | Passed | `http://localhost:5000` preflight returned 204 and catalog returned 200; an unapproved origin returned 403. Catalog is empty until products are added. |
| Dashboard sales query | Passed | Read-only direct SQL check returned 7 daily buckets; no order details were output. |
| `git diff --check` | Passed | Git emitted only working-copy LF-to-CRLF notices. |
| Authenticated admin API smoke test | Passed | Login, `/me`, authorized `/admin/system-status`, and logout succeeded against local MySQL. |
| Admin password change HTTP flow | Passed | `/me/password` accepted the current credential, kept the current session valid, and allowed a fresh sign-in with the new password; both sessions logged out cleanly. |
| Customer registration/role boundary HTTP smoke test | Passed | Temporary registration returned role `customer`; `/me` confirmed it; `/admin/system-status` returned 403; logout succeeded and the temporary user row was deleted. |
| Default-address profile API | Passed | A temporary customer saved an address through `PUT /me`, loaded it through `GET /me`, cleared it, logged out, and was deleted. |
| Favorites API lifecycle | Passed | Isolated temporary customer/product: list began empty, add returned the product, delete returned to empty; both fixtures were removed. |
| Profile, fresh login, and logout API | Passed | Isolated temporary customer: `/me`, profile update/read, password sign-in, logout, and revoked-token check passed; temporary account and its rate-limit rows were cleaned. |
| Smoke-test cleanup | Passed | Direct read-only verification found zero `codex-fav-*` products and zero temporary smoke users. Product catalog remained empty. |
| Migration 003 workflows | Not run | Current schema readiness response confirms required workflow tables/columns are absent. |
| Store profile API read | Blocked by schema | Read-only `GET /api/v1/store-profile` returned HTTP 503 because `store_profile` is created by migration 003, which is not installed yet. |
| Transparent image assets | Passed | Logo and burger cutout PNGs both report zero alpha at their outer corner; both assets are included in `build/web`. |
| Customer/admin visual update | Passed | `flutter analyze --no-pub`: no issues; all 10 Flutter tests passed; `flutter build web --no-pub` succeeded. Web build emitted the existing `flutter_secure_storage_web` Wasm compatibility dry-run warning; JavaScript build completed. |

## Results from 2026-10-20

| Check | Result | Evidence / scope |
| --- | --- | --- |
| `flutter test --no-pub` | Passed | All 29 tests passed, including customer Home at 320/360/390/430 px, guest order history, auth cross-navigation, route argument validation, product details, and admin dashboard states. |
| `flutter analyze --no-pub` | Passed | No issues found. |
| `flutter build web --no-pub --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1` | Passed | Standard JavaScript Web output built to `build/web`. The Wasm compatibility dry run still warns about `flutter_secure_storage_web` using `dart:html`/`dart:js_util`. |
| PHP syntax (`ApiApplication.php`, `create_admin.php`) | Passed | Both files report no syntax errors. |
| API catalog/store-profile reads | Passed | Loopback API on port 8081 returned HTTP 200; catalog count was 6 and public store-profile read succeeded. No product/store content was printed. |
| Malformed login email | Passed | Array-valued email returned HTTP 401; the PHP server stderr had no array-to-string warning. No valid credentials were used. |
| CORS preflight | Passed | `http://localhost:5000` returned HTTP 204; unconfigured `http://localhost:5001` returned HTTP 403. |
| Authenticated SQL order/admin workflows | Not run | No account credentials were used; complete migration readiness and real order flows remain unverified. |
| `git diff --check` | Passed | No whitespace errors. |

## Environment notes

- Flutter 3.47.6 / Dart 3.13.5 and Android SDK are installed.
- No Android phone/emulator is connected. Edge is available; Chrome was not detected.
- The earlier low-disk warning is superseded: C: had 174.18 GB free before the latest Web build, and that build completed successfully. Android APK compilation remains unverified because Gradle previously could not resolve `storage.googleapis.com`.
- Gradle could not resolve `storage.googleapis.com`; retry the APK build when DNS/network access is available.
- MySQL database `burger_bites` has the initial schema and a restricted local API account. Optional seed migration `002` is still unapplied.
- Port `8080` is occupied by local `Tomcat10`; use `8081` for the PHP API.

## Commands to repeat after setup

```powershell
flutter analyze --no-pub
flutter test --reporter expanded --no-pub
php -l backend/public/index.php
flutter build apk --debug --no-pub
```

Start the API from `backend` on port `8081` (port `8080` is used by Tomcat):

```powershell
php -S 127.0.0.1:8081 -t public public/index.php
```

Run Flutter Web with the API URL:

```powershell
flutter run -d edge --web-port=5000 --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1
```

See [[SETUP_GUIDE]] and [backend/README.md](../backend/README.md).
