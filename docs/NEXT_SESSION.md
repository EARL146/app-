# Next Session — BurgerBites

[[PROJECT_HOME]] · [[INTEGRATION_MAP]] · [[BACKUP_WORKFLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[KNOWN_ISSUES]] · [[TESTING]]

## Current state (2026-10-14)

- Flutter customer/admin screens, PHP API routes, SQL migrations, and the local MySQL setup are present. The app is not production-ready; see [[PRODUCTION_READINESS_AUDIT]].
- Earlier targeted verification: Dart analysis and all 4 Flutter tests passed; PHP syntax checks passed. APK build did not complete because DNS could not resolve `storage.googleapis.com`; no APK was produced.
- Migration `001` is installed in `burger_bites`; the restricted API account connects, and `GET /api/v1/products` returned HTTP 200 with an empty catalog. `streetfood_db` was not opened or changed.
- This repository contains the BurgerBites UI/auth/API/documentation work and local tool integrations. The user explicitly authorized publication of this change set to `origin/main`.
- RTK 1.0.0 is installed at `C:\Users\shizu\.local\bin\rtk.exe`; `rtk --version`, `rtk gain`, and `rtk init --codex` succeeded. Project hook and `RTK.md` are present. A new PowerShell/Codex session may be needed to reload the updated PATH and approve the project hook.
- ICM 0.11.4 is enabled as a Codex MCP server and its MCP handshake/tools are available. Per-project initialization reported a Windows manifest-write error, so it currently uses the local global database.
- Graphify local 0.9.90 and its Codex skill/hook are installed. Code-only extraction plus clustering produced 1,182 nodes, 1,782 edges, and 73 communities in ignored `graphify-out/`.
- Obsidian settings exist in the project root, but whether this folder is registered/open in the user's Obsidian window and whether account Sync is active are **UNVERIFIED**. See [[OBSIDIAN_SETUP]].

## Completed in the workflow and integration pass

- Added repository guidance in [[AGENTS]].
- Documented the manual/automated boundary and integration status in [[INTEGRATION_MAP]].
- Documented how to open this project folder as the Obsidian vault in [[OBSIDIAN_SETUP]].
- Documented safe Git review and backup steps in [[BACKUP_WORKFLOW]].
- Updated project indexes and corrected the vault-registration claim to describe only the verified `.obsidian/` folder.
- Installed and verified RTK, ICM, and local Graphify. No hosted account, cloud memory, or source upload was configured.
- Generated graph output and `.obsidian/graph.json` / `.obsidian/workspace.json` are local state and must not be staged. `backend/.env` is ignored; never read or commit it.

## Verification performed for this workflow

- RTK 1.0.0: version check, `gain`, and project Codex hook setup succeeded.
- ICM 0.11.4: `codex mcp get icm` reports enabled; direct MCP initialize handshake succeeded. Per-project manifest setup remains unresolved.
- Graphify 0.9.90: local Codex skill/hook setup, code-only extraction, and clustering succeeded; optional SQL parser was installed.
- `flutter analyze --no-pub`: no issues. Earlier project verification: 4 Flutter tests passed and PHP syntax checks passed. APK build remains blocked by DNS resolution of `storage.googleapis.com`.
- `git ls-remote --heads origin main` verified read-only access and the current remote branch before publication. Recheck the remote head after pushing.
- `git check-ignore --no-index -v backend/.env.example` confirms the template remains trackable; `git check-ignore -v backend/.env` confirms the secret file is ignored. Secret contents were not read.
- `git diff --check` and `git diff --cached --check` passed; Git emitted only existing working-copy LF-to-CRLF notices. A targeted check of Markdown and Obsidian links in the project/workflow index notes found no missing targets. Flutter analysis passed in this integration pass; app tests and PHP syntax checks passed earlier in this project work and were not rerun just for tool installation.

## Highest-priority next task

Exercise registration/login/refresh/logout, profile, favorites, and COD order flows against the local MySQL API, documenting actual results before connecting more screens.

## Safety constraints

- Do not point the app at `streetfood_db`; `burger_bites` is the confirmed local target.
- Never commit `.env`, database credentials, OAuth secrets, payment keys, tokens, personal customer data, or `.obsidian/workspace.json` changes.
- Do not deploy publicly, stage local Obsidian/Graphify state or ignored secrets, or alter production data without explicit authorization.
- Keep local preview data labeled until screens are connected to verified API responses.
