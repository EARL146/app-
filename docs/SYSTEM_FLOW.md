# BurgerBites — Whole System Flow

[[PROJECT_HOME]] · [[SCREEN_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[API_SPEC]]

This describes the Flutter app and PHP API code. Migration `001` is installed in local MySQL database `burger_bites`; migration `003_app_workflows.sql` is required for saved carts, reminders, preferences, support, inventory, and expanded order states, but is not yet imported. A local HTTP smoke test passed admin login, `/me`, admin authorization on the readiness endpoint, and logout. Other migration-003 customer/admin workflows still need live verification.

## 1. Startup and authentication

```mermaid
flowchart TD
    A[Flutter starts] --> B[AppShell and shared providers]
    B --> C[Splash with supplied logo]
    C --> D{Secure stored session?}
    D -->|No| E[Greetings]
    D -->|Yes and API configured| F[GET /me]
    F -->|Valid session| G[Open server role home]
    F -->|401 expired token| H[POST /auth/refresh]
    H -->|Rotated token pair saved| F
    F -->|Offline, invalid, or rejected| E
    E --> I[Sign in or register]
    I --> J[Flutter validates form]
    J --> K[POST /auth/login or /auth/register]
    K -->|Safe error| I
    K -->|Valid token, user ID, role| L[Save session with Secure Storage]
    L --> G
    G --> M{Server role}
    M -->|customer| N[Customer home]
    M -->|admin| O[Admin home]
    O --> P[Client AdminRouteGate]
    P -. API must independently check token and role .-> Q[PHP authorization]
```

Fresh install goes Splash → Greetings → Sign in/Register. Returning users validate `/me`; if the access token expired, the client uses a refresh token once and retries `/me`. Without `BURGER_BITES_API_BASE_URL`, auth actions fail closed and the app stays in its public flow. No demo credential exists.

## 2. Browse and favorites

```mermaid
flowchart TD
    A[Customer home] --> B[CatalogProvider]
    B --> C[GET /products from SQL]
    C --> D[Menu or Search filters live catalog]
    D --> E[Product details]
    E --> F{Burger customization?}
    F -->|Yes| G[Select size and toppings]
    F -->|No| H[Use base product]
    G --> I[CartProvider keeps base product ID and options]
    H --> I
    D --> J[Favorite button]
    E --> J
    J --> K{Signed in?}
    K -->|No| L[Ask customer to sign in]
    K -->|Yes| M[GET /me/favorites]
    M --> N[POST /me/favorites or DELETE /me/favorites/id]
    N --> O[Change icon after API success]
```

Catalog/search read SQL products. Burger options remain tied to the real product row; the server calculates modifier prices instead of trusting client totals. Favorites are scoped to the signed-in user.

## 3. Cart and checkout

```mermaid
flowchart TD
    A[Choose SQL catalog product] --> B{Available and quantity valid?}
    B -->|No| C[Show message]
    B -->|Yes| D[CartProvider merges identical product/options]
    D --> E{Signed in?}
    E -->|No| F[Keep guest cart in memory]
    E -->|Yes| G[GET/PUT /me/cart syncs account cart]
    F --> H[Edit quantity or remove]
    G --> H
    H --> I[Show preview total]
    I --> J[Enter name, delivery address, phone; select COD]
    J --> K{Form valid?}
    K -->|No| L[Show validation and keep cart]
    K -->|Yes| M[POST /orders with IDs, options, and quantities]
    M --> N[Server reloads prices and checks stock]
    N --> O{COD order transaction succeeds?}
    O -->|No| P[Show error and keep cart]
    O -->|Yes and order ID returned| Q[Clear local and saved cart; show request reference]
    Q --> R[GET /me/orders shows saved order]
    R -->|Pending| S[Customer may cancel; stock is restored]
```

The Flutter cart estimate uses a 12% tax and ₱25 delivery fee. Signed-in cart changes sync to `cart_items`; guest carts remain in memory until sign-in. The PHP API re-reads product price/stock and uses configurable tax/delivery values (`ORDER_TAX_PERCENT`, `ORDER_DELIVERY_FEE`). It saves COD order and option snapshots, clears the saved cart, and decrements stock in one transaction. Admin status updates progress through pending, processing, ready, shipped, delivered; cancellation restores stock before dispatch. GCash/Maya stay disabled until sandbox/callback setup is available.

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
    PHP --> DB[(burger_bites: migrations 001 and 003)]
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
