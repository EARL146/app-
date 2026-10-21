# Admin Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[SCREEN_FLOW]] · [[SECURITY]] · [[API_SPEC]]

## Authentication and route access

- Sign-in calls the configured API. The client opens `/admin-home` only when the API response includes role `admin`.
- On app restart, a stored session is checked through `GET /me` before opening admin home.
- `AdminRouteGate` checks local session state to prevent accidental navigation to an admin screen.
- This Flutter guard is not a security boundary. PHP must authenticate every request, check the role from the validated token, authorize the target resource, and record sensitive actions.
- There is no hard-coded admin email or password in the app. A local development admin (`admin@burgerbites.local`) now exists; its generated password was shared with the user in chat and is not stored in project files. Use `backend/tools/create_admin.ps1` to add an admin with a preferred email; it refuses to overwrite an existing email.

## Admin screens

| Screen | Current behavior | Status |
| --- | --- | --- |
| Dashboard | Loads totals and a seven-day SQL order-value chart | API-backed code; authenticated live verification pending |
| Orders | Reads SQL orders and submits allowed status transitions/cancellation | API-backed code; migration readiness and live workflow verification pending |
| Products | Lists, creates, edits, archives, and changes stock through admin routes | API-backed code; authenticated live workflow verification pending |
| Customers | Reads SQL profiles/order summaries and activates/deactivates accounts | API-backed code; authenticated live workflow verification pending |
| Profile | Reads server identity, edits name/phone/branch, changes password, and logs out | Admin login, `/me`, system-status authorization, and logout passed HTTP smoke testing; profile edits/password UI not yet tested live |
| More | Reads API/database/migration readiness and accurately shows payment limits | Readiness endpoint is role-protected; migration 003 currently reports incomplete |

PHP admin management endpoints are implemented and role-protected. A local development admin (`admin@burgerbites.local`) exists; its generated password was shared in chat and is not saved in project files. Migration 003 is still required before most admin operations can load their SQL data. See [[DATABASE_SCHEMA]], [[API_SPEC]], [[SECURITY]], and [[PRODUCTION_READINESS_AUDIT]].
