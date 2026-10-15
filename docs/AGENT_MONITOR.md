# AI Agent Monitoring System

[[NEXT_SESSION]] · [[INTEGRATION_MAP]]

## Separate responsibilities

- Obsidian remains the permanent BurgerBites project memory for architecture, SQL/API notes, decisions, known issues, progress, and resume instructions.
- The standalone dashboard at `tools/agent-monitor/` observes local development activity. It does not mirror the vault, edit notes, or serve as a second project knowledge base.

## Dashboard data sources

- **Codex activity:** the current Windows profile has local Codex JSONL records with session IDs, task start/completion markers, tool names, shell exit codes, file-change markers, and recorded thread usage. The dashboard reads those records read-only and omits prompts, assistant messages, tool arguments, shell command text, and tool outputs. It displays short session ID prefixes and generic task numbers because task titles require reading prompt text.
- This is an **observed local record format, not an official Codex live-session API**. The dashboard refreshes every five seconds and labels session state as inferred from the latest task marker and file modification time. Other installations may not produce these files.
- **Git:** local status, tracked diffs, configured remotes, and ahead/behind counts from cached refs. It never fetches, stages, commits, or pushes. Common credential patterns are redacted, and diff content is hidden for Obsidian settings, Graphify data, and secret files.
- **Previews:** a small allowlist of four Obsidian project notes and real existing project images. A user-selected image or Markdown attachment can also be previewed in the browser without uploading it.
- The service binds only to `127.0.0.1`, has GET-only routes, uses Python's standard library, and has no external resource dependency.

Setup, limits, and verification commands are in [tools/agent-monitor/README.md](../tools/agent-monitor/README.md).

## Integration verification (2026-10-15)

- **RTK 1.0.0:** executable is present and `rtk git status --short --branch` worked in PowerShell 7.6.5 on Windows 11 build 26200. RTK reported “No hook installed”; automatic command interception by Codex is not active or claimed.
- **Graphify Local 0.9.90:** local `graphify.exe` is installed and `graphify query` returned a focused BurgerBites graph result. “Graptify” in earlier messages refers to Graphify Local as confirmed by the user.
- **ICM:** this Codex environment exposes MCP tools named for Infinite Context Memory, including memory and transcript operations. They do not provide this dashboard with a live agent activity stream. The dashboard does not send session data to ICM.
- **GTX:** no `gtx` executable or matching MCP/app tool was available in the inspected environment; the exact product remains unverified.
- **Codex live API:** no agent-session API appeared in the tools available to this session. The local JSONL reader is the honest read-only history alternative.
- **GitHub:** GitHub MCP actions are surfaced in the environment, but this implementation does not call them. The dashboard uses local Git facts only, and no backup/push is performed.

## Known limits and next step

- Task titles and detailed error output are intentionally hidden to avoid exposing prompts, command contents, and private data. The UI shows generic task numbers and exit-code/failure markers.
- Ahead/behind values can be stale because the dashboard does not fetch remote refs.
- Next: finish the pending migration 003 rollout and admin store-profile UI/API flow, then verify the SQL workflows against the local database. Do not apply the migration from this dashboard.

## Verification (2026-10-15)

- `python -B -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: 6 tests passed, covering log privacy, incremental record reading, Git diff redaction, path traversal rejection, local HTTP note/image routes, and Host filtering.
- `python -B -m py_compile tools/agent-monitor/server.py tools/agent-monitor/test_server.py`: passed.
- `node --check tools/agent-monitor/app.js`: passed.
- `graphify update .`: completed; graph now reports 1,743 nodes, 2,810 edges, and 114 communities. Existing `linux/runner/my_application.h` parsing warning remains; no Graphify label/LLM operation was run.
- Local `/api/overview` smoke check: passed. It observed 2 recent Codex JSONL sessions, returned Git status, found 5 actual project images, and listed 4 allowed notes. No prompt bodies, tool arguments, or command output appeared in the API summary.
- `py -3 --version` resolved Python 3.14.3, matching the Windows setup command in the README.
- No Flutter, PHP, SQL, or migration checks were needed for this separate dashboard change.
