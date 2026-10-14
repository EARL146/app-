# Admin Flow

[[PROJECT_HOME]] · [[SYSTEM_FLOW]] · [[SCREEN_FLOW]] · [[SECURITY]] · [[API_SPEC]]

## Authentication and route access

- Sign-in calls the configured API. The client opens `/admin-home` only when the API response includes role `admin`.
- On app restart, a stored session is checked through `GET /me` before opening admin home.
- `AdminRouteGate` checks local session state to prevent accidental navigation to an admin screen.
- This Flutter guard is not a security boundary. PHP must authenticate every request, check the role from the validated token, authorize the target resource, and record sensitive actions.
- There is no hard-coded admin email or password in the app. After database setup, an authorized operator can create a new admin with `backend/tools/create_admin.ps1`; it refuses to overwrite an existing email.

## Admin screens

| Screen | Current behavior | Status |
| --- | --- | --- |
| Dashboard | Shows local sample counts, chart, and orders | Not connected to API |
| Orders | Search/filter and change sample status | Not persistent; server transition rules absent |
| Products | Local add/edit/delete/availability toggle | Not persistent; stock/API absent |
| Customers | Search and toggle sample active status | Not persistent; privacy authorization absent |
| Profile | Reads server identity fields and sends edits through `PUT /me`; logout calls `/auth/logout` | PHP route exists and DB is configured; admin login/profile journey still needs end-to-end verification |
| More | Navigation and preview settings | Several operations remain local or unimplemented |

PHP admin management endpoints remain unimplemented. The schema supports admin roles, and the database is configured. No admin account was created in this setup. See [[DATABASE_SCHEMA]], [[API_SPEC]], [[SECURITY]], and [[PRODUCTION_READINESS_AUDIT]].
