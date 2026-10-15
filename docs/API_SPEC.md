# API Specification

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[DATABASE_SCHEMA]] · [[SECURITY]] · [[PRODUCTION_READINESS_AUDIT]]

## Status

The Flutter client calls the API paths below. PHP/PDO implements authentication, profile/preferences, catalog, favorites, signed-in customer carts, COD order creation/history/cancellation, account calendar reminders, product and customer management, order management, dashboard totals, and a support inbox. Public catalog access and admin login, `/me`, admin authorization, and logout were checked against local MySQL. The additional workflow migration `003_app_workflows.sql` must be imported before using preferences, saved carts, reminders, support, inventory controls, account suspension, customization persistence, or the expanded order statuses. Those workflows still need authenticated end-to-end checks.

## Base URL and transport

- Set `BURGER_BITES_API_BASE_URL` at run/build time, for example `http://127.0.0.1:8081/api/v1` for local web development (port 8080 is occupied by Tomcat on this computer).
- Requests use JSON and authenticated calls attach a bearer access token.
- Access tokens expire after 15 minutes; refresh tokens after 30 days. Refresh rotates both tokens.
- The client times out after 15 seconds. API responses use JSON `{ "message": "Safe user-facing explanation" }` for errors.
- Release builds require HTTPS. Local Android cleartext is enabled only in the debug manifest.
- Browser origins must exactly match `APP_ALLOWED_ORIGINS`. Mobile API calls do not use browser CORS.

## Implemented routes

| Method/path | Authentication | Request / response |
| --- | --- | --- |
| `POST /auth/register` | Public; rate limited | `{full_name,email,password}` → `{token,refresh_token,user_id,user}`. New registrations always receive the `customer` role. Server requires at least 12 characters and Argon2id hashes. |
| `POST /auth/login` | Public; rate limited | `{email,password}` → session response above. Invalid credentials return the same message. |
| `POST /auth/refresh` | Refresh token in body | `{refresh_token}` → new `token` and `refresh_token`; old token family is revoked in a transaction. |
| `POST /auth/logout` | Bearer access token | Revokes the associated access/refresh token family. |
| `GET /me` | Bearer access token | `{user:{id,role,email,full_name,phone,branch_name,default_address}}`. |
| `PUT /me` | Bearer access token | Accepts `full_name`, `phone`, `branch_name`, and/or `default_address`; returns updated user. |
| `PUT /me/password` | Bearer access token | Verifies the current password, stores an Argon2id hash, and revokes other sessions while keeping the current session. |
| `GET /me/preferences` | Bearer access token | Returns language, theme mode, and notification/receipt preferences. Requires migration 003. |
| `PUT /me/preferences` | Bearer access token | Saves supported language, theme mode, and preference toggles. This stores a preference; it does not implement localization or send notifications. Requires migration 003. |
| `GET /me/cart` | Customer bearer access token | Loads saved cart items with current server prices and validated customizations. Requires migration 003. |
| `PUT /me/cart` | Customer bearer access token | Replaces the user's saved cart; validates product availability and options. Requires migration 003. |
| `DELETE /me/cart` | Customer bearer access token | Clears the user's saved cart. Requires migration 003. |
| `GET /me/calendar-reminders` | Customer bearer access token | Lists the authenticated customer's saved reminders. Requires migration 003. |
| `POST /me/calendar-reminders` | Customer bearer access token | Creates a reminder with `reminder_date` (`YYYY-MM-DD`), `title`, and optional `notes`. Requires migration 003. |
| `PUT /me/calendar-reminders/{id}` | Customer bearer access token | Updates an owned reminder using the same fields as create. Requires migration 003. |
| `DELETE /me/calendar-reminders/{id}` | Customer bearer access token | Deletes only an owned reminder. Requires migration 003. |
| `GET /products` | Public | Supports `q`, `category`, `sort` (`recommended`, `price_asc`, `price_desc`, `rating`), `limit` (max 50), `offset`. |
| `GET /products/{id}` | Public | Returns a product object. |
| `GET /me/favorites` | Bearer access token | Returns `{favorites:[product objects]}` for the authenticated user. |
| `POST /me/favorites` | Bearer access token | `{product_id}`; duplicate favorites are ignored. |
| `DELETE /me/favorites/{productId}` | Bearer access token | Deletes only the authenticated user's favorite. |
| `POST /orders` | Customer bearer access token | Customer name/address/phone, `payment_method:"cod"`, notes, and product/quantity items. Burgers may include `customizations:{size,toppings}`; the server validates and prices options, reloads stock, and commits the order transactionally. Requires migration 003 for customization persistence. |
| `GET /me/orders` | Bearer access token | Returns only the authenticated customer's orders and line items. |
| `PUT /me/orders/{id}/cancel` | Bearer access token | Cancels a pending order and restores stock transactionally. |
| `POST /contact` | Public; rate limited | Saves a validated support request to the SQL inbox. Requires migration 003. |
| `GET /admin/dashboard` | Admin bearer access token | Returns SQL order, revenue, product, and customer totals plus the last seven days of non-cancelled order value. Requires migration 003. |
| `GET /admin/system-status` | Admin bearer access token | Checks database reachability and whether the migration 003 workflow schema is installed; does not return credentials or customer data. |
| `GET /admin/orders` | Admin bearer access token | Returns recent orders and line items. |
| `PUT /admin/orders/{id}` | Admin bearer access token | Advances order status through the allowed lifecycle; cancellation restores stock. |
| `GET /admin/products` | Admin bearer access token | Returns all products, including unavailable items and stock quantities. |
| `POST /admin/products` | Admin bearer access token | Creates a catalog item with server-validated fields and stock. |
| `PUT /admin/products/{id}` | Admin bearer access token | Updates product fields, availability, and stock. |
| `DELETE /admin/products/{id}` | Admin bearer access token | Archives a product without breaking historic order references. |
| `GET /admin/customers` | Admin bearer access token | Returns customer profiles and SQL order summaries. |
| `PUT /admin/customers/{id}` | Admin bearer access token | Activates/deactivates a customer; deactivation revokes that customer's sessions. Requires migration 003. |
| `GET /admin/contact-messages` | Admin bearer access token | Returns recent support requests. Requires migration 003. |
| `PUT /admin/contact-messages/{id}` | Admin bearer access token | Sets support status to new, in progress, or resolved. Requires migration 003. |

Order tax and delivery defaults are 12% and ₱25, configurable with `ORDER_TAX_PERCENT` and `ORDER_DELIVERY_FEE`. Confirm these business rules before real orders. Prices are stored as `DECIMAL(10,2)`. Stock is decremented when a COD order is accepted.

## Not yet connected

- GCash/Maya and other online payments. Only COD is accepted; do not collect online payment details until provider sandbox and callback integration is configured.
- GPS courier tracking, outgoing SMS/email notifications, account recovery/email verification, Google/Apple OAuth, and app-wide translated strings/theme palettes.
- Reminder records do not send push, SMS, or email alerts. Real product image uploads, promotion/reward engine, and multiple saved addresses are also not implemented.
- Live end-to-end checks for the newly added routes require importing migration 003 and running the local PHP API against Burger_Bites.

See [[SETUP_GUIDE]] and [[DATABASE_SCHEMA]] before configuring the server. Never treat client-sent role, price, stock, totals, or customer identity as authoritative.
