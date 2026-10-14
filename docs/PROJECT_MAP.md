# BurgerBites Project Map

## Main project

- [[PROJECT_HOME]] · [[FILE_REGISTRY]] · [[SYSTEM_FLOW]]
- [[PRODUCTION_READINESS_AUDIT]] · [[SCREEN_FLOW]]
- [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[SECURITY]]
- [[TESTING]] · [[CHANGELOG]]
- [[INTEGRATION_MAP]] · [[OBSIDIAN_SETUP]] · [[BACKUP_WORKFLOW]]

## Application overview

Flutter/Dart client based on the supplied screenshots, with a PHP/PDO API and seven core tables installed in local MySQL database `burger_bites`. The referenced Figma URL is not currently accessible to the viewer. Local previews remain in several customer/admin screens.

## Main folders

- `lib/` — Flutter source, providers, routes, models, and services
- `backend/` — PHP API, environment template, SQL migrations, and local admin helper
- `android/` — Android configuration; debug-only local cleartext allowance
- `web/` — Web application configuration
- `test/` — Flutter automated tests
- `assets/` — Supplied logo and local product images
- `docs/` — Obsidian project notes
- `AGENTS.md` — concise Codex repository guidance and session continuity rules

## Database caution

Migration `001` was applied to the user-confirmed empty `Burger_Bites` database. `streetfood_db` remains untouched. The optional sample catalog migration `002` is not applied.
