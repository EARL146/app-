# Decisions

[[PROJECT_HOME]] · [[PROJECT_MAP]] · [[SECURITY]] · [[NEXT_SESSION]]

## Current decisions and constraints

| Decision | Reason / status |
| --- | --- |
| Preserve the existing Flutter project and keep documentation under `docs/`. | The project is an existing user source tree; no source rebuild or file relocation is needed for Obsidian. |
| Use the project root as the Obsidian vault and `docs/PROJECT_HOME.md` as its entry point. | `.obsidian/` already exists in the project; `app.json` directs new notes to `docs/`. |
| Use Obsidian core File Explorer and Graph for Markdown navigation; use local Graphify for code structure. | Core plugins are enabled and project docs link to each other. Graphify is a separate local Codex tool, not an Obsidian community plugin. |
| Keep Codex and Obsidian on the same project folder; do not upload project files to an unverified service. | Markdown files under `docs/` are immediately available in the vault; no external connector is required. |
| Keep design status as screenshot-referenced, not Figma-verified. | No Figma file/frame export was found. |
| Remove local admin credentials and fail closed when the auth API is unavailable. | A hard-coded client password is not production authentication. Admin creation requires a local server-side CLI action. |
| Use `Burger_Bites` (`burger_bites`) as the local API database. | The user identified the database; read-only inspection confirmed it had no tables before the initial schema was applied. `streetfood_db` remains untouched. |
| Grant the PHP API only `SELECT`, `INSERT`, `UPDATE`, and `DELETE`. | A local `burger_bites_app` account is configured; database root credentials are not stored in the API `.env`. |
| Install RTK locally with a project Codex hook. | User requested RTK; official Windows release checksum was verified. Hook registration is present, while execution after restarting Codex still needs confirmation. |
| Use ICM as local Codex MCP memory, without cloud sync. | User requested ICM; official RTK-family project was identified. ICM 0.11.4 MCP is enabled and available; per-project manifest setup hit a Windows error and remains unresolved. |
| Use Graphify locally (the user clarified “Graptify” meant Graphify). | The local `graphifyy` package and Codex skill keep the code graph on this computer; no account or source upload is used. |

## Open decisions

- Add verified menu data before customer ordering; the optional development catalog is not imported.
- Extend the schema only when implementing saved addresses, categories, admin features, order history, and cancellation/restocking rules.
- Define production business rules for prices, taxes, delivery, inventory, payment, and order status transitions with the owner.
- Obtain Figma source/export for exact visual verification.

See [[DATABASE_SCHEMA]], [[API_SPEC]], and [[KNOWN_ISSUES]].
