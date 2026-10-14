# Obsidian Setup

[[PROJECT_HOME]] · [[PROJECT_MAP]] · [[INTEGRATION_MAP]] · [[NEXT_SESSION]]

## Open this project as the vault

The vault folder is the project root:

`C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites`

This folder already contains `.obsidian/`. Its `app.json` sends new notes to `docs/`, and the File Explorer and Graph core plugins are enabled. No community plugin is needed for this workflow.

1. In Obsidian, use the vault switcher at the lower left and choose **Open folder as vault**.
2. Select the project root above. Do not create a new empty folder named `Burger_bites 011`.
3. Click the folder icon (File Explorer) in the left ribbon if the file pane is hidden.
4. Expand `docs/` and open [[PROJECT_HOME]].

The app code and Obsidian notes stay in the same project folder. Markdown changes written by Codex are files in `docs/`; Obsidian can display them when that vault is open. There is no separate live connector.

## Sync and privacy

The Obsidian Sync core-plugin toggle is enabled in `.obsidian/core-plugins.json`, but account configuration and active remote sync are **UNVERIFIED**. Do not assume this vault is syncing. Before enabling a sync service, decide whether the whole app source should be uploaded; the vault includes code and local project notes. `backend/.env` is ignored by Git, but external sync/privacy is a separate decision.

## Existing local state

`.obsidian/workspace.json` is already tracked by Git and currently modified. It stores local pane/workspace state; do not stage it. A `.gitignore` entry cannot untrack an existing file. See [[BACKUP_WORKFLOW]].
