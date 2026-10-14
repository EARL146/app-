# Testing and Verification

[[PROJECT_HOME]] · [[SETUP_GUIDE]] · [[KNOWN_ISSUES]] · [[SCREEN_IMPLEMENTATION_STATUS]]

## Recorded command results

| Command | Recorded result | Context |
| --- | --- | --- |
| `flutter pub get` | Passed on 2026-10-14. | User terminal output: dependencies resolved; newer incompatible versions were informational. |
| `dart format` on modified Dart files | Completed on 2026-10-14. | Recorded during admin profile implementation. |
| `flutter analyze --no-pub` | Passed with no issues on 2026-10-14. | Recorded after admin profile implementation. It was not rerun after the latest disk-space report. |
| `flutter build web --no-pub` | Passed on 2026-10-14. | Standard Web build completed; non-blocking Wasm compatibility notices appeared for secure-storage Web plugin. |
| `flutter build apk --debug --no-pub` | Failed to complete. | Gradle could not remove an existing generated assets directory; no APK was produced. |
| `flutter run -d edge` | Latest user run failed during compilation. | Dart could not write `app.dill`; Windows reported disk full (`errno = 112`). A disk check showed about 0.12 GB free on C:. |
| `flutter test` | Not run in this turn. | Only one widget smoke test exists at `test/widget_test.dart`; no current result is claimed. |

## Test coverage present

`test/widget_test.dart` pumps `AppShell` and verifies a `MaterialApp` is present. No dedicated tests were found for cart totals, form validation, admin profile/logout, route authorization, APIs, persistence, or database behavior.

## Next verification sequence

After freeing several GB on C: and checking for source syntax issues, from the project root run:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run -d edge
```

Record each actual result and distinguish resource failures from compiler/test failures. See [[KNOWN_ISSUES]] and [[NEXT_SESSION]].
