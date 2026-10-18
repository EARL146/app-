# Screen Implementation Status

[[PROJECT_HOME]] · [[SCREEN_DESIGN_SPEC]] · [[TESTING]] · [[FILE_REGISTRY]] · [[PRODUCTION_READINESS_AUDIT]]

Updated: 2026-10-16. “Connected” describes code paths; new SQL workflows still require migration 003 and live verification.

## Customer screens

| Screen | Status | Current behavior / limit |
| --- | --- | --- |
| Splash / Greetings | Implemented and tested | Owner-supplied logo; route to sign-in or registration. Returning session check uses `/me` when API is configured. |
| Sign in | Connected in code | Email/password calls the PHP API. Google/Apple buttons explain that provider setup is not configured yet. |
| Registration | Connected in code | PHP validates and hashes with Argon2id; creates customer role. |
| Home / Menu / Search | Connected in code | Catalog, categories, and search read the public SQL product API; empty/error states are shown. Delivery address uses the signed-in profile. |
| Product details | Connected in code | Favorites use the API. Burger size/toppings retain the real product ID and are repriced and validated by the server. |
| Favorites | Connected in code | User-scoped API list/actions; live persistence still needs rechecking. |
| Cart | SQL-backed for signed-in customers | Account carts load and sync through `/me/cart`; guest carts stay in memory until sign in. The cart shows the saved profile address when present and avoids inventing a location. The server validates product/options and recalculates prices when loading the saved cart. Requires migration 003. |
| Checkout | Connected in code (COD) | Server validates user, prices, modifiers, address, and stock; commits order and stock in a transaction. GCash/Maya remain disabled pending sandbox details. |
| Order confirmation | Conditional on server | Shows request reference only when server returns order ID. |
| Order history | Connected in code | Reads the signed-in user's SQL orders, supports pending-order cancellation and reorder; live GPS tracking is not available. |
| Profile / account settings | Connected in code | Name, phone, and default address save through `/me`; password changes use `/me/password`. Address persistence passed a live temporary-customer API check. Notification and language preference values require migration 003. Email, SMS, social login, and two-step verification are not configured. |
| Theme / language / calendar | Partial | Language and palette preferences persist, but app-wide translations/theme switching are not implemented; preview cards no longer present invented menu pricing as live catalog data. Calendar reminders support account-scoped create, list, edit, and delete in code; migration 003 and live verification are still required. Reminders do not send alerts. |
| Contact | Connected in code; live check pending migration 003 | Loads public store contact, location, hours, social, and coverage details from `/store-profile`; displays an honest empty state until verified information is saved. The SQL-backed support form requires migration 003. |
| About | Informational | Describes current menu, customization, and order-history features without placeholder brand claims. |

## Admin screens

| Screen | Status | Current behavior / limit |
| --- | --- | --- |
| Admin route gate | Client-side guard | Requires server-returned role `admin`; server must independently authorize endpoints. |
| Dashboard | Connected in code | Order/product/customer totals and the seven-day sales chart come from the admin SQL dashboard endpoint. The header bell opens Admin Orders and shows the SQL pending-order count. No growth percentages are fabricated. Migration 003 is required. |
| Orders | Connected in code | SQL orders/status lifecycle and safe cancellation/stock restoration; migration 003 and end-to-end checks required. |
| Products | Connected in code | SQL create/edit/archive, availability, stock; migration 003 required for API compatibility. Image upload is not implemented. |
| Customers | Connected in code | SQL profile/order summaries and activate/deactivate; disabled customer sessions are revoked. Migration 003 required. |
| Admin profile | Connected in code | Uses server identity/profile, password changes, and logout. Admin login/session/password endpoint checks passed; widget test verifies profile, password, and logout controls render. |
| Support inbox | Connected in code | Reads customer requests and persists new/in-progress/resolved status. |
| Store profile | Connected in code; live check blocked by migration 003 | Admin form reads and updates public business details through `/admin/store-profile`; route is behind the admin gate. |
| More | Connected with explicit provider limits | API and MySQL readiness are checked through an admin-only endpoint; migration 003 readiness is shown. Includes the Store profile editor. Language & Region opens the saved preference screen. Payment section accurately shows COD active and GCash/Maya pending sandbox setup. Email/SMS delivery and app-wide translations remain unconfigured. |

## Design and verification

- Supplied conversation screenshots are current design references. The Figma URL could not be opened by the viewer, so **Verified Against Figma: none**.
- The original logo remains at `assets/branding/burger_bites_logo.png`; a transparent cutout is used by `BrandLogo`. Registration, sign-in, and welcome marks float gently. The welcome hero uses a separate transparent photorealistic burger cutout and slow float/tilt lighting motion; reduced-motion preferences stop the loops.
- Verification on 2026-10-15: `flutter analyze --no-pub` reported no issues, all 10 Flutter tests passed, and `flutter build web --no-pub` built the JavaScript Web app. The read-only public store-profile API returned HTTP 503 because migration 003 is still absent from MySQL. The two PNG cutout assets have transparent corners and are present in the built Web assets.
- Responsive UI audit on 2026-10-16: `flutter test --no-pub --reporter expanded` passed all 14 tests; `flutter analyze --no-pub` reported no issues. Welcome, sign-in, registration, customer home, and admin dashboard were checked at 320, 360, 390, and 430 px. Search empty-state behavior was also checked at 320 px. No Android emulator or physical device is connected; this was a widget-test pass, not a device-rendered visual review.
- The small-phone pass fixed welcome/auth/home/admin layout overflow, made customer/admin header menu controls navigable, and removed unsupported voice-search and sample-search-history cues. The search screen now distinguishes empty/error states. Existing API, SQL, payment, and authentication behavior was not redesigned.
- `graphify update .` refreshed the local code graph to 1,860 nodes, 3,031 edges, and 125 communities. Its existing Linux header parse warning remains; generated graph output stays local and ignored.
- Android debug APK build: Gradle failed to resolve `storage.googleapis.com`; no APK was produced. No Android device/emulator is connected.
