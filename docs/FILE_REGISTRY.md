# File Registry

| File or folder | Responsibility | Connections |
|---|---|---|
| `lib/main.dart` | Application entry point | Verify actual startup configuration |
| `lib/` | Screens, widgets, models, services | Inspect actual contents |
| `pubspec.yaml` | Dependencies and asset declarations | Flutter build |
| `android/` | Android configuration | Flutter Android build |
| `test/` | Automated tests | Application code |

## Rules
- Add every important Dart file.
- Explain what each file does.
- Record imports, navigation, and service dependencies.
- Update this registry whenever Codex adds, removes, or changes files.
