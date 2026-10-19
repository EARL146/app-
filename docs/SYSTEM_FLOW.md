# BurgerBites — Whole System Flow

[[PROJECT_HOME]] · [[SCREEN_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[API_SPEC]]

This describes the customer/admin app, PHP API, MySQL data path, and the separate local development monitor. Migration `001` is installed in local MySQL database `burger_bites`; migration `003_app_workflows.sql` is required for saved carts, reminders, preferences, support, inventory, and expanded order states, but is not yet imported. The latest recorded catalog check returned no products. A local HTTP smoke test passed admin login, `/me`, admin authorization on the readiness endpoint, and logout. Other migration-003 customer/admin workflows still need live verification.

## 1. Startup and authentication

```mermaid
flowchart TD
    A[Flutter starts] --> B[AppShell and shared providers]
    B --> C[4.5-second animated burger splash]
    C --> D{Saved session?}
    D -->|No| E[Greetings]
    D -->|Yes and API configured| F[GET /me]
    F -->|Valid customer/admin| G[Open role home]
    F -->|401 expired token| H[POST /auth/refresh]
    H -->|Save rotated tokens| F
    F -->|Offline, invalid, or rejected| E
    E -->|Browse menu| N[Customer Home and public catalog]
    E -->|Log in| I[Sign in]
    I --> J[Sign in or create account]
    S --> J
    J --> K{Account action}
    K -->|Log in| K1[POST /auth/login]
    K -->|Register| K2[POST /auth/register]
    K1 -->|Safe error| I
    K2 -->|Safe error| I
    K1 -->|Valid token, user ID, role| L[Save session with Secure Storage]
    K2 -->|Valid token, user ID, role| L
    L --> G
    G --> M{Server role}
    M -->|customer| N
    M -->|admin| O[Admin home]
    N --> P[Browse menu, search, product details]
    P --> Q{Favorite or add to cart}
    Q -->|Customer session| R[Perform favorite or add-to-cart action]
    Q -->|Guest| S[Sign-in/create-account prompt]
    L -->|Action was pending| R
    O --> U[Client AdminRouteGate]
    U -. API checks token and role independently .-> V[PHP authorization]
```

Fresh install goes Splash → Greetings → Browse menu. Guests can browse without signing in. Favorites, adding products to cart, reorder, checkout, and order placement require a customer session; after sign-in or registration, the app returns to the calling product/action. Sign-in also links to registration. Returning users validate `/me`; if the access token expired, the client uses a refresh token once and retries `/me`. Without `BURGER_BITES_API_BASE_URL`, auth actions fail closed and the app stays in its public flow. No demo credential exists.

## 2. Browse and favorites

```mermaid
flowchart TD
    A[Guest or customer home] --> B[CatalogProvider]
    B --> C[Public GET /products from SQL]
    C --> D[Menu or Search filters current catalog]
    D --> E[Product details]
    E --> F{Burger customization?}
    F -->|Yes| G[Select size and toppings]
    F -->|No| H[Use base product]
    G --> I[CartProvider keeps base product ID and options]
    H --> I
    D --> J[Favorite button]
    E --> J
    J --> K{Customer session?}
    K -->|No| L[Prompt to log in or create account]
    L -->|Authentication succeeds| M[Return and resume favorite action]
    K -->|Yes| M
    M --> N[GET/POST/DELETE /me/favorites]
    N --> O[Change icon after API success]
```

Catalog, search, and product details are available to guests. The catalog endpoint is public and reads SQL products; the last recorded database check found zero product rows, so a working route can still show an empty menu until real products are added. Burger options remain tied to the real product row; the server calculates modifier prices instead of trusting client totals. Favorites are scoped to the signed-in user.

## 3. Cart and checkout

```mermaid
flowchart TD
    A[Select Add to cart] --> B{Customer session?}
    B -->|No| C[Prompt to log in or create account]
    C -->|Successful customer auth| D[Return to product and resume add]
    B -->|Yes| E[CartProvider validates availability and quantity]
    D --> E
    E -->|Invalid| F[Show message]
    E -->|Valid| G[Merge identical product/options]
    G --> H[GET/PUT /me/cart syncs customer cart]
    H --> I[Edit quantity or remove]
    I --> J[Show preview total]
    J --> K[Continue to checkout]
    K --> L[Customer session gate]
    L --> M[Enter name, delivery address, phone; select COD]
    M --> N{Form valid?}
    N -->|No| O[Show validation and keep cart]
    N -->|Yes| P[POST /orders with IDs, options, and quantities]
    P --> Q[Server reloads prices and checks stock]
    Q --> R{COD order transaction succeeds?}
    R -->|No| S[Show error and keep cart]
    R -->|Yes and order ID returned| T[Clear saved cart and show request reference]
    T --> U[GET /me/orders shows saved order]
    U -->|Pending| V[Customer may cancel; stock is restored]
```

The Flutter cart estimate uses a 12% tax and ₱25 delivery fee. UI actions require customer authentication before adding to the cart; signed-in cart changes sync to `cart_items`. The PHP API re-reads product price/stock and uses configurable tax/delivery values (`ORDER_TAX_PERCENT`, `ORDER_DELIVERY_FEE`). It saves COD order and option snapshots, clears the saved cart, and decrements stock in one transaction. Admin status updates progress through pending, processing, ready, shipped, delivered; cancellation restores stock before dispatch. GCash/Maya stay disabled until sandbox/callback setup is available.

## 4. Admin

```mermaid
flowchart TD
    A[Local CLI creates admin account]
    A --> B[Admin signs in through same auth API]
    B --> C[Server returns role from users table]
    C --> D[Flutter AdminRouteGate]
    D --> E[Admin dashboard and management UI]
    E --> F[GET /admin/dashboard SQL totals]
    E --> G[GET/PUT /admin/orders status lifecycle]
    E --> H[GET/POST/PUT/DELETE /admin/products inventory CRUD]
    E --> I[GET/PUT /admin/customers account controls]
    E --> J[GET/PUT /admin/contact-messages support inbox]
    B --> K[Profile GET/PUT /me and logout]
```

There is no default admin account/password. Use `backend/tools/create_admin.ps1` after configuring a dedicated DB. The PHP independently checks the bearer token and admin role. Admin product removal archives the item so order snapshots and foreign keys remain valid.

## 5. Provider and service map

```mermaid
flowchart LR
    UI[Flutter screens] <--> P[Provider state]
    P --> CAT[CatalogProvider: GET /products]
    P --> CART[CartProvider: local guest cart; GET/PUT /me/cart; POST /orders]
    P --> ORD[CustomerOrdersProvider: history and pending cancellation]
    P --> FAV[FavoritesProvider: favorite API]
    P --> AP[AdminProductsProvider: SQL CRUD/inventory]
    P --> AO[AdminOrdersProvider: SQL orders/status]
    P --> AC[AdminCustomersProvider: SQL customers]
    P --> DASH[AdminDashboardProvider: SQL aggregates]
    AUTH[AuthService] --> STORE[Secure Storage]
    AUTH --> API[ApiService: configured HTTPS release URL]
    API --> PHP[PHP/PDO routes]
    PHP --> DB[(burger_bites: 001 installed; 003 pending)]
    UI --> SUPPORT[Support form and admin inbox]
    UI --> PREFS[Profile, password, account preferences]
    SUPPORT --> PHP
    PREFS --> PHP
```

## 6. API route status

| Group | Code status | Runtime status |
| --- | --- | --- |
| Register/login/refresh/logout | PHP handlers implemented | Database configured; complete auth flow not integration-tested |
| Profile GET/PUT | PHP handlers implemented | Database configured; account journey not end-to-end tested |
| Products GET/list/detail | PHP handlers implemented | Code wired to SQL; catalog seed remains unapplied |
| Favorites GET/POST/DELETE | PHP handlers implemented | Database configured; account journey not end-to-end tested |
| COD order creation and customer history | PHP handlers implemented | SQL code wired; migration 003 and live order exercise pending |
| Admin products/orders/customers/dashboard | PHP handlers implemented | SQL code wired; migration 003 and live admin exercise pending |
| Support and preferences | PHP handlers implemented | Requires migration 003; live verification pending |
| Online payments, GPS, email/SMS, localization | Not implemented | Provider/service setup still needed |
| Multiple saved addresses | Not implemented | One default address remains on the user profile |

See [[API_SPEC]], [[DATABASE_SCHEMA]], [[SECURITY]], and [[PRODUCTION_READINESS_AUDIT]].

## 7. Obsidian and agent-monitor workflow

```mermaid
flowchart LR
    O[Obsidian: project memory in docs/] --> C[Codex reads relevant notes before work]
    C --> RTK[RTK: condense supported terminal output when active]
    C --> ICM[ICM MCP: supplementary local assistant memory]
    C --> GF[Graphify: local code structure graph]
    C --> W[Implement and inspect changes]
    RTK --> V[Run available checks and review Git diff]
    W --> V
    V --> O2[Update project memory notes]
    W --> G[Git local branch and GitHub remote]
    G -->|Only after user approval| B[Commit or push]
    A[Separate Agent Monitor on 127.0.0.1:8765] --> S[Observed sessions, process snapshots, Git, selected notes/images]
    A --> X[Agent 1/5 workers; Agent 3 can test Agent 1 worktree]
    X --> EV[Recorded events and worktree diff for review]
    U[User supplies redacted browser console/API errors] --> D[Agent 5 customer/admin debugger]
    D --> X
```

Obsidian remains the source of project documentation and memory. RTK only reduces terminal output for supported commands when its hook is active; it does not guarantee lower total AI usage. ICM is supplementary local Codex memory and is not connected to the dashboard's activity stream. Graphify builds a local code-structure graph; it does not replace Markdown notes or upload the project. Git/GitHub provide reviewed version history and backup, with commits and pushes gated on user approval. Current connection states and setup limits are recorded in [[INTEGRATION_MAP]].

The Agent Monitor is a separate local activity dashboard. It cannot read browser DevTools. Agent 5 can use console/API errors pasted into its task and starts from committed `HEAD` in an isolated Git worktree, so uncommitted app changes are not copied. See [[AGENT_MONITOR]] and [[AGENT_TEAM]].
