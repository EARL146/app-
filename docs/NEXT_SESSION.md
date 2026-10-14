# Next Session

[[PROJECT_HOME]] · [[KNOWN_ISSUES]] · [[TESTING]] · [[SETUP_GUIDE]]

## Current state (2026-10-14)

- Existing Flutter project is preserved at `C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`.
- Project folder is prepared as an Obsidian vault. Start at `docs/PROJECT_HOME.md`; `.obsidian/app.json` directs new notes to `docs/`.
- Admin profile is present with local demo details/edit behavior and logout navigation.
- Most catalog/admin/customer data remains demo/in-memory. No live PHP API or MySQL schema was found in this project tree.
- Prior analyzer and Web build results passed on 2026-10-14; latest Edge launch failed writing `app.dill` because C: had about 0.12 GB free.

## Next tasks, in order

1. Free several GB on C:; a stray trailing `s` was removed from `lib/constants/demo_admin_account.dart`, but the correction still needs compiler verification. Preserve the current demo credential unless the owner asks to change it.
2. Run `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, then `flutter run -d edge`; record each actual result in [[TESTING]].
3. Ask for/locate the separate AMPPS PHP project path and inspect it read-only before updating [[API_SPEC]] or [[DATABASE_SCHEMA]]. Never document guessed endpoints/tables or copy secrets.
4. If Figma verification is required, obtain the Figma file or frame exports and update [[SCREEN_DESIGN_SPEC]] and [[SCREEN_IMPLEMENTATION_STATUS]] after visual comparison.
5. Add focused tests for sign-in routing, admin profile edit/logout, cart math, and important error cases before any production claim.

## Constraints

- Preserve the existing Flutter project, user assets, and any separate backend/database. Do not rebuild from a generic template or delete data.
- Keep demo-only, tested, untested, and production behavior clearly distinguished.
- Update [[FILE_REGISTRY]], relevant flow/security/data notes, [[TESTING]], and [[CHANGELOG]] whenever source behavior changes.
- All new Markdown pages belong in `docs/` and must link back to [[PROJECT_HOME]].
