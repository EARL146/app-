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

The four Flutter tests do not exercise API calls, secure storage, login/register forms, profile editing, favorites persistence, checkout server responses, SQL, admin authorization, or cross-account access. PHP lint checks syntax only. No HTTP/MySQL integration test was run. The Android build did not produce an installable APK.

## Environment notes

- Flutter 3.47.6 / Dart 3.13.5 and Android SDK are installed.
- No Android phone/emulator is connected. Edge is available; Chrome was not detected.
- After final Flutter tests, C: had about 0.32 GB free, so further builds may fail from disk pressure. Move temp output to D: and free additional C: space before an Android build.
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
