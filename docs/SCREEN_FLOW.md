# BurgerBites — Screen Navigation Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[CUSTOMER_FLOW]] · [[ADMIN_FLOW]]

```mermaid
flowchart TD
    A[App start] --> B[4.5-second burger loading intro]
    B --> C{Saved session?}
    C -->|Valid customer| D[Customer Home]
    C -->|Valid admin| E[Admin Home]
    C -->|No session or unavailable| F[Guest app opens on Menu]
    F --> G[Browse menu, search, product details]
    D --> G
    G --> H{Favorite or add to cart?}
    H -->|Signed-in customer| I[Save favorite or cart item]
    H -->|Guest| J[Sign-in prompt]
    J -->|Sign in or create customer account| K[Sign-in form]
    J -->|Not now| G
    F --> L[Profile tab]
    L -->|Sign in| K
    K --> M{API verifies account role}
    M -->|Customer| D
    M -->|Admin| E
    M -->|Invalid| K
    I -->|Continue| N[Cart and checkout]
    E --> O[Dashboard, Orders, Products, Customers, Profile, More]
    N -->|Order accepted| P[Order history and status]
```

## Current behavior

- `lib/main.dart` starts `AppShell`; its `/` route opens the branded ingredient splash/loading screen.
- A fresh guest sees the ingredient assembly and BurgerBites wordmark, then opens the Customer Home shell on its Menu tab. The Greetings screen is removed from the startup flow.
- A valid restored customer session opens Customer Home; a valid admin session opens Admin Home. Session identity and role come from the API.
- Guests can enter Customer Home and browse the public API catalog, menu, search results, and product details. The catalog request uses `requiresAuth: false`.
- Favorite and add-to-cart controls show a sign-in/create-account prompt for guests. After successful customer sign-in or registration, the pending action resumes on the original screen. Admin sessions cannot use customer actions.
- Guests can open Profile → Sign in. The shared sign-in form routes customers to Customer Home and API-identified admins to Admin Home.
- Checkout also requires a customer session. Normal sign-in, registration, and session restoration continue to route customers and admins to their existing destinations.
- Login, registration, favorites, cart, and checkout use the existing PHP API. No local account or product fallback is added.
- An empty database catalog remains empty in the app. Products must exist in the configured database for the guest menu to display them; the UI does not invent menu items.
- Android Internet permission is declared. Release API URLs must use HTTPS.

Routes are mapped in `lib/navigation/app_router.dart`; see [[SYSTEM_FLOW]] for algorithms, state, and API contracts.
