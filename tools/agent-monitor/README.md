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

Open `http://127.0.0.1:8765`. Press `Ctrl+C` in the terminal to stop it. The server binds only to loopback, uses Python's standard library, has GET-only endpoints, and makes no external network requests.

## Data sources and limits

- **Codex activity:** reads up to the eight newest local `~/.codex/sessions/**/*.jsonl` files modified in the last 90 days and no larger than 150 MB each (or `%CODEX_HOME%\sessions` when that variable is set). The current Windows environment has local records containing session metadata, task start/completion markers, tool names, shell exit codes, file-change markers, and Codex usage records. Appended records are read incrementally. The file format is an observed local record format, not a public live-session API. The UI labels it accordingly and refreshes every five seconds. Other Codex installations may not write these records.
- **Named agent roles:** `agents.json` lists the role names: Agent 1 Frontend Developer, Agent 2 Backend/API Developer, Agent 3 QA Tester, and Agent 4 Code Reviewer. The separate `.state/agent-events.jsonl` ledger contains only explicit task labels, timestamps, terminal statuses, entered verification counts, blocker labels, and project-relative paths related to the task. Start it before assigning a role task, enter checks only after observing their real output, and finish it after reviewing the agent's result. The dashboard computes descriptive counts and elapsed wall time from those records; it does not measure code quality or infer missing events. Listed paths are task-related files verified by the parent, not proof of which person or agent authored them.
- **Privacy:** prompts, message bodies, tool arguments, command strings, tool output, MCP arguments/results, and full session IDs are not returned to the browser. Shell command activity shows only a timestamp and exit code. MCP activity shows the tool name and recorded status. The role ledger rejects common email, phone-like, secret, bearer-token, and API-key patterns, but it is not a complete personal-data detector; never record customer details. This does not provide a reliable semantic task title or detect a human pause; open task markers are reported from the log as observed.
- **Usage:** token figures are displayed only from a Codex `thread_token_usage` record. The monitor does not estimate usage or sum repeated cumulative records.
- **Git:** status and diffs are read from this local worktree. Diff preview redacts common secret assignments; content for `.obsidian`, `graphify-out`, and secret paths is hidden. Ahead/behind values use cached remote-tracking refs. The monitor never fetches, stages, commits, pushes, or contacts GitHub.
- **Project files:** note previews are limited to `docs/AGENT_TEAM.md`, `docs/AGENT_MONITOR.md`, `docs/NEXT_SESSION.md`, `docs/KNOWN_ISSUES.md`, `docs/TESTING.md`, and `docs/INTEGRATION_MAP.md`. Image previews come only from existing files under `assets/`, `lib/assets/`, `web/assets/`, or `docs/assets/`, with a 20 MB per-file limit. Paths are resolved and checked to stay within this repository. You may also choose a local image or Markdown attachment in the browser; that preview uses the browser's local file handle and sends no file data to the server.
- **ICM / Graphify / GTX / RTK:** ICM tools are available in this Codex environment for memory/transcript operations but do not expose a live agent event feed here; this dashboard does not send data to ICM. Graphify Local is installed and used for the project graph; `docs/AGENT_TEAM.md` links the local report from this Obsidian vault. No `gtx` command/integration was found. RTK is installed and its project and global Codex hook entries are registered; restart Codex and trust the project hook if prompted. `rtk gain` still reported no active hook during verification, so automatic interception remains unverified.

## Record named-agent work

```powershell
$runId = py -3 tools/agent-monitor/agent_events.py start --agent agent-3 --task "Run the relevant app tests"
py -3 tools/agent-monitor/agent_events.py verify --agent agent-3 --run-id $runId --check "Flutter tests" --passed 10 --failed 0
py -3 tools/agent-monitor/agent_events.py finish --agent agent-3 --run-id $runId --status completed
```

Use actual observed results and parent-verified file paths. Never record prompts, customer data, secrets, tool arguments, full command text, or output. The dashboard stays GET-only; this CLI is the only writer. Run metadata is ignored by Git in `tools/agent-monitor/.state/`.

## Verify

```powershell
python -m unittest discover -s tools/agent-monitor -p "test_*.py" -v
python -m py_compile tools/agent-monitor/server.py tools/agent-monitor/agent_events.py tools/agent-monitor/test_server.py tools/agent-monitor/test_agent_events.py
```

The dashboard is intentionally read-only. Do not expose the local port to a network interface or reverse proxy.
