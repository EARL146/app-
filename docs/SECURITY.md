# Security Status

[[PROJECT_HOME]] · [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[KNOWN_ISSUES]] · [[PRODUCTION_READINESS_AUDIT]]

## Implemented in code

- Removed the hard-coded demo administrator credential. Public registration creates only a customer; an administrator is created through an explicit local CLI helper.
- PHP registration uses Argon2id hashes and validates input on the server. Login responses do not distinguish an unknown email from a wrong password. Login/registration use HMAC-keyed IP/email fixed-window counters.
- The PHP API issues random opaque access/refresh tokens, stores only HMAC hashes, expires access tokens after 15 minutes and refresh tokens after 30 days, rotates refresh families, and revokes both token types on logout.
- API routes derive the user ID and role from the live token row. Favorites are user-scoped. Orders accept only product IDs and quantities; the server reads prices/stock and creates the order and decrements stock in one transaction.
- PHP uses PDO native prepared statements, JSON input limits, safe response errors, exact-origin CORS, and standard browser security headers.
- Flutter session values use `flutter_secure_storage`; startup calls `/me` before restoring a cached session. Admin Flutter routes are role-gated for navigation convenience.
- Release builds reject non-HTTPS API URLs. Cleartext is enabled only in the Android debug manifest.
- The checkout does not claim payment success; only COD is sent and the UI waits for a server order ID.

## Not yet verified or implemented

1. **Database:** Migration `001` is installed in the user-confirmed empty `burger_bites` database. PHP uses a dedicated account with only `SELECT`, `INSERT`, `UPDATE`, and `DELETE`; its random password and token pepper are kept in ignored `backend/.env`. `streetfood_db` was not changed. The sample catalog was not seeded.
2. **Admin authorization/features:** The PHP admin API is not implemented. Flutter admin routes alone cannot protect data. Do not use admin product/order/customer features as real operations yet.
3. **Order lifecycle:** No admin status/cancel endpoint exists, so stock decremented at order creation cannot yet be released through the app. Orders are not production-operable until this lifecycle is implemented.
4. **Account recovery:** Email verification, password reset, and account lockout/recovery flows are absent. Rate limits are process-independent database counters but have not been load-tested.
5. **Web/API deployment:** CORS has local allowlist support but must be set for the selected origin. No public host, TLS certificate, DNS, CDN, WAF, DDoS protection, proxy policy, monitoring, backup, or incident procedure is configured.
6. **Integrations:** Google/Apple credentials and server token validation, online payment provider, callbacks, reconciliation, and notifications are absent.
7. **Secrets:** Keep `backend/.env` and admin passwords out of Git and notes. Never compile database passwords or provider secrets into Flutter.

The PHP syntax check and Flutter analyzer/tests passed, but the database/API has not been connected. See [[TESTING]] for the failed Android artifact download and [[PRODUCTION_READINESS_AUDIT]] for the full feature statuses.
