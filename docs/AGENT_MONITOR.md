# AI Agent Monitoring System

[[NEXT_SESSION]] · [[INTEGRATION_MAP]]

## Separate responsibilities

- Obsidian remains the permanent BurgerBites project memory for architecture, SQL/API notes, decisions, known issues, progress, and resume instructions.
- The standalone dashboard at `tools/agent-monitor/` observes local development activity. It does not mirror the vault, edit notes, or serve as a second project knowledge base.

## Dashboard data sources

- **Codex activity:** the current Windows profile has local Codex JSONL records with session IDs, task start/completion markers, tool names, shell exit codes, file-change markers, and recorded thread usage. The dashboard reads those records read-only and omits prompts, assistant messages, tool arguments, shell command text, and tool outputs. It displays short session ID prefixes and generic task numbers because task titles require reading prompt text.
- **Codex process presence:** on Windows, the overview takes a current Toolhelp32 process snapshot and returns only entries named `codex.exe` or `codex`, their PIDs, parent PIDs, and start times when available. This is a real point-in-time OS observation matched by basename only; it does not inspect the executable path/signature or map a process to the project, a JSONL session, or a named role. Other operating systems report the source unavailable.
- **Named agent roles:** `tools/agent-monitor/agents.json` defines Agent 1–4. The dashboard reads a separate local append-only event ledger written explicitly by `agent_events.py`; it summarizes only the task labels, timestamps, status, verification counts, blocker labels, and project-relative paths recorded there. It does not map anonymous Codex JSONL sessions to a role or infer results.
- Session and task details come from an **observed local record format, not an official Codex live-session API**. The dashboard refreshes every five seconds and labels session state as inferred from the latest task marker and file modification time. The separate Windows process card is OS-observed. Other installations may not produce these files or use a matching executable basename.
- **Git:** local status, tracked diffs, configured remotes, and ahead/behind counts from cached refs. It never fetches, stages, commits, or pushes. Common credential patterns are redacted, and diff content is hidden for Obsidian settings, Graphify data, and secret files.
- **Previews:** a small allowlist of six Obsidian project notes and real existing project images. A user-selected image or Markdown attachment can also be previewed in the browser without uploading it.
- The service binds only to `127.0.0.1`, has GET-only routes, uses Python's standard library, and has no external resource dependency.

Setup, limits, and verification commands are in [tools/agent-monitor/README.md](../tools/agent-monitor/README.md).

## Integration verification (2026-10-16)

- **RTK 1.0.0:** project and global Codex hook entries are registered (`rtk init -g --codex --show`). `rtk gain` still reports “No hook installed” in the current session; restart Codex and trust the project hook if prompted, then verify activation before claiming interception.
- **Graphify Local 0.9.90:** local `graphify.exe` is installed; `graphify query` returned a focused BurgerBites graph result. “Gratify” in the current request refers to Graphify Local, as confirmed earlier. Obsidian remains the memory vault; `docs/AGENT_TEAM.md` links the local Graphify report and graph view without adding a plugin or uploading code.
- **ICM:** this Codex environment exposes MCP tools named for Infinite Context Memory, including memory and transcript operations. They do not provide this dashboard with a live agent activity stream. The dashboard does not send session data to ICM.
- **GTX:** no `gtx` executable or matching MCP/app tool was available in the inspected environment; the exact product remains unverified.
- **Codex:** **PARTIALLY CONNECTED**. The dashboard reads local JSONL session records and, on Windows, the OS process snapshot described above. This is not an official live-session API and does not map a running process to a project, session, or role. `codex app-server` is documented as an experimental client protocol for apps that start or resume threads; this dashboard does not attach it to the existing desktop session. [Official app-server docs](https://developers.openai.com/codex/app-server).
- **GitHub:** GitHub MCP actions are surfaced in the environment, but this implementation does not call them. The dashboard uses local Git facts only, and no backup/push is performed.

## Known limits and next step

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

## Windows process snapshot verification (2026-10-16)

- `py -3 -m unittest discover -s tools/agent-monitor -p "test_*.py" -v`: all 19 monitor tests passed, including process-metadata allowlisting, empty/error/unsupported process-source responses, role-event privacy, and the existing session/Git/path/preview checks.
- `py -3 -m py_compile tools/agent-monitor/server.py tools/agent-monitor/agent_events.py tools/agent-monitor/test_server.py tools/agent-monitor/test_agent_events.py`: passed. `node --check tools/agent-monitor/app.js`: passed. `git diff --check`: passed with only Git's existing LF-to-CRLF working-copy notices.
- Windows native smoke check called `codex_process_snapshot()` directly; it returned `available: true` and one basename-matched `codex.exe` record. The response contained process metadata only; no path, command line, or arguments.
- In-process HTTP smoke test of `/api/overview`: HTTP 200; process source available, one process record, eight JSONL sessions, four configured roles, and nine explicitly recorded runs across the local role ledger at that time.
- `graphify update .`: local AST/code graph refreshed to 1,842 nodes, 3,007 edges, and 117 communities. The existing `linux/runner/my_application.h` parse warning and unsupported-file skips remain; no Graphify label/LLM operation or source upload was run.
- The change adds no Codex hooks or app-server connection. [Official Codex hook docs](https://developers.openai.com/codex/hooks) say non-managed hooks must be reviewed and trusted. The [official app-server docs](https://developers.openai.com/codex/app-server) describe the transport as experimental; neither integration was activated here.
