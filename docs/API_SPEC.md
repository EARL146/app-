# API Specification

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[DATABASE_SCHEMA]] · [[SECURITY]] · [[PRODUCTION_READINESS_AUDIT]]

## Status

The Flutter client calls the API paths below. A dependency-free PHP 8 API implements account registration/login, rotating sessions, profile read/update, product reads, customer favorites, and COD order creation. The local MySQL schema and restricted account are configured; `GET /products` passed a live HTTP/database check. Registration/login, favorites, and order flows have not yet had end-to-end integration checks. Admin management and customer order history APIs are not implemented.

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
| `GET /products` | Public | Supports `q`, `category`, `sort` (`recommended`, `price_asc`, `price_desc`, `rating`), `limit` (max 50), `offset`. |
| `GET /products/{id}` | Public | Returns a product object. |
| `GET /me/favorites` | Bearer access token | Returns `{favorites:[product objects]}` for the authenticated user. |
| `POST /me/favorites` | Bearer access token | `{product_id}`; duplicate favorites are ignored. |
| `DELETE /me/favorites/{productId}` | Bearer access token | Deletes only the authenticated user's favorite. |
| `POST /orders` | Customer bearer access token | Customer name/address/phone, `payment_method:"cod"`, notes, and `{product_id,quantity}` items → committed order ID. Server reloads prices and stock and calculates totals in a transaction. |

Order tax and delivery defaults are 12% and ₱25, configurable with `ORDER_TAX_PERCENT` and `ORDER_DELIVERY_FEE`. Confirm these business rules before real orders. Prices are stored as `DECIMAL(10,2)`. Stock is decremented when a COD order is accepted.

## Not implemented

- Admin product/category/inventory/order/customer APIs. Requests under `/admin/` return 501 for admins and 403 for customers.
- Customer order-history endpoint, saved-address collection, notifications, account recovery/email verification, Google/Apple OAuth, and online payments.
- The Flutter menu/search/admin/order-history screens are still backed by local preview state. `/products` exists but is not yet connected to those screens.

See [[SETUP_GUIDE]] and [[DATABASE_SCHEMA]] before configuring the server. Never treat client-sent role, price, stock, totals, or customer identity as authoritative.
