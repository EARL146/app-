# BurgerBites Agent Monitor

This is a separate, local-only dashboard for observable development activity. Obsidian remains the project memory system. The dashboard previews a small allowlist of notes and existing images; it does not mirror the vault, rewrite notes, or modify the BurgerBites app/API/database. Named agent activity is sourced only from explicit local entries recorded with `agent_events.py`.

## Run on Windows

From the BurgerBites repository root in PowerShell:

```powershell
py -3 tools/agent-monitor/server.py
```

If the Python launcher is not installed but `python` is available:

```powershell
python tools/agent-monitor/server.py
```

Open `http://127.0.0.1:8765`. Press `Ctrl+C` in the terminal to stop it. The Python service binds only to loopback and has no public listener. Worker routes accept same-origin requests from this dashboard only.

## Data sources and limits

- **Codex activity:** reads up to the eight newest local `~/.codex/sessions/**/*.jsonl` files modified in the last 90 days and no larger than 150 MB each (or `%CODEX_HOME%\sessions` when that variable is set). The current Windows environment has local records containing session metadata, task start/completion markers, tool names, shell exit codes, file-change markers, and Codex usage records. Appended records are read incrementally. The file format is an observed local record format, not a public live-session API. The UI labels it accordingly and refreshes every five seconds. Other Codex installations may not write these records.
- **Windows process snapshot:** reads a point-in-time Toolhelp process list and reports only entries whose executable basename is `codex.exe` or `codex`, with PID, parent PID, and start time when available. It never reads or returns command lines, arguments, environment variables, executable paths, or publisher signatures. A basename match does not prove which product launched the process and is not linked to a project, JSONL session, or named role. Non-Windows systems report the source as unavailable.
- **Named agent roles:** `agents.json` lists Agent 1 Frontend Developer, Agent 2 Backend/API Developer, Agent 3 QA Tester, Agent 4 Code Reviewer, and Agent 5 Customer/Admin Debugger. The separate `.state/agent-events.jsonl` ledger contains only explicit task labels, timestamps, terminal statuses, entered verification counts, blocker labels, and project-relative paths related to the task. Start it before assigning a role task, enter checks only after observing their real output, and finish it after reviewing the agent's result. The dashboard computes descriptive counts and elapsed wall time from those records; it does not measure code quality or infer missing events. Listed paths are task-related files verified by the parent, not proof of which person or agent authored them.
- **Privacy:** prompts, message bodies, tool arguments, command strings, tool output, MCP arguments/results, and full session IDs are not returned to the browser. Shell command activity shows only a timestamp and exit code. MCP activity shows the tool name and recorded status. The role ledger rejects common email, phone-like, secret, bearer-token, and API-key patterns, but it is not a complete personal-data detector; never record customer details. This does not provide a reliable semantic task title or detect a human pause; open task markers are reported from the log as observed.
- **Usage:** token figures are displayed only from a Codex `thread_token_usage` record. The monitor does not estimate usage or sum repeated cumulative records.
- **Git:** status and diffs are read from this local worktree. Diff preview redacts common secret assignments; content for `.obsidian`, `graphify-out`, and secret paths is hidden. Ahead/behind values use cached remote-tracking refs. The monitor never fetches, stages, commits, pushes, or contacts GitHub.
- **Project files:** note previews are limited to `docs/AGENT_TEAM.md`, `docs/AGENT_MONITOR.md`, `docs/NEXT_SESSION.md`, `docs/KNOWN_ISSUES.md`, `docs/TESTING.md`, and `docs/INTEGRATION_MAP.md`. Image previews come only from existing files under `assets/`, `lib/assets/`, `web/assets/`, or `docs/assets/`, with a 20 MB per-file limit. Paths are resolved and checked to stay within this repository. You may also choose a local image or Markdown attachment in the browser; that preview uses the browser's local file handle and sends no file data to the server.
- **Agent City:** the city is a 2D isometric open-office scene with a live five-agent roster. Agents with recorded preparing/running/active/blocked tasks walk to distinct shared desks; idle or terminal agents return to the office floor. Agent 1, Agent 3, and Agent 5 use the isolated Codex worker API. Agent 2 and Agent 4 use only explicit local role-log records; those records do not prove a process is running. The status cards refresh on the five-second poll, show each task's source, and do not estimate progress. Reduced-motion preferences disable movement animations.
- **Codex workers:** the adapter checks `codex --version` and `codex login status` before a run. Agent 1 and Agent 5 each create a detached Git worktree from committed `HEAD`; staged/unstaged changes in the main worktree are not copied. Agent 3 may test a completed Agent 1 worktree. Only one worker process can run at a time. Agent 5 is a focused customer/admin sign-in and account-creation debugger. It can inspect code and existing checks and use redacted console/API errors the user provides; the dashboard has no connection to live browser DevTools. Without supplied console output, Agent 5 must say so and report a code/test investigation instead. The CLI receives fixed `--json --ephemeral --sandbox workspace-write --ask-for-approval on-request` flags; the dashboard never sets `--approve-for-me` or bypasses the sandbox. If Codex asks for protected approval, the run is stopped and marked blocked; the dashboard cannot grant that approval. A user must explicitly confirm each start and cancellation in the dashboard.
- **Worker history and privacy:** normalized JSON event types, timestamps, tool categories, exit codes, task labels, changed paths, and redacted diffs are stored under the ignored `tools/agent-monitor/.state/agent-city/`. User prompts, raw JSONL, command arguments, full tool output, and credentials are not stored or shown. Changed files stay in their isolated worktree for review; the monitor does not apply them to the main worktree or remove worktrees automatically. The isolated baseline is a local commit and no GitHub request, commit, push, database connection, or Docker container is started by this adapter.
- **ICM / Graphify / GTX / RTK:** ICM tools are available in this Codex environment for memory/transcript operations but do not expose a live agent event feed here; this dashboard does not send data to ICM. Graphify Local is installed and used for the project graph; `docs/AGENT_TEAM.md` links the local report from this Obsidian vault. No `gtx` command/integration was found. RTK is installed and its project and global Codex hook entries are registered; restart Codex and trust the project hook if prompted. `rtk gain` still reported no active hook during verification, so automatic interception remains unverified.
- **Codex app-server:** `codex app-server` is available but experimental. It is a client protocol for applications that start or resume app-server threads; this dashboard does not start an app-server, connect to one, or attach it to an existing desktop session. See the [official app-server documentation](https://developers.openai.com/codex/app-server).

## Record named-agent work

```powershell
$runId = py -3 tools/agent-monitor/agent_events.py start --agent agent-3 --task "Run the relevant app tests"
py -3 tools/agent-monitor/agent_events.py verify --agent agent-3 --run-id $runId --check "Flutter tests" --passed 10 --failed 0
py -3 tools/agent-monitor/agent_events.py finish --agent agent-3 --run-id $runId --status completed
```

Use actual observed results and parent-verified file paths. Never record prompts, customer data, secrets, tool arguments, full command text, or output. The named-role ledger CLI remains separate from Agent City worker records. Agent City has same-origin, confirmation-gated POST routes for isolated Codex task start and cancellation; existing session, Git, note, and image routes remain read-only. Run metadata is ignored by Git in `tools/agent-monitor/.state/`.

## Verify

```powershell
python -m unittest discover -s tools/agent-monitor -p "test_*.py" -v
python -m py_compile tools/agent-monitor/server.py tools/agent-monitor/agent_events.py tools/agent-monitor/test_server.py tools/agent-monitor/test_agent_events.py
```

Do not expose the local port to a network interface or reverse proxy. Worker processes can write only through the Codex workspace sandbox inside a managed worktree. Task prompts are sent to the authenticated local Codex CLI and can be subject to that account's service usage; do not enter secrets or customer data.
