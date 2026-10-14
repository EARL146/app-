# Known Issues and Blockers

[[PROJECT_HOME]] · [[PRODUCTION_READINESS_AUDIT]] · [[TESTING]] · [[NEXT_SESSION]]

## Backend and database

- PHP/MySQL is configured locally. The confirmed empty `Burger_Bites` database (`burger_bites`) now has the seven core tables from migration `001`; the restricted `burger_bites_app` account and ignored `backend/.env` are configured.
- `GET /api/v1/products` was verified over HTTP against the database and returns an empty list until menu data is added. Optional sample catalog migration `002` remains unapplied.
- Port `8080` is occupied by `Tomcat10`; run the PHP API on port `8081`.
- `streetfood_db` remains untouched. Flutter auth/profile/favorites/order requests still need `BURGER_BITES_API_BASE_URL` at run/build time; menu/search and admin CRUD/order history still use local sample data.
- Menu/search and admin CRUD/order history still use local sample data; the public products API is not connected to those screens.
- PHP admin operations, customer order history, saved-address collection, and order cancellation/restock lifecycle are not implemented.

## Development workflow tools

- RTK 1.0.0 is installed and the project hook is registered. Restart Codex and trust the project hook if prompted; actual hook execution in this Desktop session has not been observed. If PowerShell cannot find `rtk`, open a new terminal or use `C:\Users\shizu\.local\bin\rtk.exe`.
- ICM 0.11.4 is enabled as a local Codex MCP server and its tools are available. Per-project initialization reported a Windows error writing its install manifest; MCP currently uses the local global database. No cloud account or source upload is configured.
- Graphify local 0.9.90 is installed with its Codex skill. The code-only local graph is built at ignored `graphify-out/`; it is not part of Git. No hosted Graphify account or upload is configured.
- Git remote `origin` points to `https://github.com/EARL146/app-.git`; `main` tracks `origin/main`. Read-only GitHub reachability succeeded. Current changes are authorized for publication; verify the remote hash after each push and never force-push.
- `.obsidian/workspace.json` is tracked and currently modified. Do not stage it; the ignore rule does not affect a file Git already tracks.

## Product/payment/provider setup

- Figma URL was inaccessible. The provided screenshots and logo are used; exact Figma comparison remains unverified.
- Google/Apple OAuth credentials and server identity-token verification are missing.
- Online payment provider, credentials, webhook, and settlement checks are missing; COD is the only selectable checkout option.
- DNS/TLS hosting, CDN, WAF, DDoS protection, logs/alerts, and backup/restore are not configured.

## Verification environment

- Flutter tests passed 4 cases in this session; see [[TESTING]].
- Flutter and Android SDK are installed; no Android phone/emulator is connected. `flutter doctor` reports Chrome absent and incomplete Visual Studio C++ components; Edge is available for Web.
- Android debug APK build failed before compilation because Gradle could not resolve `storage.googleapis.com`; no APK was produced. See [[TESTING]].
- Existing source notes about the prior low-disk Edge build are historical; current available disk was higher, but release build/runtime behavior remains unverified.
