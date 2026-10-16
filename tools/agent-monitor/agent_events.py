#!/usr/bin/env python3
"""Append safe, explicit metadata about assigned agent runs for the local monitor."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import uuid
from collections import defaultdict
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parent
REGISTRY_PATH = ROOT / "agents.json"
EVENTS_PATH = ROOT / ".state" / "agent-events.jsonl"
MAX_LOG_BYTES = 5 * 1024 * 1024
MAX_EVENTS = 10_000
SAFE_LABEL = re.compile(r"[^\w .,:/#()'&+-]+", re.UNICODE)
EMAIL = re.compile(r"\b[^\s@]+@[^\s@]+\.[^\s@]+\b")
PHONE_LIKE = re.compile(r"(?<!\w)\+?\d(?:[\s().-]*\d){8,}(?!\w)")
SENSITIVE_ASSIGNMENT = re.compile(
    r"(?i)\b(?:password|passwd|secret|token|api[_-]?key|private[_-]?key|authorization)\b\s*[:=]"
)
BEARER = re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._~+/-]+=*")
TOKEN_LIKE = re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,})\b")
AGENT_ID = re.compile(r"^agent-[1-9][0-9]*$")


def _label(value: object, field: str, maximum: int = 100) -> str:
    if not isinstance(value, str):
        raise ValueError(f"{field} must be text")
    if EMAIL.search(value) or PHONE_LIKE.search(value) or SENSITIVE_ASSIGNMENT.search(value) or BEARER.search(value) or TOKEN_LIKE.search(value):
        raise ValueError(f"{field} must not contain contact details, secrets, or tokens")
    result = SAFE_LABEL.sub("", value).strip()[:maximum]
    if not result:
        raise ValueError(f"{field} is required")
    return result


def _timestamp() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def load_agents(path: Path = REGISTRY_PATH) -> list[dict]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list) or not raw:
        raise ValueError("Agent registry must be a non-empty JSON list.")
    agents = []
    seen = set()
    for item in raw:
        if not isinstance(item, dict):
            raise ValueError("Agent registry entry is invalid.")
        agent_id = item.get("agent_id")
        if not isinstance(agent_id, str) or not AGENT_ID.fullmatch(agent_id) or agent_id in seen:
            raise ValueError("Agent registry contains an invalid or duplicate ID.")
        seen.add(agent_id)
        agents.append({
            "agent_id": agent_id,
            "name": _label(item.get("name"), "agent name", 40),
            "role": _label(item.get("role"), "agent role", 80),
        })
    return agents


def _valid_files(values: list[str]) -> list[str]:
    paths = []
    for raw in values:
        value = _label(raw, "file path", 180).replace("\\", "/")
        path = PurePosixPath(value)
        if path.is_absolute() or not path.parts or ".." in path.parts or ":" in path.parts[0]:
            raise ValueError("File paths must be relative to the project and cannot traverse parent folders.")
        if value not in paths:
            paths.append(value)
    return paths[:100]


def append_event(event: dict, path: Path = EVENTS_PATH) -> None:
    encoded = (json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
    path.parent.mkdir(parents=True, exist_ok=True)
    current = path.stat().st_size if path.exists() else 0
    if current + len(encoded) > MAX_LOG_BYTES:
        raise ValueError("Agent history reached the 5 MB safety limit; archive it before recording more runs.")
    with path.open("ab") as stream:
        stream.write(encoded)


def read_events(path: Path = EVENTS_PATH) -> list[dict]:
    if not path.exists():
        return []
    if path.stat().st_size > MAX_LOG_BYTES:
        raise ValueError("Agent history exceeds its safety limit.")
    result = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines()[-MAX_EVENTS:]:
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if (
            isinstance(item, dict)
            and isinstance(item.get("agent_id"), str)
            and isinstance(item.get("run_id"), str)
            and isinstance(item.get("event"), str)
            and isinstance(item.get("timestamp"), str)
        ):
            result.append(item)
    return result


def _seconds_between(start: str, end: str) -> int | None:
    try:
        begin = dt.datetime.fromisoformat(start.replace("Z", "+00:00"))
        finish = dt.datetime.fromisoformat(end.replace("Z", "+00:00"))
        return max(0, int((finish - begin).total_seconds()))
    except (TypeError, ValueError):
        return None


def build_overview(agents: list[dict], events: list[dict]) -> dict:
    agent_map = {item["agent_id"]: item for item in agents}
    grouped: dict[str, list[dict]] = defaultdict(list)
    for event in events:
        if event.get("agent_id") in agent_map:
            grouped[event["run_id"]].append(event)

    runs = []
    for run_id, entries in grouped.items():
        entries.sort(key=lambda item: item.get("timestamp", ""))
        first = entries[0]
        agent = agent_map[first["agent_id"]]
        started = next((item for item in entries if item.get("event") == "started"), None)
        if started is None:
            continue
        try:
            task_label = _label(started.get("task"), "task label")
        except ValueError:
            continue
        terminal = next((item for item in reversed(entries) if item.get("event") == "finished"), None)
        blocker_events = [item for item in entries if item.get("event") == "blocked"]
        verification = [item for item in entries if item.get("event") == "verification"]
        files = []
        for item in entries:
            if item.get("event") == "finished" and isinstance(item.get("files"), list):
                for file in item["files"]:
                    if isinstance(file, str):
                        try:
                            safe_file = _valid_files([file])
                            files.extend(safe_file)
                        except ValueError:
                            continue
        files = list(dict.fromkeys(files))[:100]
        if terminal:
            terminal_status = terminal.get("status")
            status = terminal_status if isinstance(terminal_status, str) and terminal_status in {"completed", "failed", "blocked"} else "unknown"
        else:
            status = "blocked" if blocker_events else "active"
        finished_at = terminal.get("timestamp", "") if terminal else ""
        duration = _seconds_between(started.get("timestamp", ""), finished_at) if finished_at else None
        checks = []
        for item in verification:
            passed = item.get("passed", 0)
            failed = item.get("failed", 0)
            if isinstance(passed, int) and isinstance(failed, int) and passed >= 0 and failed >= 0:
                checks.append({"label": _safe_event_label(item.get("label", "Check")), "passed": passed, "failed": failed})
        runs.append({
            "run_id": run_id[:8],
            "agent_id": agent["agent_id"],
            "name": agent["name"],
            "role": agent["role"],
            "task": task_label,
            "status": status if status in {"active", "blocked", "completed", "failed", "unknown"} else "active",
            "started_at": started.get("timestamp", ""),
            "finished_at": finished_at,
            "duration_seconds": duration,
            "blocker_count": len(blocker_events),
            "checks": checks,
            "files": files,
            "events": [{
                "timestamp": item.get("timestamp", ""),
                "event": item.get("event") if item.get("event") in {"started", "blocked", "verification", "finished"} else "event",
                "label": (
                    _safe_event_label(item.get("label"))
                    if item.get("label")
                    else ""
                ),
                "status": item.get("status") if isinstance(item.get("status"), str) and item.get("status") in {"completed", "failed", "blocked"} else "",
            } for item in entries[-40:]],
        })
    runs.sort(key=lambda item: item["started_at"], reverse=True)

    role_summaries = []
    for agent in agents:
        own = [item for item in runs if item["agent_id"] == agent["agent_id"]]
        completed = [item for item in own if item["status"] == "completed"]
        durations = [item["duration_seconds"] for item in completed if isinstance(item["duration_seconds"], int)]
        passed = sum(check["passed"] for run in own for check in run["checks"])
        failed = sum(check["failed"] for run in own for check in run["checks"])
        role_summaries.append({
            **agent,
            "metrics": {
                "recorded_runs": len(own),
                "active": sum(item["status"] == "active" for item in own),
                "blocked": sum(item["status"] == "blocked" for item in own),
                "completed": len(completed),
                "failed": sum(item["status"] == "failed" for item in own),
                "completion_rate_percent": round(len(completed) * 100 / len(own)) if own else None,
                "average_completion_seconds": round(sum(durations) / len(durations)) if durations else None,
                "verification_passed": passed,
                "verification_failed": failed,
                "reported_changed_files": len({file for run in own for file in run["files"]}),
            },
        })
    return {
        "source": "Local agent event log; records are written explicitly by the workflow.",
        "available": bool(runs),
        "roles": role_summaries,
        "runs": runs[:50],
        "event_count": len(events),
    }


def _safe_event_label(value: object) -> str:
    try:
        return _label(value, "event label")
    except ValueError:
        return "[withheld]"


def agent_overview(registry_path: Path = REGISTRY_PATH, events_path: Path = EVENTS_PATH) -> dict:
    try:
        return build_overview(load_agents(registry_path), read_events(events_path))
    except (OSError, ValueError, json.JSONDecodeError):
        return {
            "available": False,
            "source": "Local agent event log.",
            "error": "The local agent log could not be read safely.",
            "roles": [],
            "runs": [],
            "event_count": 0,
        }


def _find_run(agent_id: str, run_id: str, path: Path) -> dict:
    matches = [item for item in read_events(path) if item.get("run_id") == run_id]
    started = next((item for item in matches if item.get("event") == "started"), None)
    if started is None or started.get("agent_id") != agent_id:
        raise ValueError("Run ID was not found for that agent.")
    if any(item.get("event") == "finished" for item in matches):
        raise ValueError("This run is already finished.")
    return started


def main(argv: list[str] | None = None) -> int:
    agents = load_agents()
    by_id = {item["agent_id"]: item for item in agents}
    parser = argparse.ArgumentParser(description="Record safe metadata for a local agent task.")
    commands = parser.add_subparsers(dest="command", required=True)

    start = commands.add_parser("start", help="Record an agent task assignment/start.")
    start.add_argument("--agent", required=True, choices=sorted(by_id))
    start.add_argument("--task", required=True, help="Short task label only; never enter prompts or private data.")

    finish = commands.add_parser("finish", help="Record a verified terminal task status.")
    finish.add_argument("--agent", required=True, choices=sorted(by_id))
    finish.add_argument("--run-id", required=True)
    finish.add_argument("--status", required=True, choices=("completed", "failed", "blocked"))
    finish.add_argument("--file", action="append", default=[], help="Project-relative changed file; may be repeated.")

    blocker = commands.add_parser("blocker", help="Record a short blocker label.")
    blocker.add_argument("--agent", required=True, choices=sorted(by_id))
    blocker.add_argument("--run-id", required=True)
    blocker.add_argument("--label", required=True)

    verify = commands.add_parser("verify", help="Record actual test/check counts.")
    verify.add_argument("--agent", required=True, choices=sorted(by_id))
    verify.add_argument("--run-id", required=True)
    verify.add_argument("--check", required=True, help="Short check name, not command output.")
    verify.add_argument("--passed", type=int, required=True)
    verify.add_argument("--failed", type=int, required=True)

    args = parser.parse_args(argv)
    if args.command == "start":
        event = {
            "timestamp": _timestamp(), "event": "started", "run_id": str(uuid.uuid4()),
            "agent_id": args.agent, "task": _label(args.task, "task label"),
        }
        append_event(event)
        print(event["run_id"])
        return 0

    _find_run(args.agent, args.run_id, EVENTS_PATH)
    if args.command == "finish":
        event = {
            "timestamp": _timestamp(), "event": "finished", "run_id": args.run_id,
            "agent_id": args.agent, "status": args.status, "files": _valid_files(args.file),
        }
    elif args.command == "blocker":
        event = {
            "timestamp": _timestamp(), "event": "blocked", "run_id": args.run_id,
            "agent_id": args.agent, "label": _label(args.label, "blocker label"),
        }
    else:
        if args.passed < 0 or args.failed < 0:
            parser.error("Verification counts cannot be negative.")
        event = {
            "timestamp": _timestamp(), "event": "verification", "run_id": args.run_id,
            "agent_id": args.agent, "label": _label(args.check, "check label"),
            "passed": args.passed, "failed": args.failed,
        }
    append_event(event)
    print("Recorded.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"Agent event not recorded: {exc}", file=sys.stderr)
        raise SystemExit(2)
