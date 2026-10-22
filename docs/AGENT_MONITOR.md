# AI Agent Monitoring System

[[NEXT_SESSION]] · [[INTEGRATION_MAP]]

## Separate responsibilities

- Obsidian remains the permanent BurgerBites project memory for architecture, SQL/API notes, decisions, known issues, progress, and resume instructions.
- The standalone dashboard at `tools/agent-monitor/` observes local development activity. It does not mirror the vault, edit notes, or serve as a second project knowledge base.

## Dashboard data sources

- **Existing Codex activity:** the dashboard reads the current Windows profile's local Codex JSONL records with session/task markers, tool names, shell exit codes, file-change markers, and recorded usage. These records remain read-only and log-derived; prompts, assistant messages, tool arguments, shell command text, and tool output are omitted.
- **Agent City workers:** the separate task API starts Codex CLI directly with `codex exec --json --ephemeral --sandbox workspace-write --ask-for-approval on-request -`. It first verifies the installed CLI and `codex login status`. Agent 1, Agent 5, and Agent 6 start in detached Git worktrees at committed `HEAD`; uncommitted main-worktree changes are not copied. Agent 3 can run afterward in an Agent 1 task worktree. Only one process is allowed at a time. Worker events are parsed from the actual JSONL stream and reduced to safe event labels, tool categories, timestamps, exit codes, and redacted error summaries. Prompts and raw process output are not persisted. The view does not show estimated progress. Agent 5 investigates customer/admin sign-in and registration code and can use console errors explicitly supplied by the user; the dashboard cannot read a live browser DevTools session. Agent 6 (Security Engineer at the Cyber Shield Vault) audits and hardens security across Flutter, PHP/PDO, MySQL, and Docker/Redis without reading `.env` or real secrets.
- **Codex process presence:** on Windows, the overview takes a current Toolhelp32 process snapshot and returns only entries named `codex.exe` or `codex`, their PIDs, parent PIDs, and start times when available. This is a real point-in-time OS observation matched by basename only; it does not inspect the executable path/signature or map a process to the project, a JSONL session, or a named role. Other operating systems report the source unavailable.
- **Named agent roles:** `tools/agent-monitor/agents.json` defines Agent 1–6. The dashboard reads a separate local append-only event ledger written explicitly by `agent_events.py`; it summarizes only the task labels, timestamps, status, verification counts, blocker labels, and project-relative paths recorded there. It does not map anonymous Codex JSONL sessions to a role or infer results.
- Session and task details come from an **observed local record format, not an official Codex live-session API**. The dashboard refreshes every five seconds and labels session state as inferred from the latest task marker and file modification time. The separate Windows process card is OS-observed. Other installations may not produce these files or use a matching executable basename.
- **Git:** local status, tracked diffs, configured remotes, and ahead/behind counts from cached refs. It never fetches, stages, commits, or pushes. Common credential patterns are redacted, and diff content is hidden for Obsidian settings, Graphify data, and secret files.
- **Previews:** a small allowlist of six Obsidian project notes and real existing project images. A user-selected image or Markdown attachment can also be previewed in the browser without uploading it.
- The service binds only to `127.0.0.1` and uses Python's standard library for the backend. Existing monitor/data routes remain read-only; Agent City adds same-origin, confirmation-gated POST routes for starting/cancelling isolated workers. The route does not expose arbitrary shell commands or worktree paths. Agent City is rendered in 2D SVG; no Three.js dependency is required.
- Codex runs with the workspace-write sandbox and on-request command approvals. The dashboard never auto-approves protected operations; if approval is requested, the worker is stopped and marked blocked for manual review. A worker start can create files only in its managed worktree. The dashboard does not apply those files to the main worktree, commit/push, connect to MySQL, or start containers.
- Worker task records and worktrees are local, ignored files under `tools/agent-monitor/.state/agent-city/`. Worktrees are retained for inspection and are not auto-cleaned. The task form warns that prompts are sent to the user's authenticated Codex CLI and should not contain secrets or customer data.

Setup, limits, and verification commands are in [tools/agent-monitor/README.md](../tools/agent-monitor/README.md).

## Integration verification (2026-10-16)

- **RTK 1.0.0:** project and global Codex hook entries are registered (`rtk init -g --codex --show`). `rtk gain` still reports “No hook installed” in the current session; restart Codex and trust the project hook if prompted, then verify activation before claiming interception.
- **Graphify Local 0.9.90:** local `graphify.exe` is installed; `graphify query` returned a focused BurgerBites graph result. “Gratify” in the current request refers to Graphify Local, as confirmed earlier. Obsidian remains the memory vault; `docs/AGENT_TEAM.md` links the local Graphify report and graph view without adding a plugin or uploading code.
- **ICM:** this Codex environment exposes MCP tools named for Infinite Context Memory, including memory and transcript operations. They do not provide this dashboard with a live agent activity stream. The dashboard does not send session data to ICM.
- **GTX:** no `gtx` executable or matching MCP/app tool was available in the inspected environment; the exact product remains unverified.
- **Codex:** **PARTIALLY CONNECTED**. The dashboard reads local JSONL session records and, on Windows, the OS process snapshot described above. This is not an official live-session API and does not map a running process to a project, session, or role. `codex app-server` is documented as an experimental client protocol for apps that start or resume threads; this dashboard does not attach it to the existing desktop session. [Official app-server docs](https://developers.openai.com/codex/app-server).
- **GitHub:** GitHub MCP actions are surfaced in the environment, but this implementation does not call them. The dashboard uses local Git facts only, and no backup/push is performed.

## Known limits and next step

- **Current Agent City & Figma UI Studio design (2026-10-21):** Agent City is an interactive 2D tile-based office simulation (`tools/agent-monitor/city.js`, `city.css`, `index.html`, `app.js`) rendered on an HTML5 `<canvas>` with 44×30 tiles and 8 named rooms (`Frontend Room`, `Command Center`, `Backend Room`, `Main Hallway`, `Coffee & Bites Lounge`, `QA Testing Room`, `Code Review Room`, and `Debugging Room`) separated by walls and connected by doorways and hallways. Each of the six agents (`agent-1` through `agent-6`) is a separate movable character object that navigates between rooms using 8-way A* pathfinding over walkable floor/door tiles (`findPath`), avoids walls, desks, furniture, and other agents via tile reservation, and performs directional walking, idle, working, and reporting animations. Recorded task state routes agents to their assigned room and desk (`Working` → home room desk, `Securing` / `Reviewing` → `Code Review Room` / `Cyber Shield Vault`, `Testing` → `QA Testing Room`, `Debugging` → `Debugging Room`, `Completed` → `Command Center`). Users can pan/zoom the office map (mouse drag, scroll wheel, pinch-to-zoom, keyboard arrows/`+`/`-`/`0`, zoom buttons `#city-zoom-in`, `#city-zoom-out`, `#city-zoom-reset`, room quick-jump chips `#city-room-chips`, interactive minimap) and click any character or right-side agent card (`#city-agent-live-status`) to follow that agent. Reduced-motion settings disable movement and walk animations.
- **Figma & UI Studio tab (`/api/design-system`):** displays all 19 BurgerBites Customer and Admin screen artboards, brand color swatches, typography scale, and interactive button micro-animations (`AnimatedPressScale`, `AnimatedBrandButton`, `FavoriteButton` heart pop). Users can bind a Figma file URL locally in the browser or click **Download All Screens for Figma (.svg)** to export a multi-artboard vector SVG sheet ready for direct drag-and-drop import into Figma without external network calls or token storage.

- Task titles and detailed error output are intentionally hidden to avoid exposing prompts, command contents, and private data. The UI shows generic task numbers and exit-code/failure markers.
- Role-specific activity is complete only when a task start, actual verification, and finish are recorded through the CLI. These metrics are descriptive records, not an automated quality score; no role-specific token metrics are available.
- Agent roles are Agent 1 Frontend Developer, Agent 2 Backend/API Developer, Agent 3 QA Tester, and Agent 4 Code Reviewer. The dashboard now displays each run's recorded activity events, verification labels, blocker labels, and task-related paths. Paths are parent-verified context for the task, not authorship attribution.
- Agent run history is kept in the ignored local folder `tools/agent-monitor/.state/` and is not backed up to Git or Obsidian.
- The process card matches executable basenames only; it does not verify a code signature or installation path. Treat it as evidence that a process with that name was present at the displayed observation time.
- Ahead/behind values can be stale because the dashboard does not fetch remote refs.
- Next: finish the pending migration 003 rollout and admin store-profile UI/API flow, then verify the SQL workflows against the local database. Do not apply the migration from this dashboard.

## Verification (2026-10-15)

- `python -B -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: 6 tests passed, covering log privacy, incremental record reading, Git diff redaction, path traversal rejection, local HTTP note/image routes, and Host filtering.
- `python -B -m py_compile tools/agent-monitor/server.py tools/agent-monitor/test_server.py`: passed.
- `node --check tools/agent-monitor/app.js`: passed.
- `graphify update .`: completed; graph now reports 1,743 nodes, 2,810 edges, and 114 communities. Existing `linux/runner/my_application.h` parsing warning remains; no Graphify label/LLM operation was run.
- Local `/api/overview` smoke check: passed. It observed 2 recent Codex JSONL sessions, returned Git status, found 5 actual project images, and listed the configured notes. No prompt bodies, tool arguments, or command output appeared in the API summary.
- `py -3 --version` resolved Python 3.14.3, matching the Windows setup command in the README.
- No Flutter, PHP, SQL, or migration checks were needed for this separate dashboard change.

## Verification (2026-10-16)

- `py -3 -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: 15 tests passed, covering explicit role metrics, event privacy, edited-ledger label sanitization, malformed status/path handling, Git redaction, path guards, and local HTTP note/image previews.
- `py -3 -m py_compile tools/agent-monitor/server.py tools/agent-monitor/agent_events.py tools/agent-monitor/test_server.py tools/agent-monitor/test_agent_events.py`: passed.
- `node --check tools/agent-monitor/app.js`: passed.
- Synthetic unsafe verification-label probe: secret-like text was withheld as `[withheld]` from the overview response.
- `graphify update .`: completed locally; 1,827 nodes, 2,979 edges, 118 communities. The existing `linux/runner/my_application.h` parsing warning and unsupported-file skips remain.
- `rtk init -g --codex --show`: confirms local and global hook entries. `rtk gain` still says no hook is active; a Codex restart and any trust prompt remain before activation can be confirmed.
- Agent 4 re-reviewed the fixes and confirmed all six findings resolved, with no new XSS issue. Phone matching is pattern-based; names and addresses still must not be entered into agent labels.

## Agent City upgrade (2026-10-18)

- Added a local Three.js city view to the existing vanilla JS monitor, with command HQ, coding tower, testing lab, and database center. Pointer camera controls, reduced-motion support, clickable buildings, and keyboard-accessible building buttons are included. In the 3D view, Agent 1 and Agent 3 are the Codex worker characters; their lifecycle state is sourced from worker task records.
- Follow-up visual update: the default Agent City view is an isometric pixel-art office with four human-like role figures. All four walk between Command HQ and their assigned station and animate at work only from recorded task state. Agent 1/3 prefer the newest Codex worker task from `/api/tasks` and may fall back to a newer explicit local role-log run; Agent 2/4 use explicit local agent-event ledger runs from `/api/overview`, clearly labeled as log-derived rather than process activity. The existing Three.js city remains available through the 3D view switch.
- The existing five-second dashboard refresh updates four status/location/task cards. Idle and terminal roles return to Command HQ; active and blocked records route to the assigned station. Reduced-motion settings disable movement and work animation. No estimated progress or demo activity is used.
- Added a controlled Codex CLI worker adapter. Authentication check observed `codex-cli 0.163.0-alpha.10.2` and `Logged in using ChatGPT` in this environment. Real execution is still only claimed after a smoke run has succeeded; see the latest verification below.
- One worker at a time; coding runs use detached Git worktrees based on committed `HEAD`; QA runs only after a completed coding run and shares that worktree. Existing main-worktree changes are not copied, written, staged, committed, or pushed.
- Security controls: loopback binding, exact same-origin worker requests, request size limits, required explicit confirmation, fixed Codex CLI arguments, no environment API-key forwarding, prompt omission from task records, sanitized event allowlist, secret-redacted diff preview, sandbox workspace-write, and `on-request` approval. Approval requests stop and block the run; no dashboard approval button or automatic approval exists.
- Three.js package is pinned locally in `tools/agent-monitor/package.json` and `package-lock.json`; install with `npm ci --prefix tools/agent-monitor`. Docker support was not added because this local Python monitor does not need it and Docker CLI was unavailable in the audited environment.

### Agent City verification (2026-10-18)

- `py -3 -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: all 31 tests passed.
- `node --check tools/agent-monitor/app.js` and `node --check tools/agent-monitor/city.js`: passed. Importing the locally installed Three.js module in Node reported revision 186.
- `git diff --check`: passed; Git emitted only its LF-to-CRLF working-copy notices.
- `graphify update .`: completed with 2,000 nodes, 3,385 edges, and 119 communities. Existing `linux/runner/my_application.h` parser warning and unsupported-file skips remain.
- Real Codex Agent 1 smoke run: passed in an isolated detached worktree, exited 0, and created the expected smoke-test file there. Real Agent 3 ran sequentially in that worktree, but its recorded verification commands returned nonzero; the adapter correctly marks that run failed. A later bounded QA smoke attempt timed out before it could produce a verified passing result. Therefore Agent 3 execution is wired and observable, but successful QA verification is **not yet demonstrated**.
- Codex CLI status and model catalog checks passed; the adapter selected `gpt-6-luna` because the configured default model was unavailable to the authenticated account. The original Codex configuration was not changed.
- An automatically rejected cleanup request left the generated QA fixture at `C:\Users\shizu\AppData\Local\Temp\agent-city-qa-final-4ivte299`; the Codex process from that attempt was no longer running at the final process check. This fixture is outside the BurgerBites repository.
- Pixel-office follow-up: the inline SVG parsed as XML, the monitor route test confirmed both view modes and worker/role labels are served, all 31 monitor tests passed, and both dashboard JavaScript files passed `node --check`. A rendered local scene preview was inspected; no browser automation package was installed.

### Four-agent 2D activity follow-up (2026-10-18)

- The 2D roster now derives Agent 1/3 worker states from the newest `/api/tasks` record and uses a newer explicit role-log run when available. Agent 2/4 use the explicit role log only. Four SVG characters walk from Command HQ to their assigned workstation on an active/blocked record and return when the latest record is terminal or idle. Status cards show source, task, and location; the five-second refresh remains the update cadence.
- `node --check tools/agent-monitor/app.js`, `node --check tools/agent-monitor/city.js`, and `git diff --check` passed. The running monitor served the updated HTML and scripts.
- Live API snapshot: `/api/tasks` contained 0 Codex worker tasks; `/api/overview` contained an active explicit role-log record for Agent 1 and all four role definitions. This confirms the logger data is present, but does not prove a Codex process is running or verify worker-driven movement in a live task.
- `graphify update .` completed with 2,004 nodes, 3,394 edges, and 119 communities. Existing Linux header parse warning and unsupported-file skips remain.

## Windows process snapshot verification (2026-10-16)

- `py -3 -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: all 19 monitor tests passed, including process-metadata allowlisting, empty/error/unsupported process-source responses, role-event privacy, and the existing session/Git/path/preview checks.
- `py -3 -m py_compile tools/agent-monitor/server.py tools/agent-monitor/agent_events.py tools/agent-monitor/test_server.py tools/agent-monitor/test_agent_events.py`: passed. `node --check tools/agent-monitor/app.js`: passed. `git diff --check`: passed with only Git's existing LF-to-CRLF working-copy notices.
- Windows native smoke check called `codex_process_snapshot()` directly; it returned `available: true` and one basename-matched `codex.exe` record. The response contained process metadata only; no path, command line, or arguments.
- In-process HTTP smoke test of `/api/overview`: HTTP 200; process source available, one process record, eight JSONL sessions, four configured roles, and nine explicitly recorded runs across the local role ledger at that time.
- `graphify update .`: local AST/code graph refreshed to 1,842 nodes, 3,007 edges, and 117 communities. The existing `linux/runner/my_application.h` parse warning and unsupported-file skips remain; no Graphify label/LLM operation or source upload was run.
- The change adds no Codex hooks or app-server connection. [Official Codex hook docs](https://developers.openai.com/codex/hooks) say non-managed hooks must be reviewed and trusted. The [official app-server docs](https://developers.openai.com/codex/app-server) describe the transport as experimental; neither integration was activated here.
