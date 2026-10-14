# BurgerBites repository instructions

Start with [the Obsidian project home](../docs/PROJECT_HOME.md) (`[[docs/PROJECT_HOME]]`) and consult the exact source inventory in [[docs/FILE_REGISTRY]].

## Preserve this project

- Work in the existing Flutter project. Do not replace it with a generic template or delete source, assets, tests, data, or documentation.
- Inspect the actual files before making changes. Keep edits small and scoped to the requested feature.
- The Flutter tree currently contains demo/local flows. Do not claim backend, database, security, or production behavior unless it is implemented and verified.
- A separate AMPPS/PHP project or MySQL database may exist elsewhere, but do not invent its location, tables, or endpoints. Inspect a user-provided path before documenting/integrating it.

## Flutter structure and conventions

- Entry/app shell: `lib/main.dart`, `lib/app_shell.dart`.
- Routes: `lib/navigation/app_routes.dart`, `lib/navigation/app_router.dart`.
- Screens are under `lib/screens/customer/` and `lib/screens/admin/`.
- Reusable UI: `lib/widgets/`; state: `lib/providers/`; client data/value models: `lib/data/` and `lib/models/`; services: `lib/services/`.
- Use the existing Provider architecture and shared colors/theme. Keep demo behavior visibly labeled and avoid duplicating routes/constants.
- Demo admin credentials in `lib/constants/demo_admin_account.dart` are client-side preview values, not production authentication. Never add real credentials or database secrets to source or docs.

## Backend and security

- `ApiService`, `AuthService`, and `StorageService` are client abstractions. No live server/database has been verified in this project tree.
- Do not treat model JSON serializers as the real MySQL schema.
- Protected operations require server-side authentication/authorization and server-side validation. Client navigation/flags are not security controls.

## Verification and documentation

- Before claiming a command passed, run it and record the result. The latest recorded Edge run failed because C: had about 0.12 GB free; see [[docs/TESTING]] and [[docs/KNOWN_ISSUES]].
- Follow the current command order in [[docs/TESTING]]. Do not run a release/device verification claim from static analysis alone.
- For every meaningful source change, update [[docs/FILE_REGISTRY]], the relevant flow/design/security/API notes, [[docs/TESTING]], and [[docs/CHANGELOG]]. Keep [[docs/NEXT_SESSION]] useful.
- Put new Markdown notes in `docs/`, link every documentation page back to `[[PROJECT_HOME]]`, and update the home page so Obsidian navigation stays connected.
- Preserve historical reports but label their unverified claims as historical. Keep screenshots distinct from Figma verification.
