# Customer Flow

[[PROJECT_HOME]] · [[SCREEN_IMPLEMENTATION_STATUS]] · [[API_SPEC]] · [[SECURITY]]

## Route outline

1. App starts in `lib/main.dart` and `AppShell` sends `/` to the welcome screen.
2. Welcome page links to sign-in or registration.
3. Sign-in validates fields locally. The configured admin demo email/password pair opens `/admin-home`; other valid entries follow the preview customer navigation. This does not authenticate a real account.
4. Customer home links to menu/search, product detail, cart, profile, and order history.
5. The customer can add products to `CartProvider`, update quantities, and remove items.
6. Checkout validates a name/address, simulates submission locally, clears the cart, and shows a generated reference. It does not create a persistent server order or charge payment.
7. Profile links to account settings, language, theme, calendar, contact, and about previews.

## Screen map

| Screen | Main behavior | Data source / limitation |
| --- | --- | --- |
| Welcome, sign-in, registration | Navigate and validate form fields. | Demo; no real registration/session. |
| Home, menu, search | Show promotions, category selection, products, query results. | `DemoData`; local images. |
| Product details | Show product and configure local cart action. | Local model/provider. |
| Cart, checkout, order success | Calculate local totals, validate details, show mock order ref. | No server validation, persistence, or payment. |
| Order history | Show sample status/order history. | Static demo records. |
| Profile/settings/language/theme/calendar | Show customer and preference previews. | Persistence/localization/global theme not verified. |
| Contact/about | Show contact details, FAQ, and brand content. | Contact message is not sent to a server. |

## Related source

Routes are in `lib/navigation/app_routes.dart` and `lib/navigation/app_router.dart`; page status is tracked in [[SCREEN_IMPLEMENTATION_STATUS]]. Cart math is documented in [[DATABASE_SCHEMA]] as client-only state, not database structure.
