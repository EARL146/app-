"""Isolated, single-worker Codex CLI runner for the local Agent Monitor.

The browser never chooses a command or filesystem path. It submits a task label
and prompt; this module starts Codex with fixed sandbox/approval flags in a
Git worktree created from the current committed HEAD. Prompts and raw CLI output
are never persisted or returned to the browser.
"""
from __future__ import annotations

import datetime as dt
import difflib
import json
import os
import queue
import re
import shutil
import subprocess
import threading
import time
import uuid
from pathlib import Path


MAX_TASK_PROMPT = 12_000
MAX_TASKS = 50
MAX_EVENTS = 120
MAX_TASK_DURATION_SECONDS = 60 * 60
ALLOWED_WORKERS = {
    "agent-1": "Frontend Developer",
    "agent-3": "QA Tester",
    "agent-5": "Customer/Admin Debugger",
    "agent-6": "Security Engineer",
}
WORKER_STATIONS = {
    "agent-1": "UI Studio Desk",
    "agent-3": "Verification Lab",
    "agent-5": "Auth Diagnostics Bay",
    "agent-6": "Cyber Shield Vault",
}
ACTIVE_STATES = {"queued", "preparing", "running"}
TERMINAL_STATES = {"completed", "failed", "cancelled", "blocked", "timed_out", "interrupted"}
SECRET_ASSIGNMENT = re.compile(
    r"(?i)(\b(?:password|passwd|secret|token|api[_-]?key|private[_-]?key|"
    r"client[_-]?secret|authorization|credential|database[_-]?url)\b\s*[:=]\s*)([^\r\n,;]+)"
)
BEARER = re.compile(r"(?i)\b(bearer\s+)[A-Za-z0-9._~+/-]+=*")
TOKEN_LIKE = re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,})\b")
USER_PATH = re.compile(r"(?i)\b[A-Z]:\\Users\\[^\\\s]+")
EMAIL = re.compile(r"\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b")


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def _safe_text(value: object, limit: int = 240) -> str:
    text = str(value or "").replace("\x00", " ").replace("\r", " ").replace("\n", " ")
    text = SECRET_ASSIGNMENT.sub(r"\1[redacted]", text)
    text = BEARER.sub(r"\1[redacted]", text)
    text = TOKEN_LIKE.sub("[redacted-token]", text)
    text = EMAIL.sub("[redacted-email]", text)
    text = USER_PATH.sub("<user-path>", text)
    text = "".join(ch for ch in text if ch.isprintable())
    return text[:limit].strip()


def _safe_label(value: object) -> str:
    label = _safe_text(value, 100)
    return label or "Untitled task"


def _select_model(rows: object, configured: str = "") -> str:
    if not isinstance(rows, list):
        return ""
    usable = [
        row.get("slug") for row in rows
        if isinstance(row, dict)
        and row.get("visibility") == "list"
        and row.get("supported_in_api") is not False
        and isinstance(row.get("slug"), str)
        and re.fullmatch(r"[A-Za-z0-9._-]{1,80}", row["slug"])
    ]
    if configured in usable:
        return configured
    return usable[0] if usable else ""


def _error_detail(event: dict) -> str:
    value = event.get("error")
    if isinstance(value, dict):
        value = value.get("message")
    if not isinstance(value, str) or not value:
        value = event.get("message")
    if isinstance(value, str) and value.startswith("{"):
        try:
            nested = json.loads(value)
            if isinstance(nested, dict):
                error = nested.get("error")
                if isinstance(error, dict) and isinstance(error.get("message"), str):
                    value = error["message"]
                elif isinstance(nested.get("message"), str):
                    value = nested["message"]
        except json.JSONDecodeError:
            pass
    return _safe_text(value, 300) if isinstance(value, str) else ""


def _qa_result(exit_code: int | None, command_count: int, failed_commands: int) -> tuple[str, str]:
    if exit_code != 0:
        return "failed", f"QA Codex process exited with code {exit_code}."
    if command_count == 0:
        return "failed", "QA worker completed without running a recorded check command."
    if failed_commands:
        return "failed", f"{failed_commands} of {command_count} recorded QA check commands returned nonzero exit codes."
    return "completed", ""


def _configured_model() -> str:
    codex_home = Path(os.environ.get("CODEX_HOME") or (Path.home() / ".codex")).expanduser()
    config_path = codex_home / "config.toml"
    try:
        for line in config_path.read_text(encoding="utf-8", errors="replace").splitlines():
            match = re.match(r'^\s*model\s*=\s*["\']([^"\']+)["\']\s*(?:#.*)?$', line)
            if match:
                return match.group(1)
    except OSError:
        pass
    return ""


def _event_summary(event: object) -> tuple[dict | None, bool]:
    """Return a small allowlisted event record and whether approval was requested."""
    if not isinstance(event, dict):
        return None, False
    event_type = str(event.get("type") or "").lower().replace("_", ".")
    item = event.get("item") if isinstance(event.get("item"), dict) else {}
    item_type = str(item.get("type") or "").lower().replace("_", ".")
    status = str(item.get("status") or "").lower()
    if "approval" in event_type or "approval" in item_type or status in {"approval_required", "requires_approval"}:
        return {"timestamp": _now(), "category": "approval", "label": "Codex requested an approval; the monitor will not auto-approve it."}, True

    summary: dict | None = None
    if event_type in {"thread.started", "thread.started"}:
        thread_id = event.get("thread_id")
        prefix = str(thread_id)[:8] if isinstance(thread_id, str) else ""
        summary = {"category": "lifecycle", "label": "Codex worker started"}
        if prefix:
            summary["thread_id_prefix"] = prefix
    elif event_type == "turn.started":
        summary = {"category": "lifecycle", "label": "Codex turn started"}
    elif event_type in {"turn.completed", "turn.failed", "turn.cancelled"}:
        labels = {"turn.completed": "Codex turn completed", "turn.failed": "Codex turn failed", "turn.cancelled": "Codex turn cancelled"}
        summary = {"category": "error" if event_type == "turn.failed" else "lifecycle", "label": labels[event_type]}
        if event_type == "turn.failed":
            detail = _error_detail(event)
            if detail:
                summary["label"] = "Codex error: " + detail
    elif event_type in {"item.started", "item.completed"}:
        is_done = event_type.endswith("completed")
        label = "Activity started" if not is_done else "Activity completed"
        if item_type in {"command.execution", "commandexecution"}:
            label = "Command started" if not is_done else "Command completed"
        elif item_type in {"file.change", "filechange", "patch.apply.begin", "patch.apply.end"}:
            label = "File operation started" if not is_done else "File operation completed"
        elif item_type in {"mcp.tool.call", "mcptoolcall"}:
            tool_name = item.get("tool_name") or item.get("name") or "tool"
            label = ("Tool started: " if not is_done else "Tool completed: ") + _safe_text(tool_name, 50)
        elif item_type:
            safe_type = re.sub(r"[^a-z0-9 ._-]", "", item_type)[:50]
            label = ("Started: " if not is_done else "Completed: ") + (safe_type or "activity")
        summary = {"category": "tool", "label": label}
        exit_code = item.get("exit_code")
        if isinstance(exit_code, int) and -255 <= exit_code <= 255:
            summary["exit_code"] = exit_code
        if status in {"completed", "failed", "in_progress"}:
            summary["status"] = status
    elif event_type in {"error", "codex.error", "turn.error"}:
        detail = _error_detail(event)
        summary = {"category": "error", "label": "Codex error: " + detail if detail else "Codex reported an error; sensitive details are withheld."}

    if summary is None:
        return None, False
    summary["timestamp"] = _now()
    return summary, False


def _worker_prompt(role: str, label: str, user_prompt: str | None = None) -> str:
    guardrails = (
        "Execution rules: you are inside a disposable, isolated Git worktree based on the committed project HEAD. "
        "Stay inside this worktree. Never read credentials, environment secrets, customer records, or files outside it. "
        "Do not use the network, install or update dependencies, modify Git metadata, commit, push, create branches, "
        "delete/reset files broadly, or change the main project worktree. If the task requires a restricted or elevated "
        "action, stop and explain what approval is needed. Do not claim work or tests that you did not perform."
    )
    if role == "agent-3":
        return (
            "You are Agent 3, the QA Tester. Inspect the actual changes and existing test/build instructions in this "
            "isolated worktree. Run the most relevant checks already supported by the repository, without installing "
            "dependencies or changing application source. If the repository has no runnable test suite or a check's "
            "prerequisite is missing, run `git diff --check` as a safe fallback and explicitly report that full tests "
            "were unavailable. Do not probe missing commands expecting failure. Report the actual checks and exit "
            "results; never call a failed command a pass. Do not modify source or tests.\n\n"
            f"Task being verified: {_safe_label(label)}\n\n{guardrails}"
        )
    if role == "agent-5":
        return (
            "You are Agent 5, the Customer/Admin Debugger. Investigate customer and admin sign-in and account-creation "
            "flows, and use any browser-console or API error text the user supplied as evidence. Inspect the relevant "
            "project instructions and existing code first. If no console output was supplied, you cannot see the user's "
            "browser DevTools; state that clearly and perform a code and existing-check investigation instead. Never "
            "claim to have scanned a live browser console, authenticated as a real user, or verified a production flow. "
            "Do not request or use real passwords, customer data, API keys, database credentials, or production access. "
            "Use existing safe tests or demo data only. Fix only bugs supported by the evidence, keep edits focused, and "
            "run relevant checks already available in the repository without installing dependencies. If the error needs "
            "credentials, a live service, a schema change, or an unavailable browser connection, report the blocker and "
            "leave that action for the user. Report the likely cause, exact files changed, checks actually run and their "
            "results, and any manual browser verification still needed. Do not commit or push.\n\n"
            f"Debug task: {_safe_label(label)}\n\nUser-provided issue details and optional redacted console output:\n"
            f"{user_prompt or ''}\n\n{guardrails}"
        )
    if role == "agent-6":
        return (
            "You are Agent 6, the Security Engineer (System-Wide Security Guardian) for BurgerBites. Your role is to "
            "audit and harden security across the entire BurgerBites system: Flutter client storage/auth/routing, "
            "PHP/PDO backend API endpoints, MySQL prepared statements and input validation, CORS/rate-limiting "
            "controls, Docker/Redis isolation, and local Agent Monitor privacy guards. Inspect the relevant project "
            "instructions and code first. Never read or print `.env` files, real passwords, customer PII, or production "
            "tokens. Fix only vulnerabilities or hardening gaps supported by the repository code, keep edits focused, "
            "and run relevant existing checks without installing dependencies. Report findings, exact files changed, "
            "and actual verification results. Do not commit or push.\n\n"
            f"Security task: {_safe_label(label)}\n\nSecurity audit or hardening instructions:\n"
            f"{user_prompt or ''}\n\n{guardrails}"
        )
    return (
        "You are Agent 1, the Frontend Developer. Implement only the user's task in this isolated worktree. Inspect "
        "the relevant project instructions and files first, keep the change focused, and run a relevant existing check "
        "if available. Do not commit or push. Report what changed and actual verification results.\n\n"
        f"Task label: {_safe_label(label)}\n\nUser instructions:\n{user_prompt or ''}\n\n{guardrails}"
    )


class WorkerManager:
    """A single concurrent Codex worker with persisted, sanitized task events."""

    def __init__(self, project_root: Path, state_root: Path, codex_executable: str | None = None):
        self.project_root = project_root.resolve()
        self.state_root = state_root.resolve()
        self.tasks_root = self.state_root / "tasks"
        self.worktrees_root = self.state_root / "worktrees"
        self.tasks_root.mkdir(parents=True, exist_ok=True)
        self.worktrees_root.mkdir(parents=True, exist_ok=True)
        self.codex_executable = codex_executable or shutil.which("codex")
        self._lock = threading.RLock()
        self._tasks: dict[str, dict] = {}
        self._processes: dict[str, subprocess.Popen] = {}
        self._cancelled: set[str] = set()
        self._approval_ids: set[str] = set()
        self._active_id: str | None = None
        self._status_cache: tuple[float, dict] | None = None
        self._load_tasks()

    def _task_dir(self, task_id: str) -> Path:
        if not re.fullmatch(r"[0-9a-f]{32}", task_id):
            raise ValueError("Invalid task id.")
        return self.tasks_root / task_id

    def _worktree_dir(self, task: dict) -> Path:
        key = task.get("worktree_key")
        if not isinstance(key, str) or not re.fullmatch(r"[0-9a-f]{32}", key):
            raise ValueError("Task worktree reference is invalid.")
        path = self.worktrees_root / key
        if not path.resolve().is_relative_to(self.worktrees_root.resolve()):
            raise ValueError("Task worktree is outside the managed area.")
        return path

    def _load_tasks(self) -> None:
        for path in self.tasks_root.glob("*/task.json"):
            try:
                task_id = path.parent.name
                if not re.fullmatch(r"[0-9a-f]{32}", task_id):
                    continue
                item = json.loads(path.read_text(encoding="utf-8"))
                if not isinstance(item, dict) or item.get("task_id") != task_id:
                    continue
                self._tasks[task_id] = item
                if item.get("status") in ACTIVE_STATES:
                    item["status"] = "interrupted"
                    item["finished_at"] = _now()
                    item["error"] = "The monitor restarted while this worker was active."
                    self._append_event_locked(task_id, "Worker interrupted because the monitor restarted.", "error")
                    self._write_task_locked(task_id)
            except (OSError, json.JSONDecodeError, ValueError):
                continue

    def _write_task_locked(self, task_id: str) -> None:
        directory = self._task_dir(task_id)
        directory.mkdir(parents=True, exist_ok=True)
        temporary = directory / "task.json.tmp"
        temporary.write_text(json.dumps(self._tasks[task_id], ensure_ascii=False), encoding="utf-8")
        os.replace(temporary, directory / "task.json")

    def _append_event_locked(self, task_id: str, label: str, category: str = "info", exit_code: int | None = None) -> None:
        event = {"timestamp": _now(), "category": category, "label": _safe_text(label)}
        if isinstance(exit_code, int) and -255 <= exit_code <= 255:
            event["exit_code"] = exit_code
        directory = self._task_dir(task_id)
        directory.mkdir(parents=True, exist_ok=True)
        with (directory / "events.jsonl").open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(event, ensure_ascii=False) + "\n")

    def _event(self, task_id: str, summary: dict) -> None:
        with self._lock:
            directory = self._task_dir(task_id)
            directory.mkdir(parents=True, exist_ok=True)
            with (directory / "events.jsonl").open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(summary, ensure_ascii=False) + "\n")

    def _set(self, task_id: str, **updates: object) -> None:
        with self._lock:
            self._tasks[task_id].update(updates)
            self._write_task_locked(task_id)

    def _check_cli(self, force: bool = False) -> dict:
        now = time.monotonic()
        if not force and self._status_cache and now - self._status_cache[0] < 30:
            return dict(self._status_cache[1])
        result = {
            "available": bool(self.codex_executable),
            "authenticated": False,
            "version": "",
            "model": "",
            "source": "Codex CLI local status command",
        }
        if self.codex_executable:
            safe_env = _worker_environment()
            try:
                version = subprocess.run(
                    [self.codex_executable, "--version"], capture_output=True, timeout=8,
                    check=False, env=safe_env, text=True,
                )
                result["version"] = _safe_text(version.stdout, 50) if version.returncode == 0 else ""
                login = subprocess.run(
                    [self.codex_executable, "login", "status"], capture_output=True, timeout=8,
                    check=False, env=safe_env, text=True,
                )
                login_text = (login.stdout + "\n" + login.stderr).lower()
                result["authenticated"] = login.returncode == 0 and "logged in" in login_text
                if result["authenticated"]:
                    catalog = subprocess.run(
                        [self.codex_executable, "debug", "models"], capture_output=True, timeout=12,
                        check=False, env=safe_env,
                    )
                    if catalog.returncode == 0:
                        try:
                            catalog_data = json.loads(catalog.stdout)
                            rows = catalog_data.get("models", []) if isinstance(catalog_data, dict) else []
                            configured = _configured_model()
                            result["model"] = _select_model(rows, configured)
                            result["model_source"] = (
                                "user-configured model" if result["model"] == configured and configured
                                else "catalog fallback; configured model unavailable" if configured and result["model"]
                                else "available Codex model catalog"
                            )
                        except (json.JSONDecodeError, TypeError, ValueError):
                            result["model"] = ""
            except (OSError, subprocess.TimeoutExpired):
                result["available"] = False
        self._status_cache = (now, result)
        return dict(result)

    def status(self) -> dict:
        cli = self._check_cli()
        with self._lock:
            active = self._public(self._tasks[self._active_id]) if self._active_id in self._tasks else None
            by_agent = {}
            for task in sorted(self._tasks.values(), key=lambda item: item.get("created_at", "")):
                by_agent[task.get("agent_id")] = self._public(task, include_events=False)
            return {"codex": cli, "active_task": active, "latest_by_agent": by_agent}

    def list_tasks(self) -> dict:
        self._check_cli()
        with self._lock:
            tasks = sorted(self._tasks.values(), key=lambda item: item.get("created_at", ""), reverse=True)[:MAX_TASKS]
            return {
                "codex": dict(self._status_cache[1]) if self._status_cache else {},
                "active_task": self._public(self._tasks[self._active_id]) if self._active_id in self._tasks else None,
                "tasks": [self._public(item) for item in tasks],
            }

    def _public(self, task: dict, include_events: bool = True) -> dict:
        result = {key: task.get(key) for key in (
            "task_id", "parent_task_id", "agent_id", "role", "label", "kind", "status",
            "created_at", "started_at", "finished_at", "baseline_commit", "exit_code",
            "changed_files", "error", "approval_required", "source",
        )}
        result["station"] = WORKER_STATIONS.get(str(task.get("agent_id") or ""), "Shared Office Desk")
        result["changed_files"] = task.get("changed_files", []) if isinstance(task.get("changed_files"), list) else []
        result["error"] = _safe_text(task.get("error"), 500) if task.get("error") else ""
        started_raw = task.get("started_at") or task.get("created_at") or ""
        finished_raw = task.get("finished_at") or ""
        if isinstance(started_raw, str) and isinstance(finished_raw, str) and started_raw and finished_raw:
            try:
                s_dt = dt.datetime.fromisoformat(started_raw.replace("Z", "+00:00"))
                f_dt = dt.datetime.fromisoformat(finished_raw.replace("Z", "+00:00"))
                result["duration_seconds"] = max(0, int((f_dt - s_dt).total_seconds()))
            except ValueError:
                result["duration_seconds"] = None
        else:
            result["duration_seconds"] = None
        try:
            result["worktree"] = self._worktree_dir(task).relative_to(self.project_root).as_posix()
        except (ValueError, OSError):
            result["worktree"] = ""
        if include_events:
            result["events"] = self._read_events(task["task_id"])
        return result

    def _read_events(self, task_id: str) -> list[dict]:
        path = self._task_dir(task_id) / "events.jsonl"
        try:
            with path.open("r", encoding="utf-8") as stream:
                rows = [json.loads(line) for line in stream if line.strip()]
        except (OSError, json.JSONDecodeError):
            return []
        return [row for row in rows[-MAX_EVENTS:] if isinstance(row, dict)]

    def _assert_available(self) -> None:
        status = self._check_cli()
        if not status["available"]:
            raise RuntimeError("Codex CLI is not available on PATH.")
        if not status["authenticated"]:
            raise RuntimeError("Codex CLI is not authenticated. Run `codex login` in PowerShell, then refresh this page.")
        if not status.get("model"):
            raise RuntimeError("Codex did not return a model supported by the current account.")
        with self._lock:
            if self._active_id:
                raise RuntimeError("A Codex worker is already active. Wait for it to finish or cancel it first.")

    def start_coding_task(self, agent_id: str, label: str, prompt: str) -> dict:
        if agent_id not in {"agent-1", "agent-5", "agent-6"}:
            raise ValueError("Only Agent 1, Agent 5, and Agent 6 can start coding, debugging, or security tasks.")
        if not isinstance(prompt, str):
            raise ValueError("Task instructions must be text.")
        prompt = prompt.strip()
        if not prompt or len(prompt) > MAX_TASK_PROMPT:
            raise ValueError(f"Task instructions must contain 1–{MAX_TASK_PROMPT} characters.")
        self._assert_available()
        kind = "security" if agent_id == "agent-6" else "debugging" if agent_id == "agent-5" else "coding"
        task = self._create_task(agent_id, _safe_label(label), kind, None, None)
        thread = threading.Thread(target=self._run, args=(task["task_id"], _worker_prompt(agent_id, task["label"], prompt)), daemon=True)
        thread.start()
        return self.get_task(task["task_id"])

    def start_qa_task(self, parent_task_id: str) -> dict:
        self._assert_available()
        parent = self.get_task(parent_task_id)
        if parent["agent_id"] != "agent-1" or parent["status"] != "completed":
            raise ValueError("Agent 3 can verify only a completed Agent 1 task.")
        parent_internal = self._tasks[parent_task_id]
        worktree = self._worktree_dir(parent_internal)
        if not worktree.is_dir():
            raise ValueError("The isolated worktree for this task is unavailable.")
        task = self._create_task("agent-3", _safe_label("Verify: " + parent["label"]), "testing", parent_task_id, parent_internal["worktree_key"])
        self._set(task["task_id"], baseline_commit=parent_internal.get("baseline_commit", ""))
        thread = threading.Thread(target=self._run, args=(task["task_id"], _worker_prompt("agent-3", parent["label"])), daemon=True)
        thread.start()
        return self.get_task(task["task_id"])

    def _create_task(self, agent_id: str, label: str, kind: str, parent_id: str | None, worktree_key: str | None) -> dict:
        task_id = uuid.uuid4().hex
        with self._lock:
            if self._active_id:
                raise RuntimeError("A Codex worker is already active. Wait for it to finish or cancel it first.")
            task = {
                "task_id": task_id,
                "parent_task_id": parent_id,
                "agent_id": agent_id,
                "role": ALLOWED_WORKERS[agent_id],
                "label": label,
                "kind": kind,
                "status": "preparing",
                "created_at": _now(),
                "started_at": "",
                "finished_at": "",
                "baseline_commit": "",
                "exit_code": None,
                "changed_files": [],
                "error": "",
                "approval_required": False,
                "source": "Codex CLI JSON event stream",
                "worktree_key": worktree_key or task_id,
            }
            self._tasks[task_id] = task
            self._active_id = task_id
            self._write_task_locked(task_id)
            self._append_event_locked(task_id, "Task accepted; preparing an isolated worktree.")
        return task

    def _create_worktree(self, task: dict) -> tuple[Path, str]:
        worktree = self._worktree_dir(task)
        if task["kind"] == "testing":
            return worktree, task.get("baseline_commit", "")
        if worktree.exists():
            raise RuntimeError("The isolated worktree path already exists.")
        commit = subprocess.run(
            ["git", "-C", str(self.project_root), "rev-parse", "--short", "HEAD"],
            capture_output=True, timeout=10, check=False,
        )
        if commit.returncode != 0:
            raise RuntimeError("Could not identify the committed project baseline.")
        baseline = commit.stdout.decode("utf-8", "replace").strip()
        result = subprocess.run(
            ["git", "-C", str(self.project_root), "worktree", "add", "--detach", "--quiet", str(worktree), "HEAD"],
            capture_output=True, timeout=60, check=False,
        )
        if result.returncode != 0:
            raise RuntimeError("Git could not create the isolated worker worktree.")
        return worktree, baseline

    def _run(self, task_id: str, prompt: str) -> None:
        process = None
        approval = False
        timed_out = False
        qa_command_count = 0
        qa_command_failures = 0
        try:
            with self._lock:
                task = dict(self._tasks[task_id])
            if self._is_cancelled(task_id):
                self._finish(task_id, "cancelled", None, "Cancelled before the worker started.")
                return
            worktree, baseline = self._create_worktree(task)
            self._set(task_id, baseline_commit=baseline)
            self._event(task_id, {"timestamp": _now(), "category": "lifecycle", "label": "Isolated Git worktree ready"})
            if self._is_cancelled(task_id):
                self._finish(task_id, "cancelled", None, "Cancelled before Codex started.")
                return

            executable = self.codex_executable
            if not executable:
                raise RuntimeError("Codex CLI is not available on PATH.")
            args = [
                executable, "--model", self._model_for(task_id), "--ask-for-approval", "on-request", "exec", "--json", "--ephemeral",
                "--sandbox", "workspace-write", "-",
            ]
            creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if os.name == "nt" else 0
            kwargs = {"creationflags": creationflags} if os.name == "nt" else {"start_new_session": True}
            process = subprocess.Popen(
                args, cwd=worktree, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                env=_worker_environment(), **kwargs,
            )
            with self._lock:
                self._processes[task_id] = process
                self._tasks[task_id]["started_at"] = _now()
                self._tasks[task_id]["status"] = "running"
                self._write_task_locked(task_id)
            self._event(task_id, {"timestamp": _now(), "category": "lifecycle", "label": "Codex CLI process started", "pid": process.pid})

            try:
                process.stdin.write(prompt.encode("utf-8"))
                process.stdin.close()
            except (BrokenPipeError, OSError):
                pass

            output_queue: queue.Queue[bytes | None] = queue.Queue()
            stderr_lines: list[str] = []
            stdout_thread = threading.Thread(target=_read_pipe, args=(process.stdout, output_queue), daemon=True)
            stderr_thread = threading.Thread(target=_collect_stderr, args=(process.stderr, stderr_lines, self, task_id), daemon=True)
            stdout_thread.start()
            stderr_thread.start()
            deadline = time.monotonic() + MAX_TASK_DURATION_SECONDS
            while time.monotonic() < deadline:
                if self._is_cancelled(task_id):
                    _terminate_process_tree(process)
                    break
                if self._approval_was_requested(task_id):
                    approval = True
                    self._set(task_id, approval_required=True, status="blocked", error="Codex requested a protected operation. It was not approved by the monitor.")
                    self._event(task_id, {"timestamp": _now(), "category": "approval", "label": "Worker stopped; the dashboard does not auto-approve protected actions."})
                    _terminate_process_tree(process)
                    break
                try:
                    line = output_queue.get(timeout=0.4)
                except queue.Empty:
                    if process.poll() is not None:
                        break
                    continue
                if line is None:
                    break
                try:
                    raw_event = json.loads(line.decode("utf-8", "replace"))
                except (json.JSONDecodeError, UnicodeDecodeError):
                    self._event(task_id, {"timestamp": _now(), "category": "diagnostic", "label": "Received a non-JSON Codex output line; contents withheld."})
                    continue
                if isinstance(raw_event, dict) and task.get("agent_id") == "agent-3" and str(raw_event.get("type", "")).lower() == "item.completed":
                    qa_item = raw_event.get("item") if isinstance(raw_event.get("item"), dict) else {}
                    qa_type = str(qa_item.get("type", "")).lower().replace("_", "").replace(".", "")
                    if qa_type == "commandexecution":
                        qa_command_count += 1
                        qa_exit = qa_item.get("exit_code")
                        if (isinstance(qa_exit, int) and qa_exit != 0) or str(qa_item.get("status", "")).lower() == "failed":
                            qa_command_failures += 1
                summary, approval = _event_summary(raw_event)
                if summary:
                    self._event(task_id, summary)
                if approval:
                    with self._lock:
                        self._approval_ids.add(task_id)
                    self._set(task_id, approval_required=True, status="blocked", error="Codex requested a protected operation. It was not approved by the monitor.")
                    self._event(task_id, {"timestamp": _now(), "category": "approval", "label": "Worker stopped; review the requested action in Codex before rerunning."})
                    _terminate_process_tree(process)
                    break
            else:
                timed_out = True
                _terminate_process_tree(process)
            if process.poll() is None:
                try:
                    process.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    _terminate_process_tree(process)
            return_code = process.poll()
            stdout_thread.join(timeout=2)
            stderr_thread.join(timeout=2)
            changed = _worktree_changes(worktree)
            state = "blocked" if approval else "cancelled" if self._is_cancelled(task_id) else "timed_out" if timed_out else "completed" if return_code == 0 else "failed"
            error = ""
            if state == "timed_out":
                error = "Worker exceeded the one-hour execution limit."
            elif state == "failed":
                error = stderr_lines[-1] if stderr_lines else f"Codex exited with code {return_code}."
            elif state == "cancelled":
                error = "Worker cancelled by the dashboard user."
            if state == "completed" and task.get("agent_id") == "agent-3":
                state, error = _qa_result(return_code, qa_command_count, qa_command_failures)
            self._finish(task_id, state, return_code, error, changed)
        except Exception as exc:
            self._finish(task_id, "failed", process.poll() if process else None, _safe_text(exc, 300))
        finally:
            with self._lock:
                self._processes.pop(task_id, None)
                self._cancelled.discard(task_id)
                self._approval_ids.discard(task_id)
                if self._active_id == task_id:
                    self._active_id = None

    def _is_cancelled(self, task_id: str) -> bool:
        with self._lock:
            return task_id in self._cancelled

    def _model_for(self, task_id: str) -> str:
        status = self._check_cli()
        model = status.get("model", "")
        if not model:
            raise RuntimeError("No compatible Codex model is available for this account.")
        return model

    def _approval_was_requested(self, task_id: str) -> bool:
        with self._lock:
            return task_id in self._approval_ids

    def _request_approval(self, task_id: str) -> None:
        with self._lock:
            self._approval_ids.add(task_id)

    def _finish(self, task_id: str, status: str, exit_code: int | None, error: str, changed_files: list[str] | None = None) -> None:
        with self._lock:
            task = self._tasks.get(task_id)
            if not task:
                return
            if task.get("approval_required"):
                status = "blocked"
            task.update({
                "status": status,
                "finished_at": _now(),
                "exit_code": exit_code if isinstance(exit_code, int) else None,
                "error": _safe_text(error, 500) if error else task.get("error", ""),
                "changed_files": changed_files if changed_files is not None else task.get("changed_files", []),
            })
            self._append_event_locked(task_id, f"Worker finished with status {status}." + (f" Exit code {exit_code}." if isinstance(exit_code, int) else ""), "error" if status in {"failed", "blocked", "timed_out"} else "lifecycle", exit_code)
            self._write_task_locked(task_id)

    def cancel(self, task_id: str) -> dict:
        self.get_task(task_id)
        with self._lock:
            if self._active_id != task_id:
                raise ValueError("This task is not the active worker.")
            self._cancelled.add(task_id)
            process = self._processes.get(task_id)
            self._append_event_locked(task_id, "Cancellation requested by the dashboard user.", "lifecycle")
        if process:
            _terminate_process_tree(process)
        return self.get_task(task_id)

    def get_task(self, task_id: str) -> dict:
        self._task_dir(task_id)
        with self._lock:
            task = self._tasks.get(task_id)
            if not task:
                raise ValueError("Task record was not found.")
            return self._public(task)

    def task_diff(self, task_id: str, relative: str) -> dict:
        self._task_dir(task_id)
        with self._lock:
            task = self._tasks.get(task_id)
            if not task:
                raise ValueError("Task record was not found.")
            allowed = set(task.get("changed_files") or [])
            worktree = self._worktree_dir(task)
        rel = relative.replace("\\", "/").lstrip("/")
        if rel not in allowed or not rel or ":" in rel or "\x00" in rel or any(part in ("", ".", "..") for part in rel.split("/")):
            raise ValueError("Choose a changed file from this task.")
        if _private_path(rel):
            return {"path": rel, "diff": "Diff content is hidden for local settings and secret files."}
        path = (worktree / rel).resolve(strict=False)
        if not path.is_relative_to(worktree.resolve()):
            raise ValueError("Task file is outside the isolated worktree.")
        result = subprocess.run(
            ["git", "-C", str(worktree), "diff", "--no-ext-diff", "--no-textconv", "--no-color", "HEAD", "--", rel],
            capture_output=True, timeout=8, check=False,
        )
        content = result.stdout.decode("utf-8", "replace") if result.returncode == 0 else ""
        if not content and path.is_file() and path.stat().st_size <= 1_000_000:
            text = path.read_text(encoding="utf-8", errors="replace").splitlines()
            content = "\n".join(difflib.unified_diff([], text, fromfile="/dev/null", tofile=rel, lineterm=""))
        return {"path": rel, "diff": _redact(content)[:60_000] if content else "No textual diff is available for this file."}


def _worker_environment() -> dict[str, str]:
    allowed = (
        "PATH", "PATHEXT", "SYSTEMROOT", "WINDIR", "COMSPEC", "TEMP", "TMP", "USERPROFILE",
        "HOMEDRIVE", "HOMEPATH", "APPDATA", "LOCALAPPDATA", "PROGRAMDATA", "CODEX_HOME",
    )
    return {key: os.environ[key] for key in allowed if key in os.environ}


def _read_pipe(stream, output: queue.Queue) -> None:
    try:
        for line in iter(stream.readline, b""):
            output.put(line)
    finally:
        output.put(None)
        try:
            stream.close()
        except OSError:
            pass


def _collect_stderr(stream, lines: list[str], manager: WorkerManager, task_id: str) -> None:
    try:
        for raw in iter(stream.readline, b""):
            value = _safe_text(raw.decode("utf-8", "replace"), 350)
            if value and re.search(r"(?i)error|failed|denied|approval|auth|login|not found|sandbox|unsupported", value):
                lines.append(value)
                del lines[:-12]
                category = "approval" if re.search(r"(?i)(approval\s+(required|request|needed)|needs? approval|requires? approval)", value) else "error"
                manager._event(task_id, {"timestamp": _now(), "category": category, "label": value})
                if category == "approval":
                    manager._request_approval(task_id)
    finally:
        try:
            stream.close()
        except OSError:
            pass


def _terminate_process_tree(process: subprocess.Popen) -> None:
    if process.poll() is not None:
        return
    try:
        if os.name == "nt":
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True, timeout=6, check=False)
        else:
            os.killpg(process.pid, 15)
    except (OSError, subprocess.SubprocessError):
        try:
            process.terminate()
        except OSError:
            pass


def _worktree_changes(worktree: Path) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(worktree), "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        capture_output=True, timeout=10, check=False,
    )
    if result.returncode != 0:
        return []
    paths: set[str] = set()
    rows = result.stdout.split(b"\0")
    index = 0
    while index < len(rows):
        item = rows[index]
        index += 1
        if len(item) < 4:
            continue
        relative = item[3:].decode("utf-8", "replace").replace("\\", "/")
        if b"R" in item[:2] or b"C" in item[:2]:
            index += 1
        if relative and not relative.startswith(".git/"):
            paths.add(relative)
    return sorted(paths)[:250]


def _private_path(relative: str) -> bool:
    parts = {part.lower() for part in Path(relative).parts}
    return (
        bool(parts & {"secrets", "credentials", "private_keys"})
        or any(part.startswith(".env") or "secret" in part or "credential" in part for part in parts)
        or any(relative.lower().endswith(suffix) for suffix in (".pem", ".key", ".p12", ".pfx", ".jks", ".keystore"))
    )


def _redact(text: str) -> str:
    lines = []
    for line in text.splitlines():
        line = SECRET_ASSIGNMENT.sub(r"\1[redacted]", line)
        line = BEARER.sub(r"\1[redacted]", line)
        line = TOKEN_LIKE.sub("[redacted-token]", line)
        lines.append(line)
    return "\n".join(lines)
