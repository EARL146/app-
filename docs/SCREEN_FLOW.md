# BurgerBites — Screen Navigation Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]]

```mermaid
flowchart TD
    A[App start] --> B[Restore saved API session]
    B -->|Valid customer session| G[Customer Home and public catalog]
    B -->|Valid admin session| H[Admin Home]
    B -->|No valid session| C[4.5 second ingredient intro]
    C --> D[Greetings screen]
    D -->|Browse menu| G
    D -->|Log in| E[Sign in]
    G --> I[Menu, Search, Product Details]
    I --> J{Favorite or add to cart}
    J -->|Signed-in customer, favorite| K[Save favorite]
    J -->|Signed-in customer, add| M[Cart]
    J -->|Guest| L[Sign-in prompt]
    L -->|Log in or create account| E
    L -->|Not now| I
    E -->|Valid customer, pending favorite| K
    E -->|Valid customer, pending add| M
    E -->|Valid customer, normal sign-in| G
    E -->|Server-issued admin role| H
    M -->|Continue to checkout| N[Checkout]
    N -->|Server returns order ID| O[Order request received]
    N -->|API error| M
    G --> P[Profile and order history]
    H --> Q[Dashboard, Orders, Products, Customers, Profile, More]
```

## Current behavior

- `lib/main.dart` starts `AppShell`; its `/` route opens the branded splash screen.
- The splash restores secure session state with `GET /me`. A valid customer or admin session still goes directly to that role's home screen. A fresh session sees the ingredient assembly and BurgerBites wordmark, then the Greetings screen.
- Guests can enter Customer Home and browse the public API catalog, menu, search results, and product details. The catalog request uses `requiresAuth: false`.
- Favorite and add-to-cart controls show a sign-in/create-account prompt for guests. After successful customer sign-in or registration, the pending action resumes on the original screen. Admin sessions cannot use customer actions.
- Checkout also requires a customer session. Normal sign-in, registration, and session restoration continue to route customers and admins to their existing destinations.
- Login, registration, favorites, cart, and checkout use the existing PHP API. No local account or product fallback is added.
- An empty database catalog remains empty in the app. Products must exist in the configured database for the guest menu to display them; the UI does not invent menu items.
- Android Internet permission is declared. Release API URLs must use HTTPS.

Routes are mapped in `lib/navigation/app_router.dart`; see [[SYSTEM_FLOW]] for algorithms, state, and API contracts.
