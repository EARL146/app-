# BurgerBites — Screen Navigation Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]]

```mermaid
flowchart TD
    A[App start] --> B[Restore saved API session]
    B -->|Valid customer session| G[Customer Home]
    B -->|Valid admin session| H[Admin Home]
    B -->|No valid session| C[4.5 second ingredient intro]
    C --> D[Get Started welcome]
    D -->|Get Started| F[Register]
    D -->|Log In| E[Sign in]
    E -->|Valid customer session| G
    E -->|Server-issued admin role| H
    F -->|Account created by API| G
    G --> I[Menu, Search, Product Details, Favorites]
    I --> J[Cart]
    J --> K[Checkout with cash on delivery]
    K -->|Server returns order ID| L[Order request received]
    K -->|API error| J
    G --> M[Profile, Settings, Order History]
    H --> N[Dashboard, Orders, Products, Customers, Profile, More]
```

## Current behavior

- `lib/main.dart` starts `AppShell`; its `/` route opens the branded splash screen.
- The splash restores secure session state with `GET /me` when a base URL and saved token exist. Valid customer/admin sessions go directly to their home screen; a fresh session sees the ingredient assembly, BurgerBites wordmark, then the Get Started welcome screen.
- The welcome screen reuses the BurgerBites logo and smash-burger photo. Get Started opens registration; Log In opens sign-in.
- Login and registration call `AuthService`; no local account fallback is allowed.
- Customer catalog and admin management data still use local sample data.
- Favorites and checkout call the PHP API routes in `backend/`; the local products route was checked against MySQL. Full account and order journeys remain unverified.
- Android Internet permission is declared. Release API URLs must use HTTPS.

Routes are mapped in `lib/navigation/app_router.dart`; see [[SYSTEM_FLOW]] for algorithms, state, and API contracts.
