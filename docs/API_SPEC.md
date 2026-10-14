# API Specification

[[PROJECT_HOME]] · [[PROJECT_MAP]] · [[DATABASE_SCHEMA]] · [[SECURITY]]

## Status

No API server/controller implementation was found in this project folder and no request to a live backend was verified. The client contains generic request helpers plus auth path references. These are **client-side expectations**, not evidence that the routes exist on the AMPPS server.

## Client host and generic methods

`lib/services/api_service.dart` currently defines base host `https://api.burgerbites.com/api/v1` and 30-second timeouts. The `setBaseUrl()` method currently does not change the host. The service defines generic GET, POST, PUT, and DELETE wrappers, JSON headers, optional bearer token, JSON parsing, and generic error results.

## Auth path references in `AuthService`

| Method | Client path | Request shape seen in code | Expected response fields | Server status |
| --- | --- | --- | --- | --- |
| POST | `/auth/register` | `email`, `password` | `token`, `user_id` | Not found/verified in project. |
| POST | `/auth/login` | `email`, `password` | `token`, `user_id`, optional `refresh_token` | Not found/verified in project. |
| POST | `/auth/refresh` | `refresh_token` | `token` | Not found/verified in project. |

These calls are in `lib/services/auth_service.dart`; the current customer sign-in form's demo routing does not use this service. No product, cart, checkout, orders, admin, or customer CRUD HTTP route was found in application service calls.

## Integration work needed

Identify the real API base URL and PHP files, define server request/response and error contracts, configure environment-specific base URLs, and test requests against a development database. Keep credentials and secrets on the server. See [[SECURITY]], [[DATABASE_SCHEMA]], and [[NEXT_SESSION]].
