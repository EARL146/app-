# Known Issues and Blockers

[[PROJECT_HOME]] · [[PRODUCTION_READINESS_AUDIT]] · [[TESTING]] · [[NEXT_SESSION]]

## Backend and database

- PHP/MySQL is configured locally. The confirmed empty `Burger_Bites` database (`burger_bites`) now has the seven core tables from migration `001`; the restricted `burger_bites_app` account and ignored `backend/.env` are configured.
- Read-only `GET /api/v1/products?limit=1` returned HTTP 200 with an empty list on 2026-10-15, confirming the PHP API can read the current database. Optional catalog seed `002` remains unapplied; the customer menu is empty until products are added.
- Direct inspection confirmed one local development admin account exists (`admin@burgerbites.local`); its generated password was shared with the user in chat and is not stored in the repository. There are no customer, product, or order rows. This local-only address is a login name, not a Gmail inbox.
- Port `8080` is occupied by `Tomcat10`; run the PHP API on port `8081`.
- `streetfood_db` remains untouched. The app needs `BURGER_BITES_API_BASE_URL` at run/build time and the local PHP server on port 8081.
- Migration `003_app_workflows.sql` is required by saved carts, order customizations/statuses, preferences, support, account controls, and persistent calendar reminders. It is in the repository but not yet imported into phpMyAdmin.
- Admin More now has a read-only, admin-authenticated readiness endpoint for database access and migration 003. Use it to confirm schema installation from inside the app after import.
- The Admin Store Profile editor and customer public store-details view are implemented. Their API routes currently return HTTP 503 until migration 003 creates `store_profile`; save/read cannot yet be end-to-end verified.
- Live local HTTP smoke checks verified admin login, `/me`, admin authorization on `/admin/system-status`, and logout. Isolated temporary-customer checks passed profile update/read, fresh login, logout revocation, and favorites add/list/remove on the core schema; the temporary records were removed. The readiness status correctly reports migration 003 missing. Cart, reminder, order, inventory, customer-management, support, and store-profile workflows still need migration 003 and end-to-end checks.
- The admin profile now includes a password-change action. Its `/me/password` API flow passed a live check; a widget test verifies the profile/password/logout controls render and the dialog rejects an empty current password. Valid password-change submission is verified through HTTP rather than Flutter UI automation.
- Guest cart contents remain in memory until sign-in; signed-in customer carts use SQL. Calendar reminder routes and UI are implemented in code but await migration 003 and live checks. Reminders do not send alerts. Multiple saved addresses are not implemented.

## Development workflow tools

- RTK 1.0.0 is installed and the project hook is registered. Restart Codex and trust the project hook if prompted; actual hook execution in this Desktop session has not been observed. If PowerShell cannot find `rtk`, open a new terminal or use `C:\Users\shizu\.local\bin\rtk.exe`.
- ICM 0.11.4 is enabled as a local Codex MCP server and its tools are available. Per-project initialization reported a Windows error writing its install manifest; MCP currently uses the local global database. No cloud account or source upload is configured.
- Graphify local 0.9.90 is installed with its Codex skill. The code-only local graph is built at ignored `graphify-out/`; it is not part of Git. No hosted Graphify account or upload is configured.
- Git remote `origin` points to `https://github.com/EARL146/app-.git`; `main` tracks `origin/main`. Read-only GitHub reachability succeeded. Current changes are authorized for publication; verify the remote hash after each push and never force-push.
- `.obsidian/workspace.json` is tracked and currently modified. Do not stage it; the ignore rule does not affect a file Git already tracks.

## Product/payment/provider setup

- Figma URL was inaccessible. The provided screenshots and logo are used; exact Figma comparison remains unverified.
- Google/Apple OAuth credentials and server identity-token verification are missing.
- GCash/Maya were selected, but sandbox credentials and callback/webhook details have not been supplied. COD is the only active payment method; online options remain disabled.
- DNS/TLS hosting, CDN, WAF, DDoS protection, logs/alerts, and backup/restore are not configured.

## Verification environment

- Latest Flutter test run passed 10 tests; see [[TESTING]].
- Flutter and Android SDK are installed; no Android phone/emulator is connected. `flutter doctor` reports Chrome absent and incomplete Visual Studio C++ components; Edge is available for Web.
- Android debug APK build failed before compilation because Gradle could not resolve `storage.googleapis.com`; no APK was produced. See [[TESTING]].
- Existing source notes about the prior low-disk Edge build are historical; current available disk was higher, but release build/runtime behavior remains unverified.
