# Performance and Scalability

[[PROJECT_HOME]] · [[TESTING]] · [[KNOWN_ISSUES]] · [[NEXT_SESSION]]

## Measurements available

No benchmark, load test, profile trace, memory measurement, or production workload test was found in the project records reviewed on 2026-10-14. Do not infer capacity or response-time targets from the demo.

## Current architecture limits

- Catalog, cart, sample orders, admin products, and customers are held in local lists/providers; no server pagination or durable database is connected.
- Four product photos are bundled under `assets/products/`. No image CDN, upload service, or cache policy is configured.
- `ApiService` uses a 30-second timeout but has no verified backend/retry/cancellation behavior.
- The latest Web launch attempt was blocked by a full C: drive during compilation; this is a developer-environment resource issue, not an app performance measurement.

## Work needed before scale claims

Profile on target devices; measure startup, screen transitions, memory, image decode, and catalog rendering; test real API latency and errors; add pagination and caching where measurements justify them; and load-test the backend/database with documented workload and environment. No scale or uptime claim is made. See [[API_SPEC]] and [[DATABASE_SCHEMA]].
