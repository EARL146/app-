# BurgerBites

BurgerBites is an existing Flutter food-ordering prototype with customer and administrator screens. It currently runs with local sample data; this project tree does not contain a connected PHP API or MySQL schema.

## Open the project in Obsidian

BurgerBites is registered in Obsidian's vault list. Open the `Burger_bites` vault and start with [`docs/PROJECT_HOME.md`](docs/PROJECT_HOME.md). The `.obsidian/app.json` setting directs newly created notes into `docs/`. The documentation uses Obsidian links and stays inside the existing Flutter project.

## Run on Windows

From this project directory:

```powershell
flutter pub get
flutter run -d edge
```

The latest reported Edge run stopped because C: had only about 0.12 GB free while Dart was writing a build artifact. Free several GB, then retry. See [[docs/SETUP_GUIDE]] and [[docs/KNOWN_ISSUES]].

## Current status

- Customer and admin screens are present and primarily use in-memory sample data.
- Admin preview sign-in uses a hard-coded local demo account in `lib/constants/demo_admin_account.dart`; it is not server authentication.
- Admin profile details and session-only edits are available at `lib/screens/admin/admin_profile_screen.dart`; logout returns to sign-in.
- No PHP, SQL, or migration files were found under this project directory. A separate AMPPS backend or database was not inspected.
- Supplied screenshots are the current design references. No original Figma file was found, so no screen is marked verified against Figma.
- Prior analyzer and Web build passes are recorded in [[docs/TESTING]]. The most recent `flutter run -d edge` failed from insufficient disk space.

## Documentation

Start at [[docs/PROJECT_HOME]]. See [[docs/PROJECT_MAP]], [[docs/FILE_REGISTRY]], [[docs/CUSTOMER_FLOW]], [[docs/ADMIN_FLOW]], [[docs/DATABASE_SCHEMA]], [[docs/API_SPEC]], [[docs/SECURITY]], [[docs/TESTING]], [[docs/SETUP_GUIDE]], [[docs/SCREEN_DESIGN_SPEC]], [[docs/SCREEN_IMPLEMENTATION_STATUS]], [[docs/PERFORMANCE_AND_SCALABILITY]], [[docs/DECISIONS]], [[docs/CHANGELOG]], [[docs/KNOWN_ISSUES]], and [[docs/NEXT_SESSION]].
