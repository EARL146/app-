# BurgerBites — Project Home

> Obsidian starting page for the BurgerBites Flutter project. Current audit: 2026-10-14.

## Start here

This project folder is registered in Obsidian as a vault without moving application files. Open `Burger_bites` from the vault list, then select this note. If it is not shown, choose **Open folder as vault** and select `C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`. `.obsidian/app.json` sends newly created notes to `docs/`.

The app is an existing Flutter prototype. Customer and administrator flows are largely local previews with in-memory data. No PHP endpoint, SQL schema, or MySQL migration was found inside this project directory. If an AMPPS backend exists elsewhere, its path and schema still need to be inspected before documenting it.

## Documentation map

| Area | Notes |
| --- | --- |
| Architecture | [[PROJECT_MAP]], [[FILE_REGISTRY]], [[DECISIONS]] |
| User flows | [[CUSTOMER_FLOW]], [[ADMIN_FLOW]] |
| Data and APIs | [[DATABASE_SCHEMA]], [[API_SPEC]] |
| Safety and quality | [[SECURITY]], [[TESTING]], [[PERFORMANCE_AND_SCALABILITY]], [[KNOWN_ISSUES]] |
| Setup and continuation | [[SETUP_GUIDE]], [[NEXT_SESSION]] |
| Design | [[SCREEN_DESIGN_SPEC]], [[SCREEN_IMPLEMENTATION_STATUS]] |
| History | [[CHANGELOG]], [[PHASE_3_COMPLETION_REPORT]], [[PHASE_3_DELIVERY_SUMMARY]], [[PHASE_4_6_DELIVERY_REPORT]] |
| Index | [[README]] · [Repository README](../README.md) · [Copilot instructions](../.github/copilot-instructions.md) |

## Current project status

- Flutter customer and admin screens exist. See [[CUSTOMER_FLOW]] and [[ADMIN_FLOW]].
- Admin profile shows preview details, offers local edits for name/phone/branch, and returns to sign-in on logout. These profile edits are session-only.
- The admin preview uses a hard-coded credential check in `lib/screens/customer/sign_in_screen.dart` and `lib/constants/demo_admin_account.dart`; it is not real authentication or an authorization boundary.
- Product, cart, order, customer, and dashboard data are local demo state. No server persistence was verified.
- The project contains a generic HTTP client and auth service, but no live service integration was verified. No PHP, `.env`, SQL, or migration files were found in this folder.
- Supplied screenshots guide the UI. No Figma source was available; none of the screens are marked **Verified Against Figma**.

## Latest verification snapshot

- `flutter pub get` completed on 2026-10-14.
- Previously recorded `flutter analyze --no-pub` and `flutter build web --no-pub` passed on 2026-10-14 after the admin profile work; see [[TESTING]].
- The user's latest `flutter run -d edge` stopped while writing `app.dill` because the C: drive had about 0.12 GB free. The app has not been rebuilt after that report.
- Test, Android device, production backend, and release-build coverage remains limited or not verified. See [[KNOWN_ISSUES]] and [[NEXT_SESSION]].

## Navigation tips

Use the links above, or Obsidian's graph view to follow the documentation. Each documentation page links back here. Source-file responsibilities are tracked in [[FILE_REGISTRY]].
