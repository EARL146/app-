# BurgerBites — Project Home

> Obsidian starting page for the BurgerBites Flutter project. Latest app audit: 2026-10-14.

## Start here

The project root contains `.obsidian/` and can be opened as an Obsidian vault without moving application files. It may not appear in your vault list yet. If it is not shown, choose **Open folder as vault** and select `C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`. `.obsidian/app.json` sends newly created notes to `docs/`.

The app uses Flutter/Dart with a dependency-free PHP/PDO API backed by MySQL database `burger_bites` (the user's phpMyAdmin name is `Burger_Bites`). Migration `001` is installed; the newer SQL-backed customer/admin routes require migration `003_app_workflows.sql`, which is in the repository but still awaits import. Optional catalog seed `002` is unapplied, so the live menu can be empty. Online payments, courier GPS, notifications, and app-wide localization/theme switching remain external follow-ups. See [[API_SPEC]], [[SCREEN_IMPLEMENTATION_STATUS]], and [[PRODUCTION_READINESS_AUDIT]].

## Documentation map

| Area | Notes |
| --- | --- |
| Architecture | [[PROJECT_MAP]], [[FILE_REGISTRY]], [[DECISIONS]] |
| User flows | [[SYSTEM_FLOW]], [[CUSTOMER_FLOW]], [[ADMIN_FLOW]], [[SCREEN_FLOW]] |
| Data and APIs | [[DATABASE_SCHEMA]], [[API_SPEC]] |
| Safety and quality | [[PRODUCTION_READINESS_AUDIT]], [[SECURITY]], [[TESTING]], [[PERFORMANCE_AND_SCALABILITY]], [[KNOWN_ISSUES]] |
| Setup and continuation | [[SETUP_GUIDE]], [[NEXT_SESSION]] |
| Development workflow | [[INTEGRATION_MAP]], [[OBSIDIAN_SETUP]], [[BACKUP_WORKFLOW]] |
| Design | [[SCREEN_DESIGN_SPEC]], [[SCREEN_IMPLEMENTATION_STATUS]] |
| History | [[CHANGELOG]], [[PHASE_3_COMPLETION_REPORT]], [[PHASE_3_DELIVERY_SUMMARY]], [[PHASE_4_6_DELIVERY_REPORT]] |
| Index | [[README]] · [Repository README](../README.md) · [Copilot instructions](../.github/copilot-instructions.md) |

## Current project status

- Flutter customer and admin screens exist. See [[CUSTOMER_FLOW]] and [[ADMIN_FLOW]].
- The supplied logo is in `assets/branding/burger_bites_logo.png`; fresh startup routes through the animated Splash → Greetings → public catalog. Sign-in is requested when a guest favorites or adds an item to cart. See [[SCREEN_FLOW]] and [[SYSTEM_FLOW]].
- The hard-coded admin credential was removed. PHP auth/profile/favorites/catalog/COD-order routes and SQL-backed admin workflows exist in code; migration 003 and end-to-end checks remain pending.
- Admin providers, customer catalog, favorites, cart, and customer order history call the SQL-backed API in code. Admin endpoints enforce roles on the server; migration 003 is still required before the new customer/admin flows can run against the database.
- The Figma link was inaccessible. Supplied screenshots remain the design reference; no exact Figma comparison is marked verified.

## Latest verification snapshot

- Latest `flutter test --no-pub` passed 10 tests; `flutter analyze --no-pub` reported no issues. PHP syntax checks passed in the previous backend verification pass. See [[TESTING]].
- Android SDK is available, but no Android device/emulator is connected. Android build status is in [[TESTING]].
- The Android APK build could not download Flutter engine artifacts because DNS resolution for `storage.googleapis.com` failed; no APK was produced. No Android device/emulator was connected.
- MySQL migration `001`, a least-privilege API user, and local `backend/.env` are configured. A previous `GET /api/v1/products` returned HTTP 200 with an empty catalog. `streetfood_db` remains untouched; optional seed `002` and required workflow migration `003` are unapplied.
- Backend, social login, online payment, and production infrastructure are not verified. See [[PRODUCTION_READINESS_AUDIT]] and [[KNOWN_ISSUES]].

## Navigation tips

Use the links above, or Obsidian's graph view to follow the documentation. Each documentation page links back here. Source-file responsibilities are tracked in [[FILE_REGISTRY]].
