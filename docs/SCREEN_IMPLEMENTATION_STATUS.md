# Screen Implementation Status

[[PROJECT_HOME]] · [[SCREEN_DESIGN_SPEC]] · [[TESTING]] · [[FILE_REGISTRY]] · [[PRODUCTION_READINESS_AUDIT]]

Updated: 2026-10-14. “Implemented” describes the Flutter client; absent server behavior is not implied.

## Customer screens

| Screen | Status | Current behavior / limit |
| --- | --- | --- |
| Splash / Greetings | Implemented and tested | Owner-supplied logo; route to sign-in or registration. Returning session check uses `/me` when API is configured. |
| Sign in | Implemented, database connection pending | Calls the new PHP API; no local credential or arbitrary-customer fallback. Requires the DB setup in `backend/README.md`. |
| Registration | Implemented, database connection pending | Client and PHP both validate; PHP hashes with Argon2id and assigns customer role. Requires DB setup and runtime verification. |
| Home / Menu | Preview data | Product/location/promotions remain from `DemoData`. |
| Search | Implemented over preview data | Search/category and three-dot sort menu; does not fetch server catalog. |
| Product details | Partially connected | Local product/cart actions; favorite button calls API. |
| Favorites | Implemented, database connection pending | Dedicated screen, visible saved-state icon, and PHP user-scoped endpoints; persistence not tested against MySQL. |
| Cart | Preview state | In-memory quantities and local estimate, not persisted. |
| Checkout | API request implemented, database connection pending | PHP validates address/items, reads server price/stock, and creates COD order transactionally. DB and stock behavior not tested. |
| Order confirmation | Conditional on server | Shows request reference only when server returns order ID. |
| Order history | Preview data | Static sample records; not linked to created server orders. |
| Profile | Server fields expected | Reads authenticated identity cache; saved address editing still needs full address API/UI. |
| Settings / language / theme / calendar | Preview | Changes are not consistently persisted or applied globally. |
| Contact / about | Preview | Contact form does not send a server message. |

## Admin screens

| Screen | Status | Current behavior / limit |
| --- | --- | --- |
| Admin route gate | Client-side guard | Requires server-returned role `admin`; server must independently authorize endpoints. |
| Dashboard | Preview data | Metrics, chart, and orders are local samples. |
| Orders | Preview data | Status changes/cancellation are local; no API or audit log. |
| Products | Preview data | Add/edit/delete/availability state is not persisted; inventory API absent. |
| Customers | Preview data | Sample customers and toggles; authorization/privacy service absent. |
| Admin profile | API path implemented, DB verification pending | Displays cached server identity and calls `PUT /me`; logout clears local session and attempts server logout. |
| More | Preview | Several settings are not connected to services. |

## Design and verification

- Supplied conversation screenshots are current design references. The Figma URL could not be opened by the viewer, so **Verified Against Figma: none**.
- The user-supplied logo is bundled at `assets/branding/burger_bites_logo.png`.
- `flutter test --reporter expanded`: 4 tests passed (startup route and cart preview math).
- `flutter analyze --no-pub`: passed with no issues; see [[TESTING]].
- Android debug APK build: Gradle failed to resolve `storage.googleapis.com`; no APK was produced. No Android device/emulator is connected.
