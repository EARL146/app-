# API and Database Index

[[PROJECT_HOME]] · [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[SECURITY]] · [[SETUP_GUIDE]]

## Current implementation

- PHP API source: `backend/public/index.php` and `backend/src/`.
- API root format: `{BURGER_BITES_API_BASE_URL}/api/v1`.
- Flutter configuration: `--dart-define=BURGER_BITES_API_BASE_URL=...`.
- MySQL schema: `backend/database/migrations/001_initial_schema.sql`.
- Optional development products: `backend/database/migrations/002_development_catalog.sql`.
- Local server/admin setup: [backend/README.md](../backend/README.md).

The API is configured through the ignored `backend/.env` file and connects to `burger_bites` using the restricted `burger_bites_app` MySQL account. The initial schema has been applied and the account can see all seven core tables. No sample menu data was inserted. AMPPS `streetfood_db` remains untouched. See [[DATABASE_SCHEMA]].

See [[API_SPEC]] for exact route contracts and [[SECURITY]] for implemented controls and outstanding risks. Never store database passwords, API keys, or production secrets in Obsidian.
