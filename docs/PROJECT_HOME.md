# BurgerBites — Project Home

> Obsidian starting page for the BurgerBites Flutter project. Latest app audit: 2026-10-14.

## Start here

The project root contains `.obsidian/` and can be opened as an Obsidian vault without moving application files. It may not appear in your vault list yet. If it is not shown, choose **Open folder as vault** and select `C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`. `.obsidian/app.json` sends newly created notes to `docs/`.

This pass adds a dependency-free PHP API and versioned schema files. The user identified `Burger_Bites`; inspection confirmed it was empty, and migration `001` has now created the seven core tables in MySQL database `burger_bites`. The PHP API's restricted account connects successfully. `streetfood_db` was not opened or changed. Customer catalog and admin management remain local previews. See [[PRODUCTION_READINESS_AUDIT]].

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
- The supplied logo is in `assets/branding/burger_bites_logo.png`; startup routes through Splash → Greetings → Sign in/Register.
- The hard-coded admin credential was removed. PHP auth/profile/favorites/product/COD-order routes exist; MySQL is configured and the products route passed an HTTP/database smoke check. Full account/order journeys are not yet verified.
- Admin routes have a client-side role guard; admin providers and catalog/order history still use sample data. Backend authorization and persistence are missing.
- The Figma link was inaccessible. Supplied screenshots remain the design reference; no exact Figma comparison is marked verified.

## Latest verification snapshot

- `flutter test --reporter expanded` passed 4 tests; `flutter analyze --no-pub` and PHP syntax checks passed. See [[TESTING]].
- Android SDK is available, but no Android device/emulator is connected. Android build status is in [[TESTING]].
- The Android APK build could not download Flutter engine artifacts because DNS resolution for `storage.googleapis.com` failed; no APK was produced. No Android device/emulator was connected.
- MySQL migration `001`, a least-privilege API user, and local `backend/.env` are configured. `GET /api/v1/products` returned HTTP 200 with an empty catalog. `streetfood_db` remains untouched; optional seed migration `002` is unapplied.
- Backend, social login, online payment, and production infrastructure are not verified. See [[PRODUCTION_READINESS_AUDIT]] and [[KNOWN_ISSUES]].

## Navigation tips

Use the links above, or Obsidian's graph view to follow the documentation. Each documentation page links back here. Source-file responsibilities are tracked in [[FILE_REGISTRY]].
