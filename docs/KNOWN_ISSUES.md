# Known Issues and Blockers

[[PROJECT_HOME]] · [[TESTING]] · [[SETUP_GUIDE]] · [[NEXT_SESSION]]

## Environment blocker

- Latest `flutter run -d edge` stopped while writing `app.dill`: Windows reported `There is not enough space on the disk` (`errno = 112`). The C: drive check returned about 0.12 GB free. Free several GB, then retry and record the result.

## Application limitations

- Admin credentials are hard-coded in the Flutter client and displayed on the sign-in screen. This is a preview shortcut, not secure account authentication.
- Product, customer, cart, checkout, order history, and dashboard records are sample/in-memory data; persistence and server validation are absent/unverified.
- No PHP API/schema/database files were found in this project tree. A separate AMPPS backend may exist but has not been located or inspected.
- API host and auth paths are client-side references only; live connectivity is unverified.
- No Figma source is available and no screen has been verified against Figma.
- Only one widget smoke test is present; the current test run is not recorded as passing.
- Android debug build previously did not complete because Gradle could not remove a generated assets directory. No new APK was produced.

## Source inspection follow-up

A stray `s` after the phone string's semicolon in `lib/constants/demo_admin_account.dart` was removed during this update. The correction has not been compiler-verified because the latest run stopped from low disk space. See [[TESTING]].

See [[NEXT_SESSION]] for ordered next actions.
