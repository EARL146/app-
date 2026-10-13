      # Project Map

## High-level architecture

- `lib/main.dart` - Starts the Flutter application shell.
- `lib/app_shell.dart` - Provider setup, Material app, theme, and route registration.
- `lib/navigation/` - Route constants and route-to-screen mapping.
- `lib/constants/` - Brand colors and shared theme definitions.
- `lib/data/` - Local sample catalog and order records.
- `lib/models/` - User, product, cart item, and order value models.
- `lib/providers/` - In-memory cart and admin state providers.
- `lib/services/` - Generic API, auth, and secure-storage abstractions; no live backend is connected.
- `lib/screens/customer/` - Customer auth, discovery, ordering, profile, calendar, and support screens.
- `lib/screens/admin/` - Admin dashboard, order/product/customer management, and more screen.
- `lib/widgets/` - Shared product-image rendering.
- `assets/products/` - Bundled prototype food photography.
- `docs/` - Project and screenshot-driven design notes.

## Status overview

- Flutter environment: Flutter 3.47.6 and Dart 3.13.5 start successfully.
- Static analysis: `flutter analyze --no-pub` passed on 2026-10-13.
- Customer/admin UI: Implemented with local demo data.
- Screenshot/Figma comparison: Supplied screenshots are available; original Figma source and emulator comparison are not.
- Backend/database/payment: No PHP API controllers, SQL schema, live auth provider, database, or payment provider are included or connected.

See [[FILE_REGISTRY]], [[SCREEN_DESIGN_SPEC]], and [[SCREEN_IMPLEMENTATION_STATUS]].
