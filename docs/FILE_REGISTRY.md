# File Registry

| File or folder | Responsibility | Connections |
|---|---|---|
| `lib/main.dart` | Launches `AppShell` | Startup flow and Provider tree |
| `lib/screens/customer/splash_screen.dart`, `greetings_screen.dart` | Branded startup and initial navigation | `AppRouter`, `BrandLogo`, `AuthService` |
| `lib/widgets/brand_logo.dart` | Displays supplied chef-burger logo | `assets/branding/burger_bites_logo.png` |
| `lib/services/api_service.dart`, `auth_service.dart` | JSON API calls and secure client session/profile state | `BURGER_BITES_API_BASE_URL`, `flutter_secure_storage` |
| `lib/providers/favorites_provider.dart` | Customer-scoped favorite API calls/state | `AuthService`, `ApiService`, favorites UI |
| `lib/widgets/favorite_button.dart`, `lib/screens/customer/favorites_screen.dart` | Favorite toggle and saved-products screen | `FavoritesProvider`, `/me/favorites` contract |
| `lib/navigation/admin_route_gate.dart` | Client-side guard around admin screens | `AuthService`; not server authorization |
| `test/cart_provider_test.dart` | Cart arithmetic and availability tests | `CartProvider` |
| `test/widget_test.dart` | Startup/greetings/sign-in navigation test | Splash/Greetings/Router |
| `docs/SYSTEM_FLOW.md` | Whole-app Mermaid diagrams, current demo algorithms, state map, and route groups | [[PROJECT_HOME]], `lib/app_shell.dart`, `lib/navigation/app_router.dart`, providers and customer/admin screens |
| `docs/PRODUCTION_READINESS_AUDIT.md` | Current architecture, feature status, blockers, and next steps | Flutter source, AMPPS environment, other audit notes |
| `lib/` | Screens, widgets, models, services | Inspect actual contents |
| `pubspec.yaml` | Dependencies and asset declarations | Flutter build |
| `android/` | Android configuration | Flutter Android build |
| `backend/public/index.php`, `backend/src/` | PHP API routing, HTTP helpers, PDO, session and order logic | `backend/.env`, SQL schema |
| `backend/database/migrations/` | Initial schema and optional development catalog seed | phpMyAdmin/MySQL; not yet applied |
| `backend/tools/create_admin.ps1`, `create_admin.php` | Local administrator bootstrap after database setup | Argon2id, local database config |
| `backend/README.md` | PHP/MySQL API setup and startup commands | [[SETUP_GUIDE]], [[API_SPEC]] |
| `test/` | Automated tests | Application code |

## Rules
- Add every important Dart file.
- Explain what each file does.
- Record imports, navigation, and service dependencies.
- Update this registry whenever Codex adds, removes, or changes files.
