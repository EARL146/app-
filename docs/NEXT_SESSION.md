# Next Session — BurgerBites

[[PROJECT_HOME]] · [[INTEGRATION_MAP]] · [[AGENT_TEAM]] · [[AGENT_MONITOR]] · [[BACKUP_WORKFLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[KNOWN_ISSUES]] · [[TESTING]]

## Admin account, earnings, and payment ledger (2026-10-27)

- Admin Profile now lets the signed-in admin pick and save a profile photo through the existing `/me/profile-image` endpoint; photos are stored in `users.profile_image`.
- Admin access and refresh tokens rotate every 10 minutes and refresh again when the app resumes. Overlapping refresh attempts share one request, avoiding refresh-token rotation races that could invalidate the session and trigger 401s on Store Profile and Support routes.
- Admin More notifications show recent database-backed orders. Help & Support opens the support inbox, Store Profile remains editable, and the obsolete App Information panel was removed.
- Dashboard revenue now distinguishes all non-cancelled order value from money collected on delivered orders. The local database currently has 7 pending orders with ₱2,318.68 order value, no delivered orders, and ₱0 collected; ₱0 is therefore the correct withdrawable balance until an order is delivered.
- Added admin-only `GET /admin/payment-summary` and `POST /admin/withdrawals`; the backend serializes withdrawal attempts and refuses withdrawals above the current delivered-order balance. Migration `008_store_withdrawals.sql` was applied to `burger_bites` after backup. A PHP integration check confirmed a ₱500 withdrawal returns 409 and adds no ledger row while the balance is ₱0.
- Backup: `%LOCALAPPDATA%\BurgerBites\database-backups\burger_bites_before_008_20261027-190636.sql` (1,316,296 bytes). GCash/Maya transfers are not connected; the ledger records withdrawals for manual transfer.
- Verification (2026-10-27): `flutter analyze --no-pub` found no issues; `flutter test --no-pub` passed all 34 tests; `php -l backend/src/ApiApplication.php` and `php -l backend/src/Http.php` passed; `git diff --check` was clean; `graphify update .` rebuilt 2,675 nodes / 4,583 edges / 154 communities. No browser UI review or funded withdrawal was performed.

## Customer splash, welcome, and sign-up refresh (2026-10-27)

- Reworked the loading screen to use a white background, centered BurgerBites chef/burger wordmark, large circular loader, and subtle outlined food icons around the edges. It restores an existing session before showing the guest flow.
- Added the centered welcome screen with the BurgerBites wordmark and red-accented greeting, then routes guests into the menu after a short pause.
- Fixed the missing logo text reported on splash/welcome/sign-in: the chef-burger art now renders behind the red “Burger” and burgundy “Bites” wordmark, and sign-in uses the shared full lockup instead of the art-only image.
- Redesigned account creation with the same brand, white spacious layout, email/password/full-name fields, black Continue action, Google/Apple buttons, and terms text. Email/password registration and the sign-in return-to-caller flow remain connected to the existing API. Google and Apple sign-in are still unconfigured and show an explanatory message.
- Fixed the 320 px registration button overflow and made the splash navigation timer cancel safely when the screen is disposed. Updated the auth-flow test for the current sign-up field order and the splash→welcome→menu path.
- Verification: `flutter analyze --no-pub` reported no issues; `flutter test --no-pub` passed all 34 tests, including visible Burger/Bites labels at 320–430 px; `graphify update .` rebuilt 2,676 nodes / 4,584 edges / 155 communities. Browser visual review and live auth-provider sign-in were not performed.

## Backend API restoration, presence heartbeat fixes, and test suite pass (2026-10-26)

- Resolved browser `net::ERR_CONNECTION_REFUSED` for `http://127.0.0.1:8081/api/v1/products`: identified local PHP interpreter at `D:\Ampps\php\php.exe`, started the development API server on port 8081 pointing to `backend/public/index.php`, and added convenience launcher `backend/tools/start_api.bat` for one-click startup.
- Fixed `POST /api/v1/me/activity` 400 Bad Request: `Http::body()` in `backend/src/Http.php` incorrectly rejected empty JSON objects `{}` due to PHP 8.1+ `array_is_list([]) === true`. Updated condition to allow empty associative JSON objects `{}` while preserving strict rejection of JSON arrays `[]`.
- Fixed `POST /api/v1/me/activity` 401 Unauthorized handling: `AuthService._sendActivityHeartbeat()` now passes `{'offline': false}` body explicitly, cancels the periodic 60-second activity timer on 401 and invokes `refreshToken()`, and implements `AuthService.dispose()` to cancel pending timers. Added `AuthService.forTesting({bool enableHeartbeat = false})` to prevent leaks in tests.
- Strengthened `AppPreferencesProvider` with safe listener notifications to prevent post-dispose assertions during asynchronous theme and preference updates.
- Updated `test/widget_test.dart` to initialize `FlutterSecureStorage.setMockInitialValues({})`, update placeholder assertions for admin dashboard, and use testing auth service with teardown disposal.
- Verification:
  - `php -l backend/src/Http.php` and `backend/src/ApiApplication.php`: No syntax errors.
  - `flutter analyze --no-pub`: No issues found! (ran in 12.0s).
  - `flutter test`: All 34 tests passed! (including `test/auth_service_test.dart`, `test/auth_flow_test.dart`, `test/cart_provider_test.dart`, and all 15 tests in `test/widget_test.dart`).
  - `graphify update .`: Rebuilt 2,636 nodes, 4,501 edges, 148 communities.
  - `git diff --check`: Clean.
- Blockers: None. Local PHP API is running on `127.0.0.1:8081`; MySQL is running on `127.0.0.1:3306`.
- One next task: Verify live customer sign-in and scheduled discount cart checkout flow in the Edge browser against the live 8081 API.

## Admin dashboard, customer presence, and product sales update (2026-10-25)

- Added the admin customer details needed in the request: customer profile photos, address, email, phone, active-account state, online status, and elapsed offline time. Authenticated customer sessions send a best-effort presence heartbeat every 60 seconds and mark themselves offline when logging out. The online indicator expires after 120 seconds without a heartbeat.
- Updated the admin dashboard to remove the SQL-status banner and show the same last-seven-day order total represented by its chart. Recent orders now show the customer's name, order reference, product photo, and size/brand customizations. Admin order details show the customer owner, phone/address, item quantities, photos, and selected sizes, drink brands, and toppings.
- Admin add/edit product forms accept up to three image paths or URLs, show a preview, and configure a discount percent, product size or drink brand scope, start time, and expiry. Home and Menu product cards rotate their images and display a countdown; the Home Explore categories and Menu category list include current or upcoming sales. Checkout pricing respects the sale window on the API.
- Added `backend/database/migrations/006_customer_presence_product_gallery_sales.sql` for `users.last_seen_at`, product image galleries, and sale start/end timestamps. **Confirmed applied on 2026-10-25** with a read-only PDO check: all four required columns and both migration indexes exist in `burger_bites`. Do not re-import migration 006. Admin More → App Information checks the new columns.
- Updated `backend/README.md` with migration 006. The baseline checkpoint commit for this task is `6129a30 Checkpoint baseline before admin dashboard upgrades`; task changes remain uncommitted and unpushed.
- Verification: `dart format` completed; `flutter analyze --no-pub` reported **No issues found**; `php -l backend/src/ApiApplication.php` reported no syntax errors; `git diff --check` was clean; `graphify update .` completed. No tests, browser session, or live database workflow were run in this pass.
- The API on `127.0.0.1:8081` was stopped during the migration check (connection refused); MySQL on `127.0.0.1:3306` and PHP PDO access to `burger_bites` worked. Schema import is verified, but app/API workflows have not been verified after the import.
- Next: start the local API, then verify customer sign-in/logout presence, three-image product persistence/rotation, scheduled discount display and API price behavior, and customer-owned order details. Do not re-import migration 006.

## Runtime and integration audit (2026-10-22)

- Flutter verification: `flutter test --reporter compact` reported **All tests passed**; `flutter analyze` reported **No issues found**. These checks validate app code, not live server connectivity.
- Live local ports: BurgerBites API `127.0.0.1:8081` and Docker API `:8082` were closed; Redis `:6379` and OmniRoute `:20128` were also closed. MySQL `:3306` was listening, but the API/database connection was not verified. The existing read-only Agent Monitor was then started on `127.0.0.1:8765`; `/api/overview` returned HTTP 200. It is attached to the current Codex execution session.
- AMPPS runtime: the documented `C:\Users\shizu\OneDrive\Documents\Ampps\php82\php.exe` is absent at that path and `php` is not on PATH, so the PHP API could not be started from this environment.
- Docker Desktop 4.95.0 failed startup at the existing `docker-secrets-engine\engine.sock` reparse point (`The file cannot be accessed by the system`). No Docker engine, container, volume, or database data was removed. A timestamped preservation rename was attempted without elevation and denied; an elevated retry was blocked by the execution policy. Docker and its engine remain stopped.
- Developer integrations: ICM health/recall succeeded; Task Observer 3.7.0 is loaded; Graphify 0.9.90 is installed; RTK 1.0.0 runs explicitly but `rtk gain` says no hook is active. Headroom and Claude-Mem are not installed/configured. ICM is not the Agent Monitor event stream.
- Git was clean at the start of this audit (`main...origin/main`); no app code/configuration, credentials, containers, commits, or remote state were changed. This audit updates only this note and [[TOOL_CONNECTION_FLOW]].
- Next task: recover Docker Desktop by preserving the stale runtime socket directory under a unique backup name from an Administrator PowerShell after confirming Docker is fully stopped; then verify Docker, OmniRoute, Redis, the monitor, AMPPS PHP/API, and finally the customer/admin live flows. Do not reset Docker or delete its data.

## Agent City Interactive 2D Office Map Simulation, Figma UI Studio & Flutter Tactile UI Pass (2026-10-21)

- Created baseline checkpoint commit `870db3c` (`Checkpoint guest-first menu and profile sign-in baseline`) preserving the 11 guest-first menu files before applying the Agent Monitor and Flutter design upgrades.
- Upgraded the Agent Monitor (`tools/agent-monitor/index.html`, `tools/agent-monitor/city.js`, `tools/agent-monitor/city.css`, `tools/agent-monitor/app.js`, `tools/agent-monitor/server.py`, `tools/agent-monitor/test_server.py`, `docs/AGENT_MONITOR.md`):
  - **Interactive 2D Office Map Simulation (`#office-sim-canvas`)**: Built a 44×30 tile-based 2D office map (`buildOfficeMap`) with 8 named rooms (`Frontend Room`, `Command Center`, `Backend Room`, `Main Hallway`, `Coffee & Bites Lounge`, `QA Testing Room`, `Code Review Room`, and `Debugging Room`), walls, doorways, desks, server racks, and work stations.
  - **Autonomous A* Navigation & Collision Avoidance (`findPath`, `OfficeSimulation`)**: All 6 agents (`agent-1` through `agent-6`, including **Agent 6 · Security Engineer** with her female cyber-visor character sprite stationed at the `Cyber Shield Vault` in `Code Review Room`) are independent character objects with directional walking (`up`, `down`, `left`, `right`), idle breathing, and desk working/typing animations. They route between rooms through hallways and doors using 8-way A* pathfinding without cutting corners or walking through walls/desks, and reserve tiles to avoid overlapping other agents.
  - **Status-Connected Room Routing & Live Roster (`#city-agent-live-status`)**: Active tasks route agents to their assigned room and seat (`Working` → home room desk, `Securing` / `Reviewing` → `Code Review Room` / `Cyber Shield Vault`, `Testing` → `QA Testing Room`, `Debugging` → `Debugging Room`, `Completed` → `Command Center` report table). Clicking any character or right-side agent card focuses and follows that agent. Agent 6 (`agent-6`, Security Engineer) is wired into `agents.json`, `worker_runtime.py`, `city.js`, `app.js`, and `index.html` as both an isolated Codex security worker and an explicit role-ledger agent protecting the entire BurgerBites system (Flutter client auth/storage, PHP/PDO prepared statements, MySQL schema, CORS/rate-limiting guards, Docker/Redis isolation, and secret redaction).
  - **Zoom, Pan & Camera Controls**: Added mouse/touch drag-to-pan, scroll-wheel and pinch-to-zoom, keyboard navigation (arrow keys, `+`, `-`, `0`), zoom toolbar (`#city-zoom-in`, `#city-zoom-out`, `#city-zoom-reset`), clickable room quick-jump chips (`#city-room-chips`), simulation controls (`#city-patrol-toggle`, `#city-patrol-step`, `#city-paths-toggle`, `#city-speed-select`), and an interactive minimap.
  - **Figma & UI Studio (`#panel-figma`, `/api/design-system`)**: Displays interactive BurgerBites button states, color/typography tokens, all 19 Customer & Admin phone artboards, local Figma file URL binding, and 1-click multi-artboard `.svg` vector export for direct drag-and-drop into Figma.
- Upgraded the BurgerBites Flutter UI (`lib/constants/app_colors.dart`, `lib/constants/app_theme.dart`, `lib/widgets/animated_brand_button.dart`, `lib/widgets/customer_account_prompt.dart`, `lib/widgets/favorite_button.dart`, `lib/screens/customer/welcome_screen.dart`, `lib/screens/customer/sign_in_screen.dart`, `lib/screens/customer/register_screen.dart`, `lib/screens/customer/home_screen.dart`, `lib/screens/customer/menu_screen.dart`, `lib/screens/customer/product_details_screen.dart`, `lib/screens/customer/cart_screen.dart`, `lib/screens/customer/checkout_screen.dart`, `lib/screens/customer/order_history_screen.dart`, `lib/screens/customer/search_screen.dart`, `lib/screens/customer/profile_screen.dart`, and `lib/screens/admin/admin_home_screen.dart`) with brand gradients (`primaryButtonGradient`, `warmSurfaceGradient`, `heroDarkGradient`), tactile press/hover scale animations (`AnimatedPressScale`), animated number/price transitions (`AnimatedValueText`), entrance cards (`AnimatedEntranceCard`), gradient pill badges (`BrandGradientBadge`), a redesigned `Sign in to continue` customer account modal (`customer_account_prompt.dart`), and a full Figma-matched Customer Home layout (`home_screen.dart`) featuring the studio burger Hero banner, continuous auto-moving `Burger Bites` orange marquee ribbon (`_AutoMovingBrandTicker`), `Our Story: How Burger Bites Started` with night kiosk & polaroid grill collage, 4-category showcase grid (`Burgers`, `Drinks`, `Fries`, `Combo Meals`), `What Makes Us Different` + `Our Customers` moments gallery, interactive draggable & zoomable map of Compostela, Davao de Oro PH (`_FindUsDraggableMapSection`), and `THE PERFECT COMBO` dark footer banner.
- Verification:
  - `py -3 -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: **34 tests passed (`OK`)**, including `test_office_simulation_multi_room_navigation_and_collision_detection`, `test_parse_args_supports_open_flag`, and `test_local_http_preview_routes_and_path_rejection`.
  - `node --check tools/agent-monitor/app.js` and `node --check tools/agent-monitor/city.js`: **passed**.
  - `dart analyze lib test` and `flutter analyze --no-pub`: **No issues found! (ran in 16.3s)**.
  - `flutter test --no-pub`: **All 29 tests passed!**.
  - `flutter build web --no-pub --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1`: **√ Built build\web**.
- Next task: Paste the team's Figma file URL into Agent Monitor → **Figma & UI Studio** and import `burgerbites-figma-screens.svg` into Figma; for database workflows, import migration `003_app_workflows.sql` via phpMyAdmin when ready to exercise live SQL cart/order/store-profile persistence.

## Optional Docker and Redis development stack (2026-10-20)

- Added a loopback-only Docker Compose stack for PHP API, isolated MySQL (`burger_bites_docker` in named volume `burger-bites-docker-mysql-data`), and private Redis. It does not change AMPPS MySQL on port 3306 or the local API on 8081; Docker defaults to API port 8082 and MySQL port 3307.
- Redis backs shared expiring auth rate limits. The API falls back to the existing MySQL rate-limit table if Redis or the PHP Redis extension is unavailable. No product cache or business data is stored in Redis.
- Compose mounts migrations 001 and 003 only for first initialization of the new volume; sample-catalog migration 002 is omitted. Do not run `docker compose down -v` unless intentionally deleting the Docker database.
- Docker Engine 29.8.2 and Compose 5.6.0 are installed. The PHP API image built with `pdo_mysql`, `mbstring`, and `redis`; API, MySQL 8.4, and Redis 7 containers are running healthy. The API at `127.0.0.1:8082` returned HTTP 200 with an empty product list; the API container successfully pinged Redis. Redis-backed auth rate limits were not exercised end to end. `docker/.env` is ignored by Git. The Compose network uses explicit `db`/`redis` aliases; only API and MySQL are published on loopback.
- Setup and run commands: [[DOCKER_REDIS]]. Products are absent because sample-catalog migration 002 is intentionally omitted; add verified products through the admin workflow when that Docker database is selected. Do not import or seed invented product prices.

## Customer product options (2026-10-20)

- Product details now includes burger size choices, Small/Medium/Large fries choices, and drink-brand choices (Coca-Cola, Sprite, Pepsi, Royal, Mountain Dew, 7Up). Admin product categories also include `Fries`; existing `Sides` products whose names contain “fries” receive the fries choices.
- Choices are kept in the existing cart customization JSON and revalidated by the API before cart save/order placement. Order snapshots retain the selected size or drink brand. No schema migration was added.
- Until the owner supplies the promised shared category prices, fries sizes and drink brands use each product’s current database base price. Update the app display and API price calculation after receiving the exact values; do not invent prices. Burger size and topping prices retain their existing server-validated amounts.
- Verification for this pass: `flutter analyze --no-pub` reported no issues; `php -l backend/src/ApiApplication.php` passed; `git diff --check` passed. No Flutter tests were run for this pass.
- Next task: apply the owner’s price list consistently to the product detail display and server-side cart/order calculations.

## Auth-session recovery and QA (2026-10-20)

- Startup keeps a complete cached customer/admin identity when `/me` or token refresh cannot reach the API or receives a server error. A confirmed refresh `401` clears the saved session; a successful `/me` response with a missing/mismatched user ID or invalid role also clears stale identity.
- Added `test/auth_service_test.dart` using a mocked HTTP client. It covers profile/refresh `503`, transport failures, confirmed refresh `401`, incomplete sessions (including orphaned refresh/profile data), and inconsistent successful profile data.
- Added `test/auth_flow_test.dart` to cover sign-in → registration and registration → sign-in return paths, safe handling of invalid product/order route arguments, and guest order-history access. A failing run exposed that sign-in/register routes had dynamic result types despite callers awaiting `bool`; both routes now return `MaterialPageRoute<bool>`.
- Login now rejects non-string JSON email values explicitly instead of coercing arrays or objects to strings before validation. `php -l backend/src/ApiApplication.php` and `git diff --check` passed after this fix. The backend folder has no PHP test harness, so malformed request handling was not exercised against a running PHP/MySQL service.
- Verification: the full Flutter suite passed all 29 tests; `flutter analyze --no-pub` reported no issues; PHP syntax checks passed for both modified PHP files; `git diff --check` passed. The latest `graphify update .` rebuilt 2,058 nodes, 3,480 edges, and 125 communities. The existing `linux/runner/my_application.h` parser warning remains.
- QA coverage gap: the new login/registration flow tests use a mocked HTTP client; they do not prove live PHP/MySQL login, registration, logout, admin route gating, checkout, or order flows. Guest cart/favorites prompts also lack a full end-to-end widget test. The auth flow harness does not yet verify that a pending favorite/cart action resumes after login or that order history loads after guest sign-in.
- Current local runtime check (2026-10-20): MySQL listened on port 3306; the PHP API was started on `127.0.0.1:8081`. `GET /api/v1/products?limit=50&offset=0` returned HTTP 200 with 6 products, and `GET /api/v1/store-profile` returned HTTP 200. This confirms those public reads only; customer/admin authentication and order workflows were not checked. The store-profile response shows that table/query is available, but Admin More → App Information must be checked before declaring the complete workflow schema ready. Do not re-import migration 003 without that readiness check and a database backup.
- A malformed login request with an array-valued email returned HTTP 401; the PHP server log contained no `Array to string conversion` warning. No valid account credentials were used. The reported browser WebGL context-loss error was not reproduced by Flutter tests and remains a separate browser/GPU check.
- The Edge API CORS preflight from `http://localhost:5000` returned HTTP 204; an unconfigured origin (`http://localhost:5001`) returned HTTP 403. The Home hero now reduces image/text widths and hides secondary copy on compact screens to avoid text wrapping overflow. Full Flutter tests pass (29), `flutter analyze --no-pub` reports no issues, PHP syntax checks pass for `ApiApplication.php` and `create_admin.php`, and `git diff --check` passes. `flutter build web --no-pub --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1` succeeded; the standard JavaScript build works, with the existing `flutter_secure_storage_web` Wasm dry-run compatibility warnings.
- Next task: verify customer/admin sign-in and registration, Admin More → App Information, and a real order journey with authorized test accounts. Keep products and order/customer data intact. Record any WebGL error separately with the browser and GPU-acceleration state.

## Customer/admin UI and order-state follow-up (2026-10-20)

- Moved the existing local burger hero toward the top of customer Home, with the requested “Delicious food, delivered fast” headline and existing Order Now action. Product cards no longer invent a 4.8 rating when the API has no rating.
- The Home hero rotates the supplied burger-eating, drinks-with-friends, and fries photos every 4 seconds, with a visible slide transition, three tappable indicators, and swipe support. It now displays one full-bleed photo at a time instead of splitting the hero across two photos; a left-to-right fade keeps the headline legible while leaving the right side clear. The copied/converted assets are `assets/products/hero_burger_lifestyle.webp`, `assets/products/hero_drinks_showcase.jpg`, and `assets/products/hero_loaded_fries.jpg`. The repeated white Burger Bites ticker moves continuously from right to left and loops back in from the right.
- Hero image update verification: `flutter analyze --no-pub lib/screens/customer/home_screen.dart` reported no issues and `git diff --check` passed. No Flutter tests or browser/device visual check were run for this change.
- Redesigned the Home hamburger menu as a top-anchored, full-height responsive drawer with the transparent `BrandLogo` asset (`assets/branding/burger_bites_logo_cutout.png`), grouped navigation/preferences, softer icon tiles, a close control, and a scrollable link list. Existing destinations are unchanged. Targeted Flutter analysis passed; no browser/device visual check was run.
- Home → Our Story displays the supplied kiosk/oven/grill/burger collage at `assets/products/our_story_collage.png`. Find Us now uses a responsive map/storefront layout and the storefront crop at `assets/products/find_us_storefront.png`; the custom map is illustrative, with local pan, zoom, satellite-color toggle, and recenter controls, not a live map provider. The kiosk illustration remains as an image-load fallback.
- Find Us verification: `flutter analyze --no-pub lib/screens/customer/home_screen.dart` reported no issues. No device/browser visual check or Flutter test was run for this UI change.
- Next: visually review Find Us on phone and desktop widths. Use a live map only after confirming the store's exact address and map provider.
- Customer Home now distinguishes guest sign-in, first-load, error/retry, empty history, and saved orders. Admin Home shows placeholders until dashboard data loads, labels the real data state, and distinguishes initial order loading, API errors/retry, empty results, and previously loaded orders.
- Order providers now record whether an empty response was successfully loaded, recover from request exceptions, and reset customer order state across account changes. Customer cancellation results are ignored after logout/account switch so a late response cannot alter another account's order list.
- Added widget regression checks for product description/size/price details, guest order-history messaging, and admin placeholder states. Direct SDK `dart.exe format` completed, `flutter analyze --no-pub` reported no issues, and the full Flutter test suite passed all 29 tests. The product-details test now scrolls to the actual topping row. `git diff --check` passed. The test runner needed temporary access to Flutter cache, ignored build output, and `.dart_tool`; no lockfiles were deleted or overwritten.
- The product detail page already contains real description text, size choices, topping prices, and add-to-cart totals; the added widget test guards against its previously reported blank-layout regression.
- Live login/catalog/order checks remain blocked until the PHP API and MySQL are running. The reported CanvasKit/WebGL errors were not reproduced here. OmniRoute remains a separate pending upstream Codex-auth issue; gateway API-key success does not establish upstream provider authentication.
- Next: start API/MySQL and verify customer/admin flows with real data, then confirm database migration and catalog state. Do not claim the full system is complete until those live checks pass.

## Guest-first Menu and Profile sign-in flow (2026-10-21)

- Fresh or signed-out sessions see the existing ingredient-animation loading screen, then open Customer Home on the Menu tab; the separate Greetings screen and route were removed. Restored customer and admin sessions still go directly to their role home.
- Guests can open Profile → Sign in. The shared form routes by API-issued role: customers go to Customer Home and admins go to Admin Home. Signing out returns to the guest Menu.
- Guests can browse the public API catalog and product details. Favorite, add-to-cart, reorder, checkout, and order placement prompt guests to sign in or create a customer account. Successful authentication returns to and resumes the pending customer action.
- The app does not fabricate catalog entries. The active Docker database returned an empty product list; add real products to the selected database before expecting menu cards to appear.
- Flow diagram and current behavior: [[SCREEN_FLOW]] and [[SYSTEM_FLOW]]. `dart format` completed, `flutter analyze --no-pub` reported no issues (129.7 seconds), `graphify update .` rebuilt the local code graph, and `git diff --check` passed. The startup widget-test expectation was updated but Flutter tests and device/browser checks were not run for this change.

## Hosting direction and local verification (2026-10-16)

- Hostinger domain and hosting are the planned deployment target, but have not been purchased or configured. Do not treat the app as deployed. Once available, verify the plan's PHP/PDO-MySQL support, database version, HTTPS, rewrite rules, backups, and environment-secret configuration before deployment.
- Restarted the local API at `http://127.0.0.1:8081`. `GET /api/v1/products?limit=1` returned HTTP 200 with zero products; `GET /api/v1/store-profile` returned HTTP 503 because migration `003_app_workflows.sql` is still not imported. The browser CORS preflight for `http://localhost:5000` returned HTTP 204.
- `flutter analyze --no-pub` reported no issues (118.4 seconds); `flutter test --no-pub` passed all 10 tests. These checks do not verify workflows that require migration 003 or a populated catalog.
- Flutter Web debug builds now default to the local API URL (`127.0.0.1:8081`) when no `BURGER_BITES_API_BASE_URL` is supplied. Other targets use the explicit URLs in [[backend/README]]. The PHP API and MySQL must still be running; release builds require an explicit HTTPS URL.
- Next database step remains: export a backup in phpMyAdmin, import migration 003 once, and verify Admin More reports the workflow schema ready. Optional migration 002 contains development sample menu data only.

## Flutter mobile UI audit (2026-10-16)

- Fixed small-phone layout issues in welcome/auth, customer home, and the admin dashboard; customer and admin header menu controls now open their existing destinations. Search no longer implies voice search or preloads sample history, and reports empty/error states based on actual catalog data.
- `flutter test --no-pub --reporter expanded`: all 14 tests passed. `flutter analyze --no-pub`: no issues. Widget tests cover 320, 360, 390, and 430 px for welcome/auth, customer home, and admin dashboard; search empty state is checked at 320 px.
- `graphify update .` completed locally (1,860 nodes, 3,031 edges, 125 communities); existing `linux/runner/my_application.h` parser warning remains. No device/emulator visual review was performed. See [[SCREEN_IMPLEMENTATION_STATUS]] for remaining whole-project and backend limitations.

## AI agent monitoring system (2026-10-16)

- Added a standalone read-only local dashboard under `tools/agent-monitor/`; Obsidian remains the project memory source. The Agents tab now tracks named roles Agent 1 Frontend Developer, Agent 2 Backend/API Developer, Agent 3 QA Tester, and Agent 4 Code Reviewer. Setup and data limits: [[AGENT_MONITOR]] and [[AGENT_TEAM]].
- It reads actual local Codex JSONL session markers/tool names/exit codes and supported thread usage fields, local Git status/diffs, selected `docs/` notes, existing project images, and browser-only user-selected image/Markdown files. Prompt bodies, tool arguments, command text/output, and external uploads are excluded.
- Named-role data comes only from explicit entries in the ignored local event ledger; dashboard metrics are descriptive run/check counts, not a live API or quality score. Each run now shows event timeline, blocker labels, verification counts, and task-related paths.
- RTK 1.0.0 is installed. Project and global Codex hooks are registered, but `rtk gain` still reports no active hook in this session; restart Codex and approve any trust prompt, then verify activation. Graphify Local 0.9.90 updates code graph locally and its report/view are linked from [[AGENT_TEAM]]. ICM MCP is available for durable memory and transcript tools, not live agent events. GTX remains unidentified.
- The current monitor check results and known setup limits are recorded in [[AGENT_MONITOR]]. No app/API/database schema changes or push were made for this monitoring work.
- The separate monitor now has a Windows point-in-time process card matched by executable basename, in addition to JSONL-derived session history and explicit role events. It does not identify process publisher/path or correlate a process to a session or role. See [[AGENT_MONITOR]] for the 19-test result and HTTP/native smoke checks.
- Agent City now moves all four pixel-art figures between Command HQ and their assigned station from recorded task state: Agent 1/3 prefer the latest isolated Codex worker task and fall back to a newer explicit role-log entry; Agent 2/4 use explicit role-log entries only. The five-second refresh also shows source, status, task, and location cards; reduced-motion settings disable animation. Role-log activity is not proof of a running process. The original 3D city remains available; see [[AGENT_MONITOR]].
- Latest local monitor snapshot had no Codex worker task and one active explicit role-log record for Agent 1; that log does not verify a running Codex process. JavaScript syntax checks, served-page checks, and `git diff --check` passed; see [[AGENT_MONITOR]].
- Local checkpoint commit `3d3be2d` contains only the reviewed monitor implementation/docs; it was not pushed. Existing `.obsidian/graph.json`, `.obsidian/workspace.json`, `package-lock.json`, and mixed `docs/NEXT_SESSION.md` changes remain outside that commit.
- After the checkpoint, the Windows process snapshot, UI, tests, and integration notes were updated locally but are not committed. `graphify update .` refreshed the local code graph to 1,842 nodes / 3,007 edges / 117 communities; no label/LLM pass or upload was run.

## Customer/admin visual and store-profile pass (2026-10-15)

- Added transparent cutout assets `assets/branding/burger_bites_logo_cutout.png` and `assets/products/smash_burger_cutout.png`; the source logo/product images remain preserved.
- `BrandLogo` now uses the transparent chef-burger art. Registration and sign-in logos have a subtle motion; the welcome hero uses an isolated photoreal burger cutout with floating/tilting movement and a shifting studio glow. Motion respects the system reduced-motion setting.
- Added an admin Store Profile editor, linked from Admin More, for verified public contact, address, hours, coverage, and social details. Customer Contact reads only public data from `/store-profile`; no details are invented.
- Verification: both PNGs have transparent corners and are included in `build/web`; Flutter analyze passed, all 10 tests passed (including the admin Store Profile field check), and the standard JavaScript Web build succeeded. The Web builder emitted its existing Wasm dry-run warning for `flutter_secure_storage_web`; it did not prevent the Web build.
- A read-only `GET /api/v1/store-profile` returned HTTP 503. This is expected until migration 003 is imported because it creates `store_profile`; no schema changes were applied.
- Additional core-schema HTTP smoke checks passed favorites list/add/remove and profile read/update, fresh login, logout, and session revocation. Temporary test customer/product rows and login rate-limit records were removed; a direct count confirmed no `codex-fav-*` products or temporary smoke users remain.

## Latest customer/admin SQL workflow pass (2026-10-15)

- Customer catalog, search, favorites, account-synced cart, COD order submission, SQL order history/cancellation/reorder, burger size/topping validation and persistence, profile/password changes, preferences, and support message submission now call the PHP API.
- Admin order status/stock flow, catalog CRUD/inventory, customer status controls, dashboard totals, and support inbox/status updates now call the API. Product deletion archives the product to preserve order references.
- Admin More now checks database reachability and migration 003 readiness through an admin-only API route. Removed sample bank-account details and replaced the false “Demo Mode (No Backend)” status with live API/MySQL/schema states; payment setup shows COD active and GCash/Maya pending sandbox configuration.
- Replaced the admin home’s sample sales curve and fabricated growth percentages with a seven-day SQL order-value series from `/admin/dashboard`.
- Added user-scoped SQL cart storage and load/save/clear routes; successful order creation clears the saved cart in the same transaction. Guest carts remain local until account sign-in.
- Replaced calendar sample milestones with account-scoped reminder create/list/edit/delete UI and PHP routes. Migration 003 now creates `user_calendar_reminders`; reminders are records only and do not send phone, email, or push alerts.
- Added required migration `backend/database/migrations/003_app_workflows.sql`. It is **not yet imported** in phpMyAdmin. Read-only preflight confirmed the baseline columns and `uq_order_product` index referenced by its `ALTER TABLE` statements, compatible user/product foreign-key column types and collations, and InnoDB engines. `GET /api/v1/products?limit=1` previously returned HTTP 200 with an empty catalog, confirming the DB connection. New customer/admin workflows still need migration 003 and end-to-end checks.
- Direct database inspection confirmed the target is `burger_bites` on MySQL 8.0.45 with the seven migration-001 tables. One development admin exists (`admin@burgerbites.local`); there are no customer, product, or order rows. The API account has only CRUD grants, so migration 003 must be imported through phpMyAdmin.
- Created a local development admin account using the supported Argon2id bootstrap path. Live HTTP checks passed admin login, `/me`, authorization for `/admin/system-status`, `/me/password` including a fresh sign-in with the changed password, and logout. A temporary customer registration/`/me`/logout check passed and the customer was denied the admin endpoint with HTTP 403; that user row was deleted. The readiness endpoint correctly reports migration 003 is missing. The current generated password was returned to the user in chat and is not stored in project files.
- Optional seed migration 002 remains unapplied, so catalog screens will show their explicit empty-menu state until real products or the development catalog are inserted.
- GCash/Maya remain disabled; the user selected these providers and will provide sandbox details. No online transaction is simulated. Do not request live production secrets in chat; configure sandbox-only credentials locally in ignored backend environment settings and verify the gateway's official callback/signature requirements before implementation.
- Other unresolved integrations: courier GPS, outgoing SMS/email notifications, Google/Apple login, account recovery/email verification, real image upload, saved-address collection, and rewards/promotions. App-wide palette and core customer UI language preferences were implemented on 2026-10-24; translations should still be extended when new customer-facing copy is added.
- Latest UI follow-up: About copy describes actual app actions; Contact hides unverified business details while retaining the SQL support form; Cart displays the saved profile address rather than a fixed city; the Admin dashboard bell opens SQL-backed pending orders and shows their count; Admin More's Language & Region opens the saved preference screen; Language/Theme previews no longer show invented menu prices; Google/Apple setup messages are explicit; SMS/email/promotion switches explain that they save preferences but do not deliver messages. `dart format` completed, `flutter analyze --no-pub` passed, all 9 Flutter tests passed including checks for the Settings explanations, and `git diff --check` passed. The previous Web build succeeded after the address UI change and was not rerun after this UI pass. Graphify reports 1,648 nodes / 2,628 edges / 110 communities; the existing Linux header parse warning remains.
- Earlier API verification: PHP syntax checks passed for all 5 files under `backend/src`. The `http://localhost:5000` CORS preflight returned 204, catalog returned 200, and an unapproved origin returned 403. The admin profile widget test verifies account/password/logout controls and empty-current-password validation; valid password change and re-login passed separately over HTTP. A temporary customer saved/read/cleared the default address over HTTP and was removed. The calendar screen has no dedicated widget test. The dashboard query returned 7 date buckets. Admin login/session/password change and customer registration/role denial passed over local HTTP. Migration 003 remains unapplied, so cart/order/reminder/inventory/customer-management/support routes still need end-to-end checks.
- Git worktree remains uncommitted. Existing local Obsidian state and intro/welcome changes are preserved; no commit or push was made.

### Next task

Back up `Burger_Bites`, import migration 003 using phpMyAdmin's privileged Import account, and add verified menu products (or import optional seed 002 for a clearly identified preview). Then exercise registration, saved cart, COD customized order, cancellation/restock, and admin product/order/customer/support routes with the existing development admin. Collect GCash/Maya sandbox details before implementing online payments.

## Current state (2026-10-14)

- Flutter customer/admin screens, PHP API routes, SQL migrations, and the local MySQL setup are present. The app is not production-ready; see [[PRODUCTION_READINESS_AUDIT]].
- Earlier targeted verification: Dart analysis and all 4 Flutter tests passed; PHP syntax checks passed. APK build did not complete because DNS could not resolve `storage.googleapis.com`; no APK was produced.
- Migration `001` is installed in `burger_bites`; the restricted API account connects, and `GET /api/v1/products` returned HTTP 200 with an empty catalog. `streetfood_db` was not opened or changed.
- This repository contains the BurgerBites UI/auth/API/documentation work and local tool integrations. The user explicitly authorized publication of this change set to `origin/main`.
- RTK 1.0.0 is installed at `C:\Users\shizu\.local\bin\rtk.exe`; `rtk --version`, `rtk gain`, and `rtk init --codex` succeeded. Project hook and `RTK.md` are present. A new PowerShell/Codex session may be needed to reload the updated PATH and approve the project hook.
- ICM 0.11.4 is enabled as a Codex MCP server and its MCP handshake/tools are available. Per-project initialization reported a Windows manifest-write error, so it currently uses the local global database.
- Graphify local 0.9.90 and its Codex skill/hook are installed. Code-only extraction plus clustering produced 1,182 nodes, 1,782 edges, and 73 communities in ignored `graphify-out/`.
- Startup intro and Get Started UI are implemented: new sessions see a 4.5-second ingredient assembly then the welcome screen, while restored sessions still go directly to their role home. Get Started opens registration and Log In opens sign-in. The existing logo and smash-burger photo are reused.
- Obsidian settings exist in the project root, but whether this folder is registered/open in the user's Obsidian window and whether account Sync is active are **UNVERIFIED**. See [[OBSIDIAN_SETUP]].

## Completed in the workflow and integration pass

- Added repository guidance in [[AGENTS]].
- Documented the manual/automated boundary and integration status in [[INTEGRATION_MAP]].
- Documented how to open this project folder as the Obsidian vault in [[OBSIDIAN_SETUP]].
- Documented safe Git review and backup steps in [[BACKUP_WORKFLOW]].
- Updated project indexes and corrected the vault-registration claim to describe only the verified `.obsidian/` folder.
- Installed and verified RTK, ICM, and local Graphify. No hosted account, cloud memory, or source upload was configured.
- Generated graph output and `.obsidian/graph.json` / `.obsidian/workspace.json` are local state and must not be staged. `backend/.env` is ignored; never read or commit it.
- Updated `lib/screens/customer/splash_screen.dart`, `lib/widgets/animated_burger_assembly.dart`, and `lib/screens/customer/welcome_screen.dart` for the ingredient intro and responsive welcome screen. Updated the startup widget test and [[SCREEN_FLOW]]. Authentication/session logic and other app features were left in place.

## Verification performed for this workflow

- RTK 1.0.0: the executable works for a PowerShell `rtk git status` run, but RTK itself reports that no hook is installed; see [[AGENT_MONITOR]].
- ICM MCP tools are available in this Codex environment for memory/transcript operations; no live agent-event feed is exposed to the monitor.
- Graphify Local 0.9.90 is installed; focused query/update worked. Latest graph update: 1,743 nodes, 2,810 edges, 114 communities, with the existing `linux/runner/my_application.h` parsing warning. The monitor does not use Graphify at runtime.
- `flutter analyze --no-pub`: no issues. Earlier project verification: 4 Flutter tests passed and PHP syntax checks passed. APK build remains blocked by DNS resolution of `storage.googleapis.com`.
- Startup/Get Started verification (2026-10-14): `flutter analyze --no-pub` reported no issues; `flutter test --no-pub` passed all 4 tests.
- `git ls-remote --heads origin main` verified read-only access and the current remote branch before publication. Recheck the remote head after pushing.
- `git check-ignore --no-index -v backend/.env.example` confirms the template remains trackable; `git check-ignore -v backend/.env` confirms the secret file is ignored. Secret contents were not read.
- `git diff --check` and `git diff --cached --check` passed; Git emitted only existing working-copy LF-to-CRLF notices. A targeted check of Markdown and Obsidian links in the project/workflow index notes found no missing targets. Flutter analysis passed in this integration pass; app tests and PHP syntax checks passed earlier in this project work and were not rerun just for tool installation.

## Product details visual refresh (2026-10-23)

- Refined `lib/screens/customer/product_details_screen.dart` with a larger food hero, availability/rating badges, a centered responsive content width, clearer descriptions and option cards, a live cart count, and a persistent quantity/add-to-cart bar.
- Burger sizes and topping prices remain unchanged. Fries and drink sizes continue to use the product's current database price until the owner provides variant prices. Drink size selections (Regular/Large/XL) are stored with cart customizations; the API accepts and labels these sizes without changing their price.
- Verification: targeted Flutter analysis reported no issues; `php -l backend/src/ApiApplication.php` passed; `git diff --check` passed; `graphify update .` refreshed the local graph. Flutter tests were not run for this pass.
- Follow-up: product details now use one shared overview panel for the image-led catalog item, base price, category, availability, rating, and description. Burger, fries, and drink selectors use the same bordered option-panel style; burger sizes and toppings share one panel. Items without category options get a consistent ready-to-order panel instead of an empty-looking lower section. The template remains data-driven through `ProductDetailsScreen`, so catalog items created in Admin use this same customer detail layout when opened from the menu. Drink items whose product name contains a supported brand start with that brand selected.
- The Home category cards keep a fixed matching height, and the Menu screen uses a compact 3-photo burger/drinks/fries carousel with automatic rotation, manual swipe/dot selection, and a responsive right-side image. Removed the unverified “20% off” promotion copy.
- Current-pass verification: targeted `flutter analyze --no-pub` reported no issues; `git diff --check` passed; the three referenced carousel assets exist and `pubspec.yaml` includes `assets/products/`. `graphify update .` refreshed the local graph. Flutter tests and device/browser visual review were not run.
- Next task: get the owner’s actual drink and fries size price list before charging different prices by variant.

## Highest-priority next task

Import migration 003 with the privileged phpMyAdmin account, confirm Admin More reports schema ready, then verify store-profile read/save and the SQL-backed cart, COD order, cancellation/restock, inventory, customer, support, and reminder workflows. The store-profile editor is now implemented in the app but awaits that migration.

## Safety constraints

- Do not point the app at `streetfood_db`; `burger_bites` is the confirmed local target.
- Never commit `.env`, database credentials, OAuth secrets, payment keys, tokens, personal customer data, or `.obsidian/workspace.json` changes.
- Do not deploy publicly, stage local Obsidian/Graphify state or ignored secrets, or alter production data without explicit authorization.
- Keep local preview data labeled until screens are connected to verified API responses.

## Catalog/API and menu hero fix (2026-10-24)

- `CatalogProvider` now keeps one failed automatic catalog request from repeating on every screen entry; the menu's existing “Try again” action performs a forced retry. Unexpected fetch failures clear the loading state and remain visible as a catalog error.
- Fixed the theme palette `ListTile` ink assertion by placing the tile on its own clipped `Material` surface. Increased the home category showcase card height to prevent a 5 px phone-layout overflow.
- The Menu hero now uses the full banner for its burger/drink/fries photo carousel, with readable overlay copy and manual indicators/swipes. The previous half-width image panel is removed.
- Verification: `flutter analyze --no-pub` reported no issues; the catalog provider regression test passed; all 33 Flutter tests passed after updating a navigation test to wait for the route transition without waiting on the intentionally looping carousel.
- Runtime was restored without resetting or importing database data: AMPPS MySQL is listening on port 3306 and the PHP API was started on `127.0.0.1:8081`. `GET /api/v1/products?limit=50&offset=0` returned HTTP 200 with 6 records, and CORS allowed both `http://localhost:5000` and `http://127.0.0.1:5000`. The MySQL listener reports `::`; AMPPS-wide binding configuration was left unchanged. Refresh the running Flutter web page to retry its catalog fetch. No sample products were substituted.

## Drink brand and size pricing update (2026-10-24)

- The Menu heading now has a horizontal three-dot overflow button with a working **Refresh menu** action.
- Customer Menu cards show a selected drink brand instead of a generic stored drink name (for example, **Coca-Cola** instead of **Mocha Shake**); menu quick-add uses Coca-Cola/Regular by default and carries the selected brand/size into cart customizations.
- Drink details show the selected brand name and switch to that brand's cup crop from `assets/products/hero_drinks_showcase.jpg`.
- User-provided drink prices are shared by brand: Regular ₱150, Large ₱170, XL ₱180. The Flutter selector, displayed selected price, quick-add, cart display, and PHP API cart/order recalculation now use this same table. Server-side order naming omits the generic source product name.
- Fries prices are shared by category: Small ₱170, Medium ₱180, Large ₱190. The customer size selector, Menu card “From” price and Small quick-add, cart display, and PHP API cart/order recalculation use this same table. Sides-category products named with “fries” use the fries rules too.
- Verification: targeted `flutter analyze --no-pub` reported no issues; `php -l backend/src/ApiApplication.php` passed; `git diff --check` passed; `graphify update .` rebuilt the local graph. No Flutter tests or live browser/API order were run for the size-price follow-up.

## Customer Calendar and Contact sign-in gate (2026-10-24)

- Calendar/reminders, Contact support, and Account settings now require an authenticated customer account at the named-route boundary. This covers entry from the home menu, profile, About, and direct named-route navigation.
- Guests see the existing sign-in/create-account prompt before a protected screen is built. Canceling leaves a sign-in-required screen with retry and back actions; these pages do not load personal reminders, profile/preferences, or support form until the customer session is active. Admin sessions are not treated as customer sessions.
- Verification: targeted `flutter analyze --no-pub lib/navigation/app_router.dart lib/navigation/customer_route_gate.dart` reported no issues; `git diff --check` passed; `graphify update .` completed. Graphify reported its existing parser warning for `linux/runner/my_application.h`. No Flutter tests or live API/browser flow were run.

## Calendar reminder time and due alerts (2026-10-25)

- The Calendar already displays the account creation date from `users.created_at`, returned by the authenticated profile API.
- Customer reminders now store a date and local time. Migration `005_calendar_reminder_time.sql` adds a `TIME` column; existing reminders default to 9:00 AM. Admin More → App Information checks for this column.
- The app-wide reminder scheduler loads reminders for the signed-in customer and alerts at the due time. If browser notifications are permitted, it shows an Edge/Chrome notification; otherwise it shows an in-app alert while BurgerBites is open. The Calendar screen includes a user-clicked browser permission control and a time picker.
- Browser notification delivery is foreground/page-based. A notification is not guaranteed after the browser or app is fully closed; that requires a registered push service/service worker, which is not configured.
- Database follow-up: import `backend/database/migrations/005_calendar_reminder_time.sql` once in phpMyAdmin after backing up `Burger_Bites`; the app database user does not have `ALTER` permission. Then verify Admin More → App Information reports the new requirement ready.

## Menu bottom navigation and carousel indicator fix (2026-10-24)

- Direct `/menu` navigation now opens the normal customer app shell on the Menu tab, preserving the Home/Menu/Orders/Profile bottom navigation. Category arguments continue to select the requested menu category.
- Removed the three-dot overflow button and the separate search shortcut beside the cart. Kept the search bar and its magnifying-glass icon. Centered the three white carousel indicators along the bottom of the hero image.
- Verification: targeted `flutter analyze --no-pub lib/screens/customer/menu_screen.dart` reported no issues; `git diff --check` passed; Graphify was refreshed. No Flutter tests or device/browser visual review were run.

## App-wide color themes and language preferences (2026-10-24)

- Added a shared `AppPreferencesProvider` for local theme, display mode, and language state. Color palette and light/dark/system mode apply immediately through the shared `AppColors` tokens and `MaterialApp` themes. Theme choices are stored on the device and sync to `/me/preferences` when a configured signed-in account is available.
- Language selection applies immediately to Flutter's locale plus the app's translated customer strings. Home navigation, menu, theme/language screens, profile, cart, and product details now react to a language change. Supported choices are English, Filipino, Cebuano, Ilonggo, Waray, Spanish, Japanese, and Korean. Regional languages use Filipino for Flutter's built-in material locale while app strings retain the selected regional translation.
- Appearance and language preferences persist locally for guest users and are preserved when authentication state is cleared. Successful account sign-in can load that account's saved preferences. Updated `flutter_localizations` and `intl` to the SDK-compatible version.
- Verification: `flutter pub get` succeeded; `flutter analyze --no-pub` reported no errors (three `prefer_initializing_formals` info notices remain in the dependency-injected provider constructor); `git diff --check` passed; `graphify update .` rebuilt the local graph to 2,376 nodes / 4,049 edges / 131 communities. Graphify still reports its existing parser warning for `linux/runner/my_application.h`. No tests or browser visual review were run.

## Customer reward points and Flutter ink assertion (2026-10-25)

- Reward earning is now 0.5 point per purchased item unit: one unit earns 0.5, two earn 1.0, and quantity across all configured products is counted. The exact award is stored on the order and in `reward_transactions`; canceling an order reverses that exact amount.
- The customer Profile Burger Bites Rewards card now displays an animated progress bar from 0 to 2,500 points, current points, remaining points, and the 80%-off reward for up to five item units. The Profile summary says 0.5 point per item.
- The reported ListTile ink assertion is addressed by placing colored/bordered ListTile and SwitchListTile surfaces on their own clipped `Material` widgets in the affected customer and admin screens.
- Live read check: `GET /api/v1/products?limit=50&offset=0` returned HTTP 200 with six products, confirming the local API-to-database catalog read.
- Verification: `flutter analyze --no-pub` reported no issues; `php -l backend/src/ApiApplication.php` and `git diff --check` passed; `graphify update .` rebuilt 2,424 nodes / 4,135 edges / 133 communities. Graphify reported its existing parser warning for `linux/runner/my_application.h`. No Flutter tests were run and no order was submitted during verification.
