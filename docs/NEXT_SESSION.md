# Next Session — BurgerBites

[[PROJECT_HOME]] · [[INTEGRATION_MAP]] · [[AGENT_TEAM]] · [[AGENT_MONITOR]] · [[BACKUP_WORKFLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[KNOWN_ISSUES]] · [[TESTING]]

## Hosting direction and local verification (2026-10-16)

- Hostinger domain and hosting are the planned deployment target, but have not been purchased or configured. Do not treat the app as deployed. Once available, verify the plan's PHP/PDO-MySQL support, database version, HTTPS, rewrite rules, backups, and environment-secret configuration before deployment.
- Restarted the local API at `http://127.0.0.1:8081`. `GET /api/v1/products?limit=1` returned HTTP 200 with zero products; `GET /api/v1/store-profile` returned HTTP 503 because migration `003_app_workflows.sql` is still not imported. The browser CORS preflight for `http://localhost:5000` returned HTTP 204.
- `flutter analyze --no-pub` reported no issues (118.4 seconds); `flutter test --no-pub` passed all 10 tests. These checks do not verify workflows that require migration 003 or a populated catalog.
- To avoid the Flutter "API is not configured" message during local Edge development, pass `--dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1`; the full local commands are in [[backend/README]].
- Next database step remains: export a backup in phpMyAdmin, import migration 003 once, and verify Admin More reports the workflow schema ready. Optional migration 002 contains development sample menu data only.

## Flutter mobile UI audit (2026-10-16)

- Fixed small-phone layout issues in welcome/auth, customer home, and the admin dashboard; customer and admin header menu controls now open their existing destinations. Search no longer implies voice search or preloads sample history, and reports empty/error states based on actual catalog data.
- `flutter test --no-pub --reporter expanded`: all 14 tests passed. `flutter analyze --no-pub`: no issues. Widget tests cover 320, 360, 390, and 430 px for welcome/auth, customer home, and admin dashboard; search empty state is checked at 320 px.
- `graphify update .` completed locally (1,860 nodes, 3,031 edges, 125 communities); existing `linux/runner/my_application.h` parser warning remains. No device/emulator visual review was performed. See [[SCREEN_IMPLEMENTATION_STATUS]] for remaining whole-project and backend limitations.

## AI agent monitoring system (2026-10-16)

- Added a standalone read-only local dashboard under `tools/agent-monitor/`; Obsidian remains the project memory source. The Agents tab now tracks named roles Agent 1 Frontend Developer, Agent 2 Backend/API Developer, Agent 3 QA Tester, and Agent 4 Code Reviewer. Setup and data limits: [[AGENT_MONITOR]] and [[AGENT_TEAM]].
- It reads actual local Codex JSONL session markers/tool names/exit codes and supported thread usage fields, local Git status/diffs, selected `docs/` notes, existing project images, and browser-only user-selected image/Markdown files. Prompt bodies, tool arguments, command text/output, and external uploads are excluded.
- Named-role data comes only from explicit entries in the ignored local event ledger; dashboard metrics are descriptive run/check counts, not a live API or quality score. Each run now shows event timeline, blocker labels, verification counts, and task-related paths.
- RTK 1.0.0 is installed. Project and global Codex hooks are registered, but `rtk gain` still reports no active hook in this session; restart Codex and approve any trust prompt, then verify activation. Graphify Local 0.9.90 updates code graph locally and its report/view are linked from [[AGENT_TEAM]]. ICM MCP is available for durable memory and transcript tools, not live agent events. GTX remains unidentified.
- The current monitor check results and known setup limits are recorded in [[AGENT_MONITOR]]. No app/API/database schema changes or push were made for this monitoring work.
- The separate monitor now has a Windows point-in-time process card matched by executable basename, in addition to JSONL-derived session history and explicit role events. It does not identify process publisher/path or correlate a process to a session or role. See [[AGENT_MONITOR]] for the 19-test result and HTTP/native smoke checks.
- Agent City now moves all four pixel-art figures between Command HQ and their assigned station from recorded task state: Agent 1/3 prefer the latest isolated Codex worker task and fall back to a newer explicit role-log entry; Agent 2/4 use explicit role-log entries only. The five-second refresh also shows source, status, task, and location cards; reduced-motion settings disable animation. Role-log activity is not proof of a running process. The original 3D city remains available; see [[AGENT_MONITOR]].
- Latest local monitor snapshot had no Codex worker task and one active explicit role-log record for Agent 1; that log does not verify a running Codex process. JavaScript syntax checks, served-page checks, and `git diff --check` passed; see [[AGENT_MONITOR]].
- Local checkpoint commit `3d3be2d` contains only the reviewed monitor implementation/docs; it was not pushed. Existing `.obsidian/graph.json`, `.obsidian/workspace.json`, `package-lock.json`, and mixed `docs/NEXT_SESSION.md` changes remain outside that commit.
- After the checkpoint, the Windows process snapshot, UI, tests, and integration notes were updated locally but are not committed. `graphify update .` refreshed the local code graph to 1,842 nodes / 3,007 edges / 117 communities; no label/LLM pass or upload was run.

## Customer/admin visual and store-profile pass (2026-10-15)

- Added transparent cutout assets `assets/branding/burger_bites_logo_cutout.png` and `assets/products/smash_burger_cutout.png`; the source logo/product images remain preserved.
- `BrandLogo` now uses the transparent chef-burger art. Registration and sign-in logos have a subtle motion; the welcome hero uses an isolated photoreal burger cutout with floating/tilting movement and a shifting studio glow. Motion respects the system reduced-motion setting.
- Added an admin Store Profile editor, linked from Admin More, for verified public contact, address, hours, coverage, and social details. Customer Contact reads only public data from `/store-profile`; no details are invented.
- Verification: both PNGs have transparent corners and are included in `build/web`; Flutter analyze passed, all 10 tests passed (including the admin Store Profile field check), and the standard JavaScript Web build succeeded. The Web builder emitted its existing Wasm dry-run warning for `flutter_secure_storage_web`; it did not prevent the Web build.
- A read-only `GET /api/v1/store-profile` returned HTTP 503. This is expected until migration 003 is imported because it creates `store_profile`; no schema changes were applied.
- Additional core-schema HTTP smoke checks passed favorites list/add/remove and profile read/update, fresh login, logout, and session revocation. Temporary test customer/product rows and login rate-limit records were removed; a direct count confirmed no `codex-fav-*` products or temporary smoke users remain.

## Latest customer/admin SQL workflow pass (2026-10-15)

- Customer catalog, search, favorites, account-synced cart, COD order submission, SQL order history/cancellation/reorder, burger size/topping validation and persistence, profile/password changes, preferences, and support message submission now call the PHP API.
- Admin order status/stock flow, catalog CRUD/inventory, customer status controls, dashboard totals, and support inbox/status updates now call the API. Product deletion archives the product to preserve order references.
- Admin More now checks database reachability and migration 003 readiness through an admin-only API route. Removed sample bank-account details and replaced the false “Demo Mode (No Backend)” status with live API/MySQL/schema states; payment setup shows COD active and GCash/Maya pending sandbox configuration.
- Replaced the admin home’s sample sales curve and fabricated growth percentages with a seven-day SQL order-value series from `/admin/dashboard`.
- Added user-scoped SQL cart storage and load/save/clear routes; successful order creation clears the saved cart in the same transaction. Guest carts remain local until account sign-in.
- Replaced calendar sample milestones with account-scoped reminder create/list/edit/delete UI and PHP routes. Migration 003 now creates `user_calendar_reminders`; reminders are records only and do not send phone, email, or push alerts.
- Added required migration `backend/database/migrations/003_app_workflows.sql`. It is **not yet imported** in phpMyAdmin. Read-only preflight confirmed the baseline columns and `uq_order_product` index referenced by its `ALTER TABLE` statements, compatible user/product foreign-key column types and collations, and InnoDB engines. `GET /api/v1/products?limit=1` previously returned HTTP 200 with an empty catalog, confirming the DB connection. New customer/admin workflows still need migration 003 and end-to-end checks.
- Direct database inspection confirmed the target is `burger_bites` on MySQL 8.0.45 with the seven migration-001 tables. One development admin exists (`admin@burgerbites.local`); there are no customer, product, or order rows. The API account has only CRUD grants, so migration 003 must be imported through phpMyAdmin.
- Created a local development admin account using the supported Argon2id bootstrap path. Live HTTP checks passed admin login, `/me`, authorization for `/admin/system-status`, `/me/password` including a fresh sign-in with the changed password, and logout. A temporary customer registration/`/me`/logout check passed and the customer was denied the admin endpoint with HTTP 403; that user row was deleted. The readiness endpoint correctly reports migration 003 is missing. The current generated password was returned to the user in chat and is not stored in project files.
- Optional seed migration 002 remains unapplied, so catalog screens will show their explicit empty-menu state until real products or the development catalog are inserted.
- GCash/Maya remain disabled; the user selected these providers and will provide sandbox details. No online transaction is simulated. Do not request live production secrets in chat; configure sandbox-only credentials locally in ignored backend environment settings and verify the gateway's official callback/signature requirements before implementation.
- Other unresolved integrations: courier GPS, outgoing SMS/email notifications, Google/Apple login, account recovery/email verification, app-wide localization/palette changes, real image upload, saved-address collection, and rewards/promotions.
- Latest UI follow-up: About copy describes actual app actions; Contact hides unverified business details while retaining the SQL support form; Cart displays the saved profile address rather than a fixed city; the Admin dashboard bell opens SQL-backed pending orders and shows their count; Admin More's Language & Region opens the saved preference screen; Language/Theme previews no longer show invented menu prices; Google/Apple setup messages are explicit; SMS/email/promotion switches explain that they save preferences but do not deliver messages. `dart format` completed, `flutter analyze --no-pub` passed, all 9 Flutter tests passed including checks for the Settings explanations, and `git diff --check` passed. The previous Web build succeeded after the address UI change and was not rerun after this UI pass. Graphify reports 1,648 nodes / 2,628 edges / 110 communities; the existing Linux header parse warning remains.
- Earlier API verification: PHP syntax checks passed for all 5 files under `backend/src`. The `http://localhost:5000` CORS preflight returned 204, catalog returned 200, and an unapproved origin returned 403. The admin profile widget test verifies account/password/logout controls and empty-current-password validation; valid password change and re-login passed separately over HTTP. A temporary customer saved/read/cleared the default address over HTTP and was removed. The calendar screen has no dedicated widget test. The dashboard query returned 7 date buckets. Admin login/session/password change and customer registration/role denial passed over local HTTP. Migration 003 remains unapplied, so cart/order/reminder/inventory/customer-management/support routes still need end-to-end checks.
- Git worktree remains uncommitted. Existing local Obsidian state and intro/welcome changes are preserved; no commit or push was made.

### Next task

Back up `Burger_Bites`, import migration 003 using phpMyAdmin's privileged Import account, and add verified menu products (or import optional seed 002 for a clearly identified preview). Then exercise registration, saved cart, COD customized order, cancellation/restock, and admin product/order/customer/support routes with the existing development admin. Collect GCash/Maya sandbox details before implementing online payments.

## Current state (2026-10-14)

- Flutter customer/admin screens, PHP API routes, SQL migrations, and the local MySQL setup are present. The app is not production-ready; see [[PRODUCTION_READINESS_AUDIT]].
- Earlier targeted verification: Dart analysis and all 4 Flutter tests passed; PHP syntax checks passed. APK build did not complete because DNS could not resolve `storage.googleapis.com`; no APK was produced.
- Migration `001` is installed in `burger_bites`; the restricted API account connects, and `GET /api/v1/products` returned HTTP 200 with an empty catalog. `streetfood_db` was not opened or changed.
- This repository contains the BurgerBites UI/auth/API/documentation work and local tool integrations. The user explicitly authorized publication of this change set to `origin/main`.
- RTK 1.0.0 is installed at `C:\Users\shizu\.local\bin\rtk.exe`; `rtk --version`, `rtk gain`, and `rtk init --codex` succeeded. Project hook and `RTK.md` are present. A new PowerShell/Codex session may be needed to reload the updated PATH and approve the project hook.
- ICM 0.11.4 is enabled as a Codex MCP server and its MCP handshake/tools are available. Per-project initialization reported a Windows manifest-write error, so it currently uses the local global database.
- Graphify local 0.9.90 and its Codex skill/hook are installed. Code-only extraction plus clustering produced 1,182 nodes, 1,782 edges, and 73 communities in ignored `graphify-out/`.
- Startup intro and Get Started UI are implemented: new sessions see a 4.5-second ingredient assembly then the welcome screen, while restored sessions still go directly to their role home. Get Started opens registration and Log In opens sign-in. The existing logo and smash-burger photo are reused.
- Obsidian settings exist in the project root, but whether this folder is registered/open in the user's Obsidian window and whether account Sync is active are **UNVERIFIED**. See [[OBSIDIAN_SETUP]].

## Completed in the workflow and integration pass

- Added repository guidance in [[AGENTS]].
- Documented the manual/automated boundary and integration status in [[INTEGRATION_MAP]].
- Documented how to open this project folder as the Obsidian vault in [[OBSIDIAN_SETUP]].
- Documented safe Git review and backup steps in [[BACKUP_WORKFLOW]].
- Updated project indexes and corrected the vault-registration claim to describe only the verified `.obsidian/` folder.
- Installed and verified RTK, ICM, and local Graphify. No hosted account, cloud memory, or source upload was configured.
- Generated graph output and `.obsidian/graph.json` / `.obsidian/workspace.json` are local state and must not be staged. `backend/.env` is ignored; never read or commit it.
- Updated `lib/screens/customer/splash_screen.dart`, `lib/widgets/animated_burger_assembly.dart`, and `lib/screens/customer/welcome_screen.dart` for the ingredient intro and responsive welcome screen. Updated the startup widget test and [[SCREEN_FLOW]]. Authentication/session logic and other app features were left in place.

## Verification performed for this workflow

- RTK 1.0.0: the executable works for a PowerShell `rtk git status` run, but RTK itself reports that no hook is installed; see [[AGENT_MONITOR]].
- ICM MCP tools are available in this Codex environment for memory/transcript operations; no live agent-event feed is exposed to the monitor.
- Graphify Local 0.9.90 is installed; focused query/update worked. Latest graph update: 1,743 nodes, 2,810 edges, 114 communities, with the existing `linux/runner/my_application.h` parsing warning. The monitor does not use Graphify at runtime.
- `flutter analyze --no-pub`: no issues. Earlier project verification: 4 Flutter tests passed and PHP syntax checks passed. APK build remains blocked by DNS resolution of `storage.googleapis.com`.
- Startup/Get Started verification (2026-10-14): `flutter analyze --no-pub` reported no issues; `flutter test --no-pub` passed all 4 tests.
- `git ls-remote --heads origin main` verified read-only access and the current remote branch before publication. Recheck the remote head after pushing.
- `git check-ignore --no-index -v backend/.env.example` confirms the template remains trackable; `git check-ignore -v backend/.env` confirms the secret file is ignored. Secret contents were not read.
- `git diff --check` and `git diff --cached --check` passed; Git emitted only existing working-copy LF-to-CRLF notices. A targeted check of Markdown and Obsidian links in the project/workflow index notes found no missing targets. Flutter analysis passed in this integration pass; app tests and PHP syntax checks passed earlier in this project work and were not rerun just for tool installation.

## Highest-priority next task

Import migration 003 with the privileged phpMyAdmin account, confirm Admin More reports schema ready, then verify store-profile read/save and the SQL-backed cart, COD order, cancellation/restock, inventory, customer, support, and reminder workflows. The store-profile editor is now implemented in the app but awaits that migration.

## Safety constraints

- Do not point the app at `streetfood_db`; `burger_bites` is the confirmed local target.
- Never commit `.env`, database credentials, OAuth secrets, payment keys, tokens, personal customer data, or `.obsidian/workspace.json` changes.
- Do not deploy publicly, stage local Obsidian/Graphify state or ignored secrets, or alter production data without explicit authorization.
- Keep local preview data labeled until screens are connected to verified API responses.
