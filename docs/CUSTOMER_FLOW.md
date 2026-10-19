# Customer Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[SCREEN_FLOW]] · [[API_SPEC]] · [[SECURITY]]

## Sign-in and profile

1. Splash restores a saved token and role using `GET /me` when the API URL is configured. Valid customers and admins go directly to their role home.
2. Guests see the ingredient intro and Greetings screen, then choose Browse menu. They can view the public catalog without signing in.
3. Favorite or add-to-cart actions open a sign-in/create-account prompt. Successful customer authentication returns to the product and resumes the pending action. Sign-in links to registration.
4. Flutter validates email and a 12-character password; the PHP API repeats validation, checks a small common-password list, and stores an Argon2id hash.
5. Login/register call `AuthService`. The UI accepts a session only when the server returns a token, user ID, and `customer` or `admin` role.
6. Access/refresh tokens, ID, role, and returned profile fields are stored with Flutter Secure Storage. Access tokens expire after 15 minutes; on a 401 at startup, the client rotates the refresh token and retries `/me`. Logout revokes the token family and clears local storage.
7. Account Settings saves the customer's name, phone, and default delivery address through `PUT /me`; the returned address appears in the profile and seeds checkout. A live temporary-customer API check confirmed address save, read, and clear.

PHP routes and the local MySQL schema are configured. The database-backed products endpoint passed a smoke check. Authentication, profile loading/editing, and session persistence still need a full end-to-end user journey test.

## Browse, favorites, and cart

| Screen/feature | Current implementation | Data boundary |
| --- | --- | --- |
| Home, menu, search | Search/category/sort UI over the PHP catalog API | Reads current SQL products; an empty catalog is shown when no products are seeded. |
| Product details | Opens API catalog product and adds its real ID/options to the cart | Server reprices and checks stock during cart sync and checkout. |
| Favorites | Favorite heart and dedicated Favorites screen | Calls user-scoped PHP `GET/POST/DELETE /me/favorites`; requires signed-in customer and configured database. |
| Cart | Merge same product/options, edit each customized line, calculate preview totals | Add-to-cart prompts for customer authentication; signed-in cart syncs to SQL. Requires migration 003. |

## Checkout algorithm

1. Customer authentication is required before checkout and order placement.
2. Validate non-empty cart, customer name, address, and phone.
3. Keep the cart's displayed total as an estimate only.
4. Send only product IDs, quantities, customer name, address, phone, notes, and `payment_method: cod` to `POST /orders`.
5. Do not send client price or amount as authoritative data.
6. The PHP route reloads prices and stock and writes the pending COD order in one transaction. If the API fails or gives no order ID, show the server/setup error and keep the cart unchanged.
7. If the server confirms an order ID, clear the cart and show “Order request received”; payment is not collected online.

Online payment choices are disabled because no provider is configured. Order History reads the signed-in user's SQL orders. Public catalog read is smoke-tested; authenticated cart/order flows still need live tests after migration 003 is imported.

## Account/support screens

Profile/password, default address, saved preferences, contact messages, and account-scoped calendar reminders call the API. Reminders can be created, listed, edited, and deleted after migration 003 is imported; they do not send push, SMS, or email alerts. App-wide translations/theme application, external notifications, and verified business contact coordinates are not complete. The profile no longer displays a made-up customer name/address or fake point balance. See [[PRODUCTION_READINESS_AUDIT]] for feature status and remaining backend work.
