# Database Schema and Inspection Status

[[PROJECT_HOME]] · [[API_SPEC]] · [[SECURITY]] · [[PRODUCTION_READINESS_AUDIT]]

## Database selection

The user identified the existing phpMyAdmin database as `Burger_Bites`. Read-only inspection confirmed its MySQL name is `burger_bites` and it had no tables before setup. Migration `001_initial_schema.sql` was then applied; the seven core tables are visible to the PHP API's restricted account. `streetfood_db` was not changed.

Migration `001` uses `CREATE TABLE IF NOT EXISTS`; it does not drop data, but an existing table with a different structure would not be repaired by that statement. Do not point this API at `streetfood_db`.

## Versioned schema files

`backend/database/migrations/001_initial_schema.sql` defines:

| Table | Purpose and key rules |
| --- | --- |
| `users` | Unique email, Argon2id password hash, server-owned role, profile fields. Public registration always creates `customer`. |
| `api_tokens` | HMAC-hashed access/refresh tokens, family revocation, user foreign key, expiry index. |
| `products` | String IDs matching the current Flutter catalog, `DECIMAL(10,2)` prices, availability, stock, search indexes. |
| `favorites` | Composite primary key `(user_id, product_id)` prevents duplicates; both foreign keys cascade. |
| `orders` | Owner, delivery snapshot, COD-only method, status, decimal price totals and owner/status indexes. |
| `order_items` | Product/name/image/price snapshots and quantity; order/product foreign keys. |
| `auth_rate_limits` | HMAC-hashed email/IP subjects and fixed-window counters; no raw email/IP is stored in this table. |

`002_development_catalog.sql` inserts the six products currently in `lib/data/demo_data.dart`. It is sample data with sample stock, for development only. Replace it with verified restaurant data before accepting real orders.

## Applying locally

1. Start MySQL in AMPPS and select `Burger_Bites` (`burger_bites`) in phpMyAdmin.
2. The initial schema is already installed. For a fresh copy, import `001_initial_schema.sql`; optionally import `002_development_catalog.sql` for local sample products.
3. The `burger_bites_app` API account has only `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on `burger_bites.*`. Root credentials are not stored in the API configuration.
4. `backend/.env` contains local generated settings and is ignored by Git. Do not share its secrets. See [[SETUP_GUIDE]] and `backend/README.md`.

Migration `001` was applied against the verified empty local database. The API account successfully connected and confirmed seven tables are visible. No product/customer/order rows were added. Migration `002` remains unapplied.

## Gaps

The current schema has one `default_address` field rather than multiple saved addresses. It has no product categories table, password-reset tokens, email-verification state, audit log, payment records, or migrations tracking table. Admin APIs, customer order history, and cancellation/restocking flows are not implemented. Extend the schema only after confirming the business rules and target database.
