# BurgerBites Agent Team and Tool Connections

[[NEXT_SESSION]] · [[AGENT_MONITOR]] · [[INTEGRATION_MAP]]

## Agent roles

| ID | Role | Status |
| --- | --- | --- |
| Agent 1 | Frontend Developer | Assigned |
| Agent 2 | Backend/API Developer | Assigned |
| Agent 3 | QA Tester | Assigned |
| Agent 4 | Code Reviewer | Assigned |
| Agent 5 | Customer/Admin Debugger | Assigned |

The role registry is `tools/agent-monitor/agents.json`. Agent 1, Agent 3, and Agent 5 can run through the monitor's isolated Codex worker adapter; Agent 5 focuses on customer/admin sign-in and account creation. Agent 5 cannot read a live browser console automatically, so include redacted console/API errors in the task when available. Agent 2 and Agent 4 remain explicit-log roles. The local monitor does not guess that an anonymous Codex session belongs to a role.

## Agent task records and performance

The separate local dashboard at `http://127.0.0.1:8765` has an Agents tab. Its input is the append-only `tools/agent-monitor/.state/agent-events.jsonl` ledger, written by the small CLI. The dashboard is still GET-only and read-only. The ledger is ignored by Git and stays on this computer.

Start a run in PowerShell and keep its returned ID:

```powershell
$runId = py -3 tools/agent-monitor/agent_events.py start --agent agent-1 --task "Review menu screen spacing"
```

After an actual check, record the result; when the task ends, record the outcome and parent-verified project-relative paths:

```powershell
py -3 tools/agent-monitor/agent_events.py verify --agent agent-1 --run-id $runId --check "Flutter widget tests" --passed 10 --failed 0
py -3 tools/agent-monitor/agent_events.py finish --agent agent-1 --run-id $runId --status completed --file lib/screens/customer/menu_screen.dart
```

Supported terminal statuses are `completed`, `failed`, and `blocked`. A blocker can be recorded while work is open with `blocker --agent agent-1 --run-id $runId --label "Waiting for API schema"`.

The dashboard reports recorded run counts, current/blocked/completed/failed tasks, completion percentage, elapsed time between recorded start and finish, entered verification counts, blocker records, and changed paths. These are not an automated quality score. They only cover runs that were logged; elapsed time includes gaps between events. Verification counts and paths must be based on actual results reviewed by the parent agent. Per-agent token figures are not shown because the available usage record cannot be reliably allocated to a role.

Never pass prompts, raw tool output, command text, customer information, secrets, or private attachments into the event logger. The logger rejects common email, phone-like, secret, bearer-token, and API-key patterns, but it is not a complete personal-data detector. Use short task and check labels only.

## Obsidian, Graphify, ICM, and RTK

- Open the BurgerBites project root as the Obsidian vault. This Markdown note and the other `docs/` notes are the durable project memory; the dashboard reads selected notes but does not edit or mirror the vault.
- Graphify Local is the code-structure graph, not an agent activity source or an Obsidian plugin. Its local generated report is [Graphify's code report](../graphify-out/GRAPH_REPORT.md), and the local graph view is [Graphify's HTML graph](../graphify-out/graph.html). Use `graphify query "<code question>"` for focused code navigation and `graphify update .` after code changes. The generated folder is ignored by Git and stays local.
- ICM is connected to this Codex environment for memory and transcript tools. It stores durable decisions and resume context; it does not feed live task events to the dashboard. Keep credentials and customer data out of ICM.
- RTK 1.0.0 is a local command-output filter. Project and global Codex hook entries are registered, but `rtk gain` still reports no active hook in this session. Restart Codex and trust the project hook if prompted, then verify activation. `rtk gain` describes command-output reduction, not agent quality or task success. Use direct command output when full diagnostics matter.

## Current connection limits

- The monitor refreshes local Codex JSONL session history and the explicit role ledger. Neither is an official live-session API. The role ledger requires the workflow above. The task history displays recorded run events, verification labels, blocker labels, and parent-verified task-related paths; the path list does not prove authorship.
- On Windows, the Overview card takes a point-in-time Toolhelp process snapshot and lists executable basenames matching `codex.exe` or `codex`, plus PIDs, parent PIDs, and start times when available. This verifies only a process-name match; it does not inspect the executable path/signature or connect a process to a project, JSONL session, or role. The native path was smoke-tested on this Windows machine.
- The official [Codex app-server](https://developers.openai.com/codex/app-server) is experimental and designed for clients that start or resume app-server threads. The dashboard does not start one or attach to an existing Codex Desktop session. Official [Codex hook documentation](https://developers.openai.com/codex/hooks) requires non-managed hooks to be reviewed and trusted; no new hooks were configured or trusted for this dashboard.
- Graphify, ICM, and RTK run locally. No hosted Graphify account or repository upload is configured. RTK and ICM do not send agent performance records to Obsidian or the dashboard.
- Read `[[AGENT_MONITOR]]` for the privacy boundaries and server setup.
