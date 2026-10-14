# Changelog

Record significant project changes.

## 2026-10-14 — Local development tools and GitHub publication
- Files changed: RTK project hook and `RTK.md`; ICM MCP registration in local Codex config; Graphify project skill and hooks; `.gitignore`; tool workflow, decision, blocker, and session notes.
- What changed: Installed RTK 1.0.0 and Graphify local 0.9.90; registered their project Codex integrations; enabled ICM 0.11.4 as a local MCP server. Graphify built a code-only project graph locally (1,182 nodes, 1,782 edges); generated output remains ignored. User PATH entries were added for all three executables.
- ICM limitation: MCP is enabled and available, but per-project initialization reported a Windows error writing its install manifest. The MCP server currently uses ICM's local global database.
- Privacy: No hosted Graphify account, Graphify service upload, cloud memory, or credentials were configured. GitHub publication is user-authorized. Obsidian UI state and generated Graphify output are excluded from the Git changes.
- Verification: RTK version/gain/init succeeded; ICM MCP handshake and Codex registration succeeded; Graphify local code-only extraction and clustering succeeded; `flutter analyze --no-pub` found no issues. Flutter tests and PHP syntax checks had passed earlier in this project work.
- Publication: The user explicitly authorized committing and pushing this project set to `origin/main`; verify the resulting remote branch before completing the backup.

## 2026-10-14 — Connect local MySQL database
- Files changed: `backend/.env.example`, `backend/README.md`, and database, setup, API, security, system-flow, testing, audit, and Obsidian index notes.
- What changed: Confirmed the user's empty `Burger_Bites` database, applied the seven-table initial schema, created a least-privilege local API account, configured ignored local secrets, and used the supplied screenshots as the UI reference.
- Tests performed: PDO connected through the app account; the products API returned HTTP 200 with an empty product list. Existing data tables were empty before setup; no customer, order, or sample menu rows were added.
- Remaining issues: Full account and checkout journeys, admin APIs, menu data, and production setup still need work. Port 8080 is used by Tomcat; local PHP uses 8081.

## 2026-10-14 — Client hardening and isolated PHP API
- Files changed: Flutter startup/auth/profile/favorites/checkout/router/providers/screens; Android manifests; `backend/` PHP API, admin bootstrap helper, `.env.example`, SQL migrations; Dart tests; README and audit/setup/security/API/database/testing notes.
- What changed: Added the supplied logo and initial navigation; removed client demo admin credentials; added server-issued sessions, profile/favorites/COD order paths; created a PHP API with Argon2id, opaque rotating tokens, rate limiting, prepared queries, user-scoped favorites, and transactional stock/order creation; added schema and a development-only catalog seed.
- Database/API changes at the time of this initial code pass: API routes and schema files were added, but migrations had not yet been applied. The follow-up database setup is recorded above. Admin operations and order history are still missing.
- Tests performed: 4 Flutter tests passed; `flutter analyze --no-pub` passed; modified Dart files formatted; `php -l` passed for all PHP files.
- Build status: Android APK build failed before app compilation because DNS could not resolve `storage.googleapis.com`; no APK was produced.
- Remaining issues: No database/API end-to-end verification, admin APIs, Flutter catalog/order-history wiring, Android device run, production hosting/security setup, OAuth, or online payment.

## 2026-10-14 — Whole-system flow documentation
- Files changed: `docs/SYSTEM_FLOW.md`, `docs/SCREEN_FLOW.md`, `docs/PROJECT_HOME.md`, `docs/README.md`, `docs/PROJECT_MAP.md`, `docs/FILE_REGISTRY.md`, `docs/CHANGELOG.md`.
- What changed: Added current app startup, sign-in, customer checkout, admin operations, provider/service connections, and route diagrams with plain-language algorithms. Linked the system flow from Obsidian's project indexes.
- Dependencies or API changes: None.
- Tests performed: No code changed; documentation paths and source behavior were inspected.
- Remaining issues: Current app actions remain demo-only/in-memory; no verified live backend or payment connection.

## 2026-10-14 — Development workflow and tool audit
- Status note: This was the initial audit snapshot; its RTK/ICM/Graptify status was superseded by the later-added local tool installation entry above.
- Files changed: `AGENTS.md`, `.gitignore`, root `README.md`, and project documentation including `PROJECT_MAP`, `PROJECT_HOME`, `SCREEN_FLOW`, `DECISIONS`, `KNOWN_ISSUES`, `NEXT_SESSION`, `CHANGELOG`, `INTEGRATION_MAP`, `OBSIDIAN_SETUP`, and `BACKUP_WORKFLOW`.
- What changed: Documented the local Obsidian vault setup, manual/automated workflow, safe GitHub backup review, and tool integration matrix. Recorded ICM and Graptify as UNVERIFIED because the user has no official URLs. Corrected the claim that the vault was already registered.
- RTK: Official Windows instructions were reviewed, but the CLI was not installed: `winget` is absent and C: had about 8 MB free. Codex Desktop hook support remains UNVERIFIED. No RTK hook, telemetry, external account, or upload was enabled.
- Verification: Inspected Git branch/remote/status and ignore rules. No code tests or build were run for this documentation-only pass. No files were staged, committed, or pushed.
- Remaining issues: Git worktree has extensive pre-existing app/backend changes; `.obsidian/workspace.json` is tracked and modified and must not be staged. Confirm Obsidian opens the project root in the user's window. ICM/Graptify identities remain unknown.

## Entry template
- Date:
- Files changed:
- What changed:
- Dependencies or API changes:
- Tests performed:
- Remaining issues:
