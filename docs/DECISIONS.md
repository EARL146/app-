# Decisions

[[PROJECT_HOME]] · [[PROJECT_MAP]] · [[SECURITY]] · [[NEXT_SESSION]]

## Current decisions and constraints

| Decision | Reason / status |
| --- | --- |
| Preserve the existing Flutter project and keep documentation under `docs/`. | The project is an existing user source tree; no source rebuild or file relocation is needed for Obsidian. |
| Use the project root as the Obsidian vault and `docs/PROJECT_HOME.md` as its entry point; register it in the vault list. | No `.obsidian` folder existed in this project. Existing unrelated vaults were preserved. |
| Direct new Obsidian notes to `docs/`. | Minimal `.obsidian/app.json` preference; application source remains in place. |
| Keep design status as screenshot-referenced, not Figma-verified. | No Figma file/frame export was found. |
| Label local auth/data as demo-only. | Current app paths use local hard-coded credentials and in-memory providers; a live service/database was not verified. |
| Do not invent PHP endpoints, SQL tables, or database relationships. | No backend/database artifacts were found under this project root. |

## Open decisions

- Locate and inspect the separate AMPPS/PHP backend and actual MySQL schema, if they exist.
- Choose and document the real authentication/API contract only after reviewing that backend.
- Define production business rules for prices, taxes, delivery, inventory, payment, and order status transitions with the owner.
- Obtain Figma source/export for exact visual verification.

See [[DATABASE_SCHEMA]], [[API_SPEC]], and [[KNOWN_ISSUES]].
