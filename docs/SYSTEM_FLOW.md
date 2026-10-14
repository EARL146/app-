# BurgerBites — Whole System Flow

[[PROJECT_HOME]] · [[SCREEN_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]] · [[PRODUCTION_READINESS_AUDIT]] · [[API_SPEC]]

This describes the Flutter app and PHP API code. Migration `001` is installed in local MySQL database `burger_bites`, and the restricted PHP account has passed a database-backed product-list request. Production hosting and several screen integrations remain incomplete.

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
    A[Customer home] --> B[Menu or Search]
    B --> C[Current screen reads local DemoData]
    C --> D[Product details]
    C --> E[Favorite button]
    D --> E
    E --> F{Signed in?}
    F -->|No| G[Ask customer to sign in]
    F -->|Yes| H[GET /me/favorites]
    H --> I[POST /me/favorites or DELETE /me/favorites/id]
    I --> J[Change icon after API success]
```

The PHP product read routes exist, but Flutter menu/search do not call them yet. Favorites routes scope reads/writes to the bearer-token user. SQL uniqueness prevents duplicate favorite rows; database behavior is not tested until migration setup.

## 3. Cart and checkout

```mermaid
flowchart TD
    A[Choose sample product] --> B{Available and quantity valid?}
    B -->|No| C[Show message]
    B -->|Yes| D[CartProvider merges identical IDs]
    D --> E[Edit quantity or remove]
    E --> F[Show preview total]
    F --> G[Enter name, delivery address, phone; select COD]
    G --> H{Form valid?}
    H -->|No| I[Show validation and keep cart]
    H -->|Yes| J[POST /orders with IDs and quantities]
    J --> K{Server transaction succeeds?}
    K -->|No| L[Show error and keep cart]
    K -->|Yes and order ID returned| M[Clear cart and show request reference]
```

The Flutter preview uses a 12% tax and ₱25 delivery fee. The PHP API re-reads product price/stock and uses configurable tax/delivery values (`ORDER_TAX_PERCENT`, `ORDER_DELIVERY_FEE`). It writes COD order snapshots and decrements stock in one transaction. These rules are not validated against the restaurant's actual business rules; there is no admin cancel/restock lifecycle yet.

## 4. Admin

```mermaid
flowchart TD
    A[Local CLI creates admin account]
    A --> B[Admin signs in through same auth API]
    B --> C[Server returns role from users table]
    C --> D[Flutter AdminRouteGate]
    D --> E[Admin dashboard and management UI]
    E --> F[Current dashboard, products, orders, customers use local samples]
    E -. Admin API not implemented .-> G[No persistent admin operation]
    B --> H[Profile GET/PUT /me and logout]
```

There is no default admin account/password. Use `backend/tools/create_admin.ps1` after configuring a dedicated DB. The PHP admin management routes are not implemented; the Flutter gate is only a navigation check.

## 5. Provider and service map

```mermaid
flowchart LR
    UI[Flutter screens] <--> P[Provider state]
    P --> CART[CartProvider: preview cart; POST /orders]
    P --> FAV[FavoritesProvider: favorite API]
    P --> AP[Admin products: local preview]
    P --> AO[Admin orders: local preview]
    P --> AC[Admin customers: local preview]
    AUTH[AuthService] --> STORE[Secure Storage]
    AUTH --> API[ApiService: configured HTTPS release URL]
    API --> PHP[PHP/PDO routes]
    PHP --> DB[(burger_bites: 7 core tables)]
    DATA[DemoData] --> CATALOG[Menu, search, admin preview]
```

## 6. API route status

| Group | Code status | Runtime status |
| --- | --- | --- |
| Register/login/refresh/logout | PHP handlers implemented | Database configured; complete auth flow not integration-tested |
| Profile GET/PUT | PHP handlers implemented | Database configured; account journey not end-to-end tested |
| Products GET/list/detail | PHP handlers implemented | Flutter screens still use local preview |
| Favorites GET/POST/DELETE | PHP handlers implemented | Database configured; account journey not end-to-end tested |
| COD order creation | PHP handler implemented | Schema configured; order journey not end-to-end tested; no cancel/restock endpoint |
| Admin products/orders/customers | Not implemented | Screens use local preview |
| Customer order history and multiple addresses | Not implemented | Screens/features use preview or single profile address |

See [[API_SPEC]], [[DATABASE_SCHEMA]], [[SECURITY]], and [[PRODUCTION_READINESS_AUDIT]].
