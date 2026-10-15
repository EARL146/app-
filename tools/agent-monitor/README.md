# BurgerBites Agent Monitor

This is a separate, local-only dashboard for observable development activity. Obsidian remains the project memory system. The dashboard previews a small allowlist of notes and existing images; it does not mirror the vault, rewrite notes, or modify the BurgerBites app/API/database.

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
- **Privacy:** prompts, message bodies, tool arguments, command strings, tool output, MCP arguments/results, and full session IDs are not returned to the browser. Shell command activity shows only a timestamp and exit code. MCP activity shows the tool name and recorded status. This does not provide a reliable semantic task title or detect a human pause; open task markers are reported from the log as observed.
- **Usage:** token figures are displayed only from a Codex `thread_token_usage` record. The monitor does not estimate usage or sum repeated cumulative records.
- **Git:** status and diffs are read from this local worktree. Diff preview redacts common secret assignments; content for `.obsidian`, `graphify-out`, and secret paths is hidden. Ahead/behind values use cached remote-tracking refs. The monitor never fetches, stages, commits, pushes, or contacts GitHub.
- **Project files:** note previews are limited to `docs/NEXT_SESSION.md`, `docs/KNOWN_ISSUES.md`, `docs/TESTING.md`, and `docs/INTEGRATION_MAP.md`. Image previews come only from existing files under `assets/`, `lib/assets/`, `web/assets/`, or `docs/assets/`, with a 20 MB per-file limit. Paths are resolved and checked to stay within this repository. You may also choose a local image or Markdown attachment in the browser; that preview uses the browser's local file handle and sends no file data to the server.
- **ICM / Graphify / GTX / RTK:** ICM tools are available in this Codex environment for memory/transcript operations but do not expose a live agent event feed here; this dashboard does not send data to ICM. Graphify Local is installed and used for the project graph. No `gtx` command/integration was found. RTK is installed and its PowerShell command works, but `rtk git status` reported that no hook is installed, so automatic Codex interception is not claimed.

## Verify

```powershell
python -m unittest discover -s tools/agent-monitor -p "test_*.py" -v
python -m py_compile tools/agent-monitor/server.py tools/agent-monitor/test_server.py
```

The dashboard is intentionally read-only. Do not expose the local port to a network interface or reverse proxy.
