# Security

[[PROJECT_HOME]] · [[API_SPEC]] · [[DATABASE_SCHEMA]] · [[KNOWN_ISSUES]]

## Current protections and behavior

- The admin preview uses a hard-coded email/password comparison in the Flutter client. The credential is also rendered on the sign-in screen. Anyone with the source or app can discover/bypass this check; it is not production authentication.
- Admin routes can be opened through the client router. There is no verified server-side role check or authorization boundary.
- `StorageService` wraps `flutter_secure_storage` for token/user values, and `ApiService` can add a bearer token. A live auth integration and platform-specific storage guarantees were not tested.
- API response parsing has generic error handling and a 30-second timeout. There is no verified server implementation, TLS deployment policy, rate limit, audit log, or token revocation contract.
- Profile edits and logout on the admin preview are local UI behavior; no persistent identity or server session is updated.

## Production blockers

1. Replace client-side credential matching with a server-authenticated flow and server-verified administrator role.
2. Remove credentials from source/UI and issue secrets only through a protected server process.
3. Enforce authorization on every protected endpoint, validate input server-side, and calculate price/inventory/order totals on the server.
4. Implement secure token expiry, refresh, revocation, logout, rate limits, safe logging, and HTTPS deployment.
5. Add integration tests for login, unauthorized role, object access, expired token, and order concurrency.

These items are not claimed as implemented. See [[DECISIONS]], [[TESTING]], and [[NEXT_SESSION]].
