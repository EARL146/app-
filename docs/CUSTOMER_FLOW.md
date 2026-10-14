# Customer Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[SCREEN_FLOW]] · [[API_SPEC]] · [[SECURITY]]

## Sign-in and profile

1. Splash checks for a saved token and role using `GET /me` when the API URL is configured.
2. New users see Greetings, then can open Sign in or Register.
3. Flutter validates email and a 12-character password; the PHP API repeats validation, checks a small common-password list, and stores an Argon2id hash.
4. Login/register call `AuthService`. The UI accepts a session only when the server returns a token, user ID, and `customer` or `admin` role.
5. Access/refresh tokens, ID, role, and returned profile fields are stored with Flutter Secure Storage. Access tokens expire after 15 minutes; on a 401 at startup, the client rotates the refresh token and retries `/me`. Logout revokes the token family and clears local storage.
6. The customer profile displays the returned name, email, phone, and default address. Saving profile fields requires `PUT /me`.

PHP routes and the local MySQL schema are configured. The database-backed products endpoint passed a smoke check. Authentication, profile loading/editing, and session persistence still need a full end-to-end user journey test.

## Browse, favorites, and cart

| Screen/feature | Current implementation | Data boundary |
| --- | --- | --- |
| Home, menu, search | Search/category/sort UI over `DemoData.products` | Catalog is still local sample data. |
| Product details | Shows local product and adds to the shared cart | Server price/stock checks are still required. |
| Favorites | Favorite heart and dedicated Favorites screen | Calls user-scoped PHP `GET/POST/DELETE /me/favorites`; requires signed-in customer and configured database. |
| Cart | Merge same product ID, change quantity, remove item, calculate preview totals | In-memory only; not persisted. |

## Checkout algorithm

1. Validate non-empty cart, customer name, address, and phone.
2. Keep the cart's displayed total as an estimate only.
3. Send only product IDs, quantities, customer name, address, phone, notes, and `payment_method: cod` to `POST /orders`.
4. Do not send client price or amount as authoritative data.
5. The PHP route reloads prices and stock and writes the pending COD order in one transaction. If the API fails or gives no order ID, show the server/setup error and keep the cart unchanged.
6. If the server confirms an order ID, clear the cart and show “Order request received”; payment is not collected online.

Online payment choices are disabled because no provider is configured. The current Order History screen still shows sample records and is not backed by the submitted orders. The API/database flow has not been integration-tested.

## Account/support screens

Settings, language, theme, calendar, contact, and about screens remain prototype/local views. The profile no longer displays a made-up customer name/address or fake point balance. See [[PRODUCTION_READINESS_AUDIT]] for feature status and remaining backend work.
