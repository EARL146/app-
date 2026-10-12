# File Registry

## Verified files

- `lib/main.dart` — existing app entry; retained and wrapped with the new application shell.
- `lib/app_shell.dart` — current foundation app shell and session bootstrap.
- `lib/navigation/app_routes.dart` — route constants.
- `lib/constants/app_colors.dart` — verified design system palette.
- `lib/constants/app_theme.dart` — theme definition.
- `lib/services/storage_service.dart` — secure storage for tokens and user data.
- `lib/services/api_service.dart` — generic API abstraction layer.
- `lib/services/auth_service.dart` — authentication and session state logic.
- `lib/models/user_model.dart` — user profile model.
- `lib/models/product_model.dart` — product model.
- `lib/models/order_model.dart` — order and status models.

## Status legend

- Verified = implemented and inspected.
- Planned = future work required.
- Partial = initial shell only.

## Current state

The foundation shell is implemented. The complete UI and backend integrations remain planned and will be updated as work proceeds.
