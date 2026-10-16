# Burger_bites repository guidance

## Task workflow and safeguards

- Before changing code, inspect the repository status and the relevant project instructions, notes, and source files. Use the project graph for code navigation when its instructions apply; do not begin edits from assumptions alone.
- For major implementation tasks, create a local checkpoint commit of the approved baseline before making task changes. Review the status and diff first, stage only the intended files, and keep unrelated or pre-existing user changes out of the commit. If the working tree cannot be separated safely, ask before committing. A checkpoint does not authorize pushing.
- Delegate independent work to available agents when it will help. Assign disjoint files or clearly separated tasks, and do not let multiple agents edit the same files concurrently. Coordinate and review delegated changes before integrating them.
- Verify every change with relevant existing checks, inspect the final diff, and report the commands and actual results. Do not claim unrun checks passed.

## Project and reference notes

- This is an existing Flutter/Dart app with a PHP/PDO API and local MySQL database. Preserve the current architecture and inspect the relevant source before changing it.
- Read `docs/NEXT_SESSION.md` for current state, then only the topic note needed for the task. Do not re-read all project docs for a small change.
- `docs/SCREEN_FLOW.md` and the supplied screenshots are the UI reference. The Figma file has not been verified.
- Open the project root as the Obsidian vault; project knowledge is under `docs/`.

## Change and verification rules

- Check `git status --short --branch` before editing. Preserve existing user changes; do not reset, clean, overwrite, or stage unrelated files.
- Use the checkpoint rule above for major tasks. Do not push unless the user explicitly asks. Review `git diff` and `git diff --cached` before any backup operation.
- Keep secrets out of source and notes. Do not print `backend/.env`; use `git check-ignore` and inspect only whether the file is ignored.
- Use targeted checks for changed code. Do not launch a full Flutter build or emulator unless the task needs it. Report actual commands and results.
- For substantial work, update `docs/NEXT_SESSION.md` with state, files, verification, blockers, and one next task.

## Optional tools

- RTK 1.0.0 is installed in the user's local tools folder. Project and global RTK Codex hook entries are registered; restart Codex and trust the project hook if prompted. `rtk gain` still reports that no hook is active in the current session, so do not claim automatic interception until verified. The executable is `C:\Users\shizu\.local\bin\rtk.exe`. Review full output directly when an RTK summary is incomplete.
- ICM 0.11.4 is configured as a local Codex MCP server. Its MCP handshake works, but per-project initialization reported a Windows manifest-write error; do not claim per-project memory is ready unless that is repaired and verified. Keep ICM memory free of credentials and personal data.
- Graphify means the local `graphifyy` package selected by the user. Keep code indexing local, use its Codex project skill, and leave `graphify-out/` ignored. Do not sign into a hosted service or upload source unless the user separately asks.

## Agent activity logging

- When using a named Codex subagent for BurgerBites, start a local record with `py -3 tools/agent-monitor/agent_events.py start --agent agent-N --task "short label"`. Record actual checks with `verify`, then record the verified outcome and changed paths with `finish`.
- Record only a short task label, check label, counts, status, and project-relative file paths. Never pass prompts, customer data, secrets, full command output, or tool arguments to the logger.
- The monitor's agent metrics are only as complete as these explicit records. Do not infer a role from anonymous Codex session IDs. Agent 2 is Backend/API Developer, as assigned by the user.

@RTK.md

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
