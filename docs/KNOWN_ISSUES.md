# Known Issues and Blockers

[[PROJECT_HOME]] · [[PRODUCTION_READINESS_AUDIT]] · [[TESTING]] · [[NEXT_SESSION]]

## Backend and database

- Current local check (2026-10-20): MySQL listened on port 3306 and the PHP API returned HTTP 200 for public products and store-profile routes. The products response contained 6 records. The full workflow-schema readiness endpoint and authenticated user/order routes were not checked in this pass.
- The `Burger_Bites` database (`burger_bites`) has the seven core tables from migration `001`; the restricted `burger_bites_app` account and ignored `backend/.env` were configured earlier. The 2026-10-15 inspection found no customer or order rows; current customer/order counts were not checked.
- The 2026-10-15 inspection found one local development admin account (`admin@burgerbites.local`); its generated password was shared with the user in chat and is not stored in the repository. This local-only address is a login name, not a Gmail inbox; current account state was not rechecked.
- Port `8080` is occupied by `Tomcat10`; run the PHP API on port `8081`.
- `streetfood_db` remains untouched. The app needs `BURGER_BITES_API_BASE_URL` at run/build time and the local PHP server on port 8081.
- Migration `003_app_workflows.sql` supplies saved carts, order customizations/statuses, preferences, support, account controls, and persistent calendar reminders. Its complete current readiness is **unverified**. `GET /store-profile` returned HTTP 200 on 2026-10-20, confirming that read path works; check Admin More → App Information before relying on the rest of migration 003. Do not import it again unless readiness reports missing items and the database has been backed up.
- Admin More has a read-only, admin-authenticated readiness endpoint. The Admin Store Profile editor and customer public store-details view are implemented; the public read route returned HTTP 200 in the current check. The authenticated save route was not tested.
- Earlier local HTTP smoke checks on 2026-10-15 verified admin login, `/me`, admin authorization on `/admin/system-status`, logout, and isolated temporary-customer profile/favorites behavior. Those flows were not rerun on 2026-10-20. Cart, reminder, order, inventory, customer-management, and support workflows still need authenticated end-to-end checks.
- The admin profile now includes a password-change action. Its `/me/password` API flow passed a live check; a widget test verifies the profile/password/logout controls render and the dialog rejects an empty current password. Valid password-change submission is verified through HTTP rather than Flutter UI automation.
- Guest cart contents remain in memory until sign-in; signed-in customer carts use SQL when the workflow schema is ready. Calendar reminder routes and UI are implemented in code but await authenticated live checks. Reminders do not send alerts. Multiple saved addresses are not implemented.

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

- Latest Flutter verification on 2026-10-20 passed analysis and all 29 tests; see [[TESTING]].
- Flutter and Android SDK are installed; no Android phone/emulator is connected. `flutter doctor` reports Chrome absent and incomplete Visual Studio C++ components; Edge is available for Web.
- Android debug APK build failed before compilation because Gradle could not resolve `storage.googleapis.com`; no APK was produced. See [[TESTING]].
- Existing source notes about the prior low-disk Edge build are historical; current available disk was higher, but release build/runtime behavior remains unverified.
