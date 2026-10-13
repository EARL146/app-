# File Registry

## Navigation

- [[PROJECT_MAP]]
- [[SCREEN_DESIGN_SPEC]]
- [[SCREEN_IMPLEMENTATION_STATUS]]
- [[README]]

## Application entry and theme

| Path | Responsibility | State |
| --- | --- | --- |
| `lib/main.dart` | Starts `AppShell`. Legacy prototype classes remain in the file below the entry point. | Existing source retained |
| `lib/app_shell.dart` | Creates providers and `MaterialApp`; installs the route generator and global theme. | Implemented |
| `lib/navigation/app_router.dart` | Maps route names and arguments to customer/admin screens. | Implemented |
| `lib/navigation/app_routes.dart` | Route name constants used by app navigation. | Implemented |
| `lib/constants/app_colors.dart` | Brand palette, surfaces, text, and state colors. | Updated for screenshot direction |
| `lib/constants/app_theme.dart` | Shared Material theme, inputs, buttons, cards, and bottom navigation style. | Updated |

## Screens

- `lib/screens/customer/` contains `welcome_screen.dart`, `sign_in_screen.dart`, `register_screen.dart`, `home_screen.dart`, `menu_screen.dart`, `search_screen.dart`, `product_details_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `order_success_screen.dart`, `order_history_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `language_screen.dart`, `theme_screen.dart`, `calendar_screen.dart`, `contact_screen.dart`, and `about_screen.dart`.
- `lib/screens/admin/` contains `admin_home_screen.dart`, `admin_orders_screen.dart`, `admin_products_screen.dart`, `admin_add_product_screen.dart`, `admin_edit_product_screen.dart`, `admin_customers_screen.dart`, and `admin_more_screen.dart`.
- `lib/widgets/food_image.dart` resolves bundled product image assets, category fallbacks, and optional network image URLs.

The screens are wired to local providers and demo data. See [[SCREEN_IMPLEMENTATION_STATUS]] for per-screen limits.

## State, models, and services

| Path | Responsibility | State |
| --- | --- | --- |
| `lib/data/demo_data.dart` | Local menu categories, products, and sample customer orders. | Demo data |
| `lib/providers/cart_provider.dart` | In-memory cart, total calculations, local checkout reference generation. | Demo-only |
| `lib/providers/admin_orders_provider.dart` | In-memory admin orders, filtering, and local status changes. | Demo-only |
| `lib/providers/admin_products_provider.dart` | In-memory product list, add/edit/delete, search, and availability toggle. | Demo-only |
| `lib/providers/admin_customers_provider.dart` | In-memory sample customer records and controls. | Demo-only |
| `lib/models/product_model.dart` | Product and order-item value models. | Implemented |
| `lib/models/order_model.dart` | Order values and statuses. | Implemented |
| `lib/models/user_model.dart` | User profile value model. | Present |
| `lib/services/api_service.dart` | Generic HTTP client abstraction. Its configured host is a placeholder, not a verified backend. | Not connected |
| `lib/services/auth_service.dart` | Auth/session service abstraction. | Not connected to a real provider |
| `lib/services/storage_service.dart` | Secure storage wrapper for token/user values. | Present; production session flow not verified |

## Product assets

- `assets/products/smash_burger.jpg`
- `assets/products/loaded_fries.jpg`
- `assets/products/crispy_chicken.jpg`
- `assets/products/cola.jpg`
- `pubspec.yaml` declares the `assets/products/` bundle.

## Platform, tests, and backend inventory

- Flutter platform folders are present for Android, iOS, web, Windows, macOS, and Linux.
- `test/widget_test.dart` is the existing Flutter widget-test file. It was not run for this redesign.
- No PHP API controllers, SQL schema/migrations, or database dump are included in this archive.
- `docs/SCREEN_DESIGN_SPEC.md` records screenshot-driven UI requirements; the original Figma source was not found.
