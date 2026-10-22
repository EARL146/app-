#!/usr/bin/env python3
"""Read-only, loopback-only monitor for local Codex records and this Git worktree.

This intentionally reads only Codex JSONL metadata needed for a timeline. It does
not return prompts, tool arguments, command text, tool output, or full session IDs.
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import ipaddress
import json
import mimetypes
import os
import re
import subprocess
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from agent_events import agent_overview
from worker_runtime import WorkerManager


PROJECT_ROOT = Path(__file__).resolve().parents[2]
STATIC_ROOT = Path(__file__).resolve().parent
IMAGE_ROOTS = ("assets", "lib/assets", "web/assets", "docs/assets")
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}
NOTE_FILES = (
    "docs/AGENT_TEAM.md",
    "docs/AGENT_MONITOR.md",
    "docs/NEXT_SESSION.md",
    "docs/KNOWN_ISSUES.md",
    "docs/TESTING.md",
    "docs/INTEGRATION_MAP.md",
    "docs/SCREEN_DESIGN_SPEC.md",
    "docs/SCREEN_FLOW.md",
    "docs/SCREEN_IMPLEMENTATION_STATUS.md",
)

DESIGN_SYSTEM_SCREENS = (
    {
        "id": "splash",
        "group": "Customer",
        "title": "Splash & Ingredient Intro",
        "route": "/",
        "file": "lib/screens/customer/splash_screen.dart",
        "primary_cta": "Auto-routes to Guest Menu / Role Home",
        "accent": "#ff4f24",
        "highlights": ["4.5s AnimatedBurgerAssembly", "Session restore (/me)", "Reduced-motion aware"],
    },
    {
        "id": "welcome",
        "group": "Customer",
        "title": "Welcome Hero",
        "route": "/welcome",
        "file": "lib/screens/customer/welcome_screen.dart",
        "primary_cta": "Get Started / Log In",
        "accent": "#ff4f24",
        "highlights": ["Floating burger cutout", "Studio glow backdrop", "320–430px responsive"],
    },
    {
        "id": "sign-in",
        "group": "Customer",
        "title": "Sign In",
        "route": "/sign-in",
        "file": "lib/screens/customer/sign_in_screen.dart",
        "primary_cta": "Sign In",
        "accent": "#ff4f24",
        "highlights": ["Role-aware routing", "Floating BrandLogo", "AnimatedPressScale CTA"],
    },
    {
        "id": "register",
        "group": "Customer",
        "title": "Create Account",
        "route": "/register",
        "file": "lib/screens/customer/register_screen.dart",
        "primary_cta": "Create Account",
        "accent": "#ef2f2b",
        "highlights": ["Argon2id API registration", "Pending action resume", "Validated inputs"],
    },
    {
        "id": "customer-home",
        "group": "Customer",
        "title": "Customer Home",
        "route": "/customer-home",
        "file": "lib/screens/customer/home_screen.dart",
        "primary_cta": "Order now",
        "accent": "#ff4f24",
        "highlights": ["Smash burger hero banner", "Category bubbles", "SQL recent orders"],
    },
    {
        "id": "menu",
        "group": "Customer",
        "title": "Menu Catalog",
        "route": "/menu",
        "file": "lib/screens/customer/menu_screen.dart",
        "primary_cta": "View cart · ₱total",
        "accent": "#ff4f24",
        "highlights": ["Guest-first browsing", "ChoiceChip filter bar", "Animated add-to-cart"],
    },
    {
        "id": "search",
        "group": "Customer",
        "title": "Catalog Search",
        "route": "/search",
        "file": "lib/screens/customer/search_screen.dart",
        "primary_cta": "Filter & Add",
        "accent": "#ff6b35",
        "highlights": ["Live SQL product filter", "Honest empty/error states", "Compact phone grid"],
    },
    {
        "id": "product-details",
        "group": "Customer",
        "title": "Product Details & Customizer",
        "route": "/product-details",
        "file": "lib/screens/customer/product_details_screen.dart",
        "primary_cta": "Add to cart",
        "accent": "#ff4f24",
        "highlights": ["Burger/fries size & drink choices", "Server-validated toppings", "Pop FavoriteButton"],
    },
    {
        "id": "favorites",
        "group": "Customer",
        "title": "Saved Favorites",
        "route": "/favorites",
        "file": "lib/screens/customer/favorites_screen.dart",
        "primary_cta": "Browse menu",
        "accent": "#ef2f2b",
        "highlights": ["User-scoped /me/favorites", "Quick add to cart", "Animated heart toggle"],
    },
    {
        "id": "cart",
        "group": "Customer",
        "title": "Shopping Cart",
        "route": "/cart",
        "file": "lib/screens/customer/cart_screen.dart",
        "primary_cta": "Proceed to checkout",
        "accent": "#ff4f24",
        "highlights": ["SQL /me/cart sync", "Quantity stepper", "Saved profile address"],
    },
    {
        "id": "checkout",
        "group": "Customer",
        "title": "Checkout & Payment",
        "route": "/checkout",
        "file": "lib/screens/customer/checkout_screen.dart",
        "primary_cta": "Place COD Order",
        "accent": "#24935b",
        "highlights": ["Transactional COD order", "GCash/Maya sandbox status", "Server price revalidation"],
    },
    {
        "id": "order-history",
        "group": "Customer",
        "title": "Order History",
        "route": "/order-history",
        "file": "lib/screens/customer/order_history_screen.dart",
        "primary_cta": "Reorder / Cancel",
        "accent": "#3789c9",
        "highlights": ["Active & completed tabs", "Pending order cancellation", "One-tap reorder"],
    },
    {
        "id": "profile",
        "group": "Customer",
        "title": "Customer Profile",
        "route": "/profile",
        "file": "lib/screens/customer/profile_screen.dart",
        "primary_cta": "Sign in / Edit profile",
        "accent": "#ff4f24",
        "highlights": ["Guest sign-in card", "Account & preferences", "Calendar & support links"],
    },
    {
        "id": "settings-preferences",
        "group": "Customer",
        "title": "Settings, Theme, Language & Calendar",
        "route": "/settings",
        "file": "lib/screens/customer/settings_screen.dart",
        "primary_cta": "Save preferences",
        "accent": "#f0a323",
        "highlights": ["Address & password update", "SQL calendar reminders", "Explicit delivery notices"],
    },
    {
        "id": "contact-about",
        "group": "Customer",
        "title": "Contact & About",
        "route": "/contact",
        "file": "lib/screens/customer/contact_screen.dart",
        "primary_cta": "Send message",
        "accent": "#24935b",
        "highlights": ["Public /store-profile data", "SQL support ticket form", "Verified store hours"],
    },
    {
        "id": "admin-home",
        "group": "Admin",
        "title": "Admin Dashboard",
        "route": "/admin",
        "file": "lib/screens/admin/admin_home_screen.dart",
        "primary_cta": "Manage Orders & Menu",
        "accent": "#ff4f24",
        "highlights": ["7-day SQL sales series", "Pending-order bell badge", "Live/placeholder state labels"],
    },
    {
        "id": "admin-orders",
        "group": "Admin",
        "title": "Admin Orders",
        "route": "/admin/orders",
        "file": "lib/screens/admin/admin_orders_screen.dart",
        "primary_cta": "Update Order Status",
        "accent": "#3789c9",
        "highlights": ["Status lifecycle controls", "Stock restock on cancel", "Search & status chips"],
    },
    {
        "id": "admin-products",
        "group": "Admin",
        "title": "Admin Products & Editor",
        "route": "/admin/products",
        "file": "lib/screens/admin/admin_products_screen.dart",
        "primary_cta": "Add / Save Product",
        "accent": "#24935b",
        "highlights": ["CRUD & archive flow", "Stock & availability toggle", "Fries/Drinks/Burgers categories"],
    },
    {
        "id": "admin-customers-more",
        "group": "Admin",
        "title": "Customers, Support, Store Profile & More",
        "route": "/admin/more",
        "file": "lib/screens/admin/admin_more_screen.dart",
        "primary_cta": "Save Store Profile",
        "accent": "#a77bff",
        "highlights": ["Migration 003 readiness check", "Store profile editor", "Support inbox & customer status"],
    },
)
SECRET_PATH_PARTS = {"secrets", "credentials", "private_keys"}
SECRET_ASSIGNMENT = re.compile(
    r"(?i)(\b(?:password|passwd|secret|token|api[_-]?key|private[_-]?key|"
    r"client[_-]?secret|authorization|credential|database[_-]?url)\b\s*[:=]\s*)([^\r\n,;]+)"
)
BEARER = re.compile(r"(?i)\b(bearer\s+)[A-Za-z0-9._~+/-]+=*")
TOKEN_LIKE = re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,})\b")
SAFE_WORD = re.compile(r"[^A-Za-z0-9_.:/ -]+")
USAGE_FIELDS = (
    "input_tokens",
    "cached_input_tokens",
    "cache_write_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
    "total_tokens",
)


def _timestamp(value: object) -> str:
    return str(value)[:40] if isinstance(value, (str, int, float)) else ""


def _safe_label(value: object, fallback: str = "event") -> str:
    label = SAFE_WORD.sub("", str(value or ""))[:64].strip()
    return label or fallback


def _new_session_state(path: Path) -> dict:
    return {
        "path": str(path),
        "session_id": "",
        "cli_version": "",
        "source": "",
        "tasks": [],
        "events": [],
        "errors": [],
        "task_started": 0,
        "task_completed": 0,
        "turn_aborted": 0,
        "tool_counts": collections.Counter(),
        "usage": {},
        "last_event_at": "",
        "last_task": None,
        "sequence": 0,
    }


def _add_event(state: dict, timestamp: str, category: str, label: str, detail: str = "") -> None:
    state["events"].append({
        "timestamp": timestamp,
        "category": _safe_label(category),
        "label": _safe_label(label),
        "detail": _safe_label(detail, "") if detail else "",
    })
    state["events"] = state["events"][-240:]
    if timestamp:
        state["last_event_at"] = timestamp


def ingest_record(state: dict, record: dict) -> None:
    """Keep only safe event metadata from one local Codex JSONL record."""
    record_type = record.get("type")
    payload = record.get("payload") if isinstance(record.get("payload"), dict) else {}
    timestamp = _timestamp(record.get("timestamp"))

    if record_type == "session_meta":
        sid = payload.get("session_id") or payload.get("id")
        state["session_id"] = _safe_label(str(sid or "")[:8], "unknown")
        state["cli_version"] = _safe_label(payload.get("cli_version"), "")
        state["source"] = _safe_label(payload.get("source") or payload.get("originator"), "")
        _add_event(state, timestamp, "session", "Session record opened")
        return

    if record_type == "event_msg":
        event_type = payload.get("type")
        if event_type == "task_started":
            state["sequence"] += 1
            task = {"number": state["sequence"], "started_at": timestamp, "completed_at": "", "status": "open"}
            state["tasks"].append(task)
            state["tasks"] = state["tasks"][-80:]
            state["last_task"] = task
            state["task_started"] += 1
            _add_event(state, timestamp, "task", "Task started", f"Task {task['number']}")
            return
        if event_type in ("task_complete", "turn_aborted"):
            status = "completed" if event_type == "task_complete" else "interrupted"
            if state["last_task"] and state["last_task"]["status"] == "open":
                state["last_task"]["status"] = status
                state["last_task"]["completed_at"] = timestamp
            if event_type == "task_complete":
                state["task_completed"] += 1
                _add_event(state, timestamp, "task", "Task completed")
            else:
                state["turn_aborted"] += 1
                error = {"timestamp": timestamp, "label": "Turn interrupted"}
                state["errors"].append(error)
                state["errors"] = state["errors"][-40:]
                _add_event(state, timestamp, "task", "Turn interrupted")
            return
        if event_type == "item_completed":
            item = payload.get("item") if isinstance(payload.get("item"), dict) else {}
            kind = item.get("type")
            if kind == "CommandExecution":
                code = item.get("exit_code")
                detail = f"exit code {code}" if isinstance(code, int) else "finished"
                _add_event(state, timestamp, "command", "Shell command", detail)
                if isinstance(code, int) and code != 0:
                    state["errors"].append({"timestamp": timestamp, "label": f"Shell command exited {code}"})
                    state["errors"] = state["errors"][-40:]
                return
            if kind == "FileChange":
                _add_event(state, timestamp, "file", "File change recorded")
                return
            if kind == "McpToolCall":
                tool = _safe_label(item.get("tool"), "MCP tool")
                status = _safe_label(item.get("status"), "recorded")
                state["tool_counts"][tool] += 1
                _add_event(state, timestamp, "tool", f"MCP · {tool}", status)
                if status.lower() in {"failed", "error"}:
                    state["errors"].append({"timestamp": timestamp, "label": f"MCP tool {tool} failed"})
                    state["errors"] = state["errors"][-40:]
                return

    if record_type == "response_item":
        kind = payload.get("type")
        if kind in ("custom_tool_call", "function_call"):
            tool = _safe_label(payload.get("name"), "tool")
            state["tool_counts"][tool] += 1
            _add_event(state, timestamp, "tool", f"Tool call · {tool}")
            return

    if record_type == "token_usage_record":
        usage = payload.get("thread_token_usage")
        if isinstance(usage, dict):
            state["usage"] = {
                field: int(usage[field])
                for field in USAGE_FIELDS
                if isinstance(usage.get(field), (int, float)) and usage[field] >= 0
            }


def read_session_records(path: Path, state: dict | None = None, offset: int = 0) -> tuple[dict, int]:
    state = state or _new_session_state(path)
    try:
        size = path.stat().st_size
        if offset > size:
            state = _new_session_state(path)
            offset = 0
        with path.open("rb") as stream:
            stream.seek(offset)
            while True:
                line_start = stream.tell()
                line = stream.readline()
                if not line:
                    offset = stream.tell()
                    break
                if not line.endswith(b"\n"):
                    offset = line_start
                    break
                try:
                    record = json.loads(line.decode("utf-8", "replace"))
                except (json.JSONDecodeError, ValueError):
                    offset = stream.tell()
                    continue
                if isinstance(record, dict):
                    ingest_record(state, record)
                offset = stream.tell()
    except OSError:
        return state, offset
    return state, offset


def summarize_session(path: Path, state: dict) -> dict:
    try:
        age = max(0, time.time() - path.stat().st_mtime)
    except OSError:
        age = 0
    task_status = state["last_task"]["status"] if state["last_task"] else "unknown"
    if task_status == "open":
        status = "Active in log" if age <= 300 else "Open, no recent event"
    elif task_status == "interrupted":
        status = "Interrupted"
    elif task_status == "completed":
        status = "Idle"
    else:
        status = "Observed"

    try:
        modified = dt.datetime.fromtimestamp(path.stat().st_mtime, dt.timezone.utc).isoformat(timespec="seconds")
    except OSError:
        modified = ""
    return {
        "session_id": state["session_id"] or "unknown",
        "cli_version": state["cli_version"],
        "source": state["source"],
        "status": status,
        "modified_at": modified,
        "age_seconds": int(age),
        "last_event_at": state["last_event_at"],
        "task_started": state["task_started"],
        "task_completed": state["task_completed"],
        "turn_aborted": state["turn_aborted"],
        "last_task_status": task_status,
        "tasks": state["tasks"][-30:],
        "tool_counts": dict(state["tool_counts"].most_common(30)),
        "errors": state["errors"][-30:],
        "events": state["events"][-100:][::-1],
        "usage": state["usage"],
        "source_label": "Local Codex JSONL record; read-only, not a live API",
    }


def parse_session_file(path: Path) -> dict:
    state, _ = read_session_records(path)
    return summarize_session(path, state)


def _filter_codex_processes(entries: object) -> list[dict]:
    """Return an allowlisted view of Codex CLI rows from a native process snapshot."""
    if not isinstance(entries, (list, tuple)):
        return []
    result = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        pid = entry.get("pid")
        parent_pid = entry.get("parent_pid")
        name = entry.get("name")
        if isinstance(pid, bool) or not isinstance(pid, int) or pid <= 0:
            continue
        if parent_pid is not None and (isinstance(parent_pid, bool) or not isinstance(parent_pid, int)):
            parent_pid = None
        if not isinstance(name, str) or name.casefold() not in {"codex.exe", "codex"}:
            continue
        started_at = entry.get("started_at")
        result.append({
            "pid": pid,
            "parent_pid": parent_pid,
            "name": "codex.exe" if name.casefold() == "codex.exe" else "codex",
            "started_at": started_at if isinstance(started_at, str) else None,
        })
    return result


def _windows_codex_processes() -> list[dict]:
    """Read process entries named codex.exe/codex; never inspect paths or command lines."""
    import ctypes
    from ctypes import wintypes

    class PROCESSENTRY32W(ctypes.Structure):
        _fields_ = [
            ("dwSize", wintypes.DWORD),
            ("cntUsage", wintypes.DWORD),
            ("th32ProcessID", wintypes.DWORD),
            ("th32DefaultHeapID", ctypes.c_size_t),
            ("th32ModuleID", wintypes.DWORD),
            ("cntThreads", wintypes.DWORD),
            ("th32ParentProcessID", wintypes.DWORD),
            ("pcPriClassBase", wintypes.LONG),
            ("dwFlags", wintypes.DWORD),
            ("szExeFile", wintypes.WCHAR * 260),
        ]

    class FILETIME(ctypes.Structure):
        _fields_ = [("dwLowDateTime", wintypes.DWORD), ("dwHighDateTime", wintypes.DWORD)]

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.CreateToolhelp32Snapshot.argtypes = (wintypes.DWORD, wintypes.DWORD)
    kernel32.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    kernel32.Process32FirstW.argtypes = (wintypes.HANDLE, ctypes.POINTER(PROCESSENTRY32W))
    kernel32.Process32FirstW.restype = wintypes.BOOL
    kernel32.Process32NextW.argtypes = (wintypes.HANDLE, ctypes.POINTER(PROCESSENTRY32W))
    kernel32.Process32NextW.restype = wintypes.BOOL
    kernel32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    kernel32.OpenProcess.restype = wintypes.HANDLE
    kernel32.GetProcessTimes.argtypes = (
        wintypes.HANDLE,
        ctypes.POINTER(FILETIME),
        ctypes.POINTER(FILETIME),
        ctypes.POINTER(FILETIME),
        ctypes.POINTER(FILETIME),
    )
    kernel32.GetProcessTimes.restype = wintypes.BOOL
    kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
    kernel32.CloseHandle.restype = wintypes.BOOL

    def started_at_for(pid: int) -> str | None:
        handle = kernel32.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
        if not handle:
            return None
        try:
            created, exited, kernel_time, user_time = FILETIME(), FILETIME(), FILETIME(), FILETIME()
            if not kernel32.GetProcessTimes(
                handle, ctypes.byref(created), ctypes.byref(exited),
                ctypes.byref(kernel_time), ctypes.byref(user_time),
            ):
                return None
            ticks = (created.dwHighDateTime << 32) | created.dwLowDateTime
            unix_seconds = ticks / 10_000_000 - 11_644_473_600
            return dt.datetime.fromtimestamp(unix_seconds, dt.timezone.utc).isoformat(timespec="seconds")
        except (OverflowError, OSError, ValueError):
            return None
        finally:
            kernel32.CloseHandle(handle)

    snapshot = kernel32.CreateToolhelp32Snapshot(0x00000002, 0)  # TH32CS_SNAPPROCESS
    invalid_handle = ctypes.c_void_p(-1).value
    if not snapshot or snapshot == invalid_handle:
        raise OSError("process snapshot unavailable")
    try:
        entry = PROCESSENTRY32W()
        entry.dwSize = ctypes.sizeof(PROCESSENTRY32W)
        if not kernel32.Process32FirstW(snapshot, ctypes.byref(entry)):
            raise OSError("process snapshot enumeration unavailable")
        rows = []
        while True:
            rows.append({
                "pid": int(entry.th32ProcessID),
                "parent_pid": int(entry.th32ParentProcessID),
                "name": str(entry.szExeFile),
                "started_at": None,
            })
            if not kernel32.Process32NextW(snapshot, ctypes.byref(entry)):
                if ctypes.get_last_error() != 18:  # ERROR_NO_MORE_FILES
                    raise OSError("process snapshot enumeration unavailable")
                break
        codex_rows = _filter_codex_processes(rows)
        for row in codex_rows:
            row["started_at"] = started_at_for(row["pid"])
        return codex_rows
    finally:
        kernel32.CloseHandle(snapshot)


def codex_process_snapshot() -> dict:
    """Return a name-matched Windows process snapshot, separate from session logs."""
    observed_at = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    if os.name != "nt":
        return {
            "available": False,
            "source": "unsupported",
            "observed_at": observed_at,
            "processes": [],
            "error": "unsupported_platform",
        }
    source = "Windows Toolhelp32Snapshot"
    try:
        processes = _windows_codex_processes()
    except Exception:
        return {
            "available": False,
            "source": source,
            "observed_at": observed_at,
            "processes": [],
            "error": "process_snapshot_unavailable",
        }
    return {
        "available": True,
        "source": source,
        "observed_at": observed_at,
        "processes": processes,
    }


class SessionIndex:
    def __init__(self, codex_home: Path):
        self.codex_home = codex_home
        self.cache: dict[str, tuple[int, int, dict, int]] = {}
        self.lock = threading.Lock()
        self.last_scan = 0.0
        self.paths: list[Path] = []

    def list(self) -> list[dict]:
        with self.lock:
            now = time.time()
            if now - self.last_scan > 3:
                base = self.codex_home / "sessions"
                files = []
                if base.is_dir():
                    for candidate in base.rglob("*.jsonl"):
                        try:
                            stat = candidate.stat()
                            if candidate.is_file() and stat.st_size <= 150 * 1024 * 1024 and stat.st_mtime >= now - 90 * 86400:
                                files.append((stat.st_mtime_ns, stat.st_size, candidate))
                        except OSError:
                            pass
                self.paths = [item[2] for item in sorted(files, reverse=True)[:8]]
                self.last_scan = now
            result = []
            for path in self.paths:
                try:
                    stat = path.stat()
                    key = str(path)
                    cached = self.cache.get(key)
                    if cached and cached[1] <= stat.st_size and (cached[1] != stat.st_size or cached[0] == stat.st_mtime_ns):
                        state, offset = read_session_records(path, cached[2], cached[3])
                    else:
                        state, offset = read_session_records(path)
                    self.cache[key] = (stat.st_mtime_ns, stat.st_size, state, offset)
                    item = summarize_session(path, state)
                    age = max(0, time.time() - stat.st_mtime)
                    item["age_seconds"] = int(age)
                    if item.get("last_task_status") == "open":
                        item["status"] = "Active in log" if age <= 300 else "Open, no recent event"
                    elif item.get("last_task_status") == "interrupted":
                        item["status"] = "Interrupted"
                    elif item.get("last_task_status") == "completed":
                        item["status"] = "Idle"
                    result.append(item)
                except OSError:
                    continue
            return result


def _run_git(root: Path, *args: str, timeout: float = 4) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(root), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        timeout=timeout,
        check=False,
    )


def git_snapshot(root: Path) -> dict:
    branch_result = _run_git(root, "branch", "--show-current")
    branch = branch_result.stdout.decode("utf-8", "replace").strip() if branch_result.returncode == 0 else ""
    status_result = _run_git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status_result.returncode != 0:
        return {"available": False, "error": "Git status is unavailable for this folder.", "files": []}

    entries = []
    raw = status_result.stdout.split(b"\0")
    index = 0
    while index < len(raw):
        item = raw[index]
        index += 1
        if len(item) < 4:
            continue
        state = item[:2].decode("ascii", "replace")
        rel = item[3:].decode("utf-8", "replace").replace("\\", "/")
        if "R" in state or "C" in state:
            index += 1
        if not rel:
            continue
        entries.append({"path": rel, "state": state, "kind": "untracked" if state == "??" else "changed"})

    upstream = _run_git(root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}")
    upstream_name = upstream.stdout.decode("utf-8", "replace").strip() if upstream.returncode == 0 else ""
    divergence = None
    if upstream_name:
        counts = _run_git(root, "rev-list", "--left-right", "--count", f"HEAD...{upstream_name}")
        if counts.returncode == 0:
            parts = counts.stdout.decode("ascii", "replace").split()
            if len(parts) == 2 and all(part.isdigit() for part in parts):
                divergence = {"ahead": int(parts[0]), "behind": int(parts[1]), "source": "cached remote-tracking ref; no fetch performed"}

    remotes = _run_git(root, "remote")
    remote_names = [line for line in remotes.stdout.decode("utf-8", "replace").splitlines() if line]
    return {
        "available": True,
        "branch": branch or "(detached HEAD)",
        "upstream": upstream_name,
        "divergence": divergence,
        "remotes_configured": remote_names,
        "files": entries,
        "changed_count": len(entries),
    }


def _safe_repo_file(root: Path, relative: str, allowed_roots: tuple[str, ...], extensions: set[str]) -> Path:
    if not relative or "\x00" in relative or ":" in relative:
        raise ValueError("Invalid project-relative path.")
    rel = relative.replace("\\", "/").lstrip("/")
    if any(part in ("", ".", "..") for part in rel.split("/")):
        raise ValueError("Path must stay inside the project.")
    candidate = (root / rel).resolve(strict=True)
    root_resolved = root.resolve()
    if not candidate.is_relative_to(root_resolved) or not candidate.is_file():
        raise ValueError("File is outside the project or is unavailable.")
    if candidate.suffix.lower() not in extensions:
        raise ValueError("File type is not available for preview.")
    if not any(rel == prefix or rel.startswith(prefix.rstrip("/") + "/") for prefix in allowed_roots):
        raise ValueError("File is outside the allowed preview folders.")
    return candidate


def design_system_snapshot(root: Path) -> dict:
    """Return local UI design tokens, screen catalog, and Figma connection readiness."""
    figma_url = os.environ.get("BURGER_BITES_FIGMA_URL", "").strip()
    figma_key_match = re.search(r"figma\.com/(?:design|file|proto)/([A-Za-z0-9_-]{10,64})", figma_url)
    figma_file_key = figma_key_match.group(1) if figma_key_match else ""
    screens = []
    for item in DESIGN_SYSTEM_SCREENS:
        file_path = root / item["file"]
        screens.append({
            **item,
            "exists": file_path.is_file(),
        })
    return {
        "figma": {
            "connected": bool(figma_file_key),
            "file_key": figma_file_key,
            "mode": "Local interactive Figma Artboard Studio + SVG Vector Export",
            "note": (
                "Paste your Figma file URL in the dashboard to bind frame deep-links in this browser, "
                "or export the vector SVG artboard sheet to drag-and-drop all BurgerBites screens directly into Figma."
            ),
        },
        "tokens": {
            "colors": [
                {"name": "brandOrange", "hex": "#FF4F24", "usage": "Primary CTAs, active tabs, price emphasis"},
                {"name": "brandOrangeDark", "hex": "#E84018", "usage": "Pressed CTA state, gradient stops"},
                {"name": "brandRed", "hex": "#EF2F2B", "usage": "Wordmark accent, heart badges"},
                {"name": "pageBackground", "hex": "#FAF7F5", "usage": "Warm cream mobile scaffold"},
                {"name": "surface", "hex": "#FFFFFF", "usage": "Elevated product & order cards"},
                {"name": "surfaceMuted", "hex": "#FFF0E9", "usage": "Soft coral icon wells & selected chips"},
                {"name": "textPrimary", "hex": "#261C18", "usage": "Espresso headings & primary copy"},
                {"name": "textSecondary", "hex": "#81756F", "usage": "Warm muted descriptions & metadata"},
                {"name": "darkSurface", "hex": "#1C1715", "usage": "Hero offer banners & dark snackbars"},
                {"name": "success", "hex": "#24935B", "usage": "Order completed & schema ready badges"},
            ],
            "typography": [
                {"role": "Display Large", "spec": "Roboto · 32px · w800 · -0.8px tracking"},
                {"role": "Headline Medium", "spec": "Roboto · 24px · w900 · -0.5px tracking"},
                {"role": "Title Large", "spec": "Roboto · 19px · w800 · -0.3px tracking"},
                {"role": "Body Large", "spec": "Roboto · 15px · w500 · 1.45 line-height"},
                {"role": "Label Large / Button", "spec": "Roboto · 13px · w800 · +0.2px tracking"},
            ],
            "animations": [
                {"name": "AnimatedPressScale", "spec": "140ms Curves.easeOutCubic scale 1.0 → 0.96 on tap with reduced-motion guard"},
                {"name": "AnimatedBrandButton", "spec": "Warm coral gradient (#FF4F24 → #FF7838), soft glow shadow, and tactile press state"},
                {"name": "FavoriteButton Pop", "spec": "220ms TweenSequence heart bounce (1.0 → 1.24 → 1.0) on favorite toggle"},
                {"name": "Splash Ingredient Assembly", "spec": "4.5s staggered burger layer drop + floating BrandLogo cutout"},
            ],
        },
        "screens": screens,
    }


def list_images(root: Path) -> list[dict]:
    results = []
    for folder in IMAGE_ROOTS:
        base = root / folder
        if not base.is_dir() or base.is_symlink() or not base.resolve().is_relative_to(root.resolve()):
            continue
        for path in base.rglob("*"):
            try:
                if path.is_symlink() or not path.is_file() or path.suffix.lower() not in IMAGE_EXTENSIONS:
                    continue
                if path.stat().st_size > 20 * 1024 * 1024:
                    continue
                rel = path.relative_to(root).as_posix()
                results.append({"path": rel, "size": path.stat().st_size})
            except OSError:
                continue
            if len(results) >= 150:
                return sorted(results, key=lambda item: item["path"].lower())
    return sorted(results, key=lambda item: item["path"].lower())


def _private_path(relative: str) -> bool:
    parts = {part.lower() for part in Path(relative).parts}
    sensitive_suffixes = (".pem", ".key", ".p12", ".pfx", ".jks", ".keystore")
    return (
        bool(parts & SECRET_PATH_PARTS)
        or any(part.startswith(".env") or "secret" in part or "credential" in part for part in parts)
        or any(relative.lower().endswith(suffix) for suffix in sensitive_suffixes)
    )


def _redact_diff(text: str) -> str:
    lines = []
    for line in text.splitlines():
        line = SECRET_ASSIGNMENT.sub(r"\1[redacted]", line)
        line = BEARER.sub(r"\1[redacted]", line)
        line = TOKEN_LIKE.sub("[redacted-token]", line)
        lines.append(line)
    result = "\n".join(lines)
    return result[:60000] + ("\n… diff truncated at 60,000 characters" if len(result) > 60000 else "")


def file_diff(root: Path, relative: str) -> dict:
    rel = relative.replace("\\", "/").lstrip("/")
    if not rel or ":" in rel or "\x00" in rel or any(part in ("", ".", "..") for part in rel.split("/")):
        raise ValueError("Invalid project-relative path.")
    physical = (root / rel).resolve(strict=True)
    if not physical.is_relative_to(root.resolve()) or not physical.is_file():
        raise ValueError("File is outside the project.")
    if _private_path(rel) or rel.lower().startswith(".obsidian/") or rel.lower().startswith("graphify-out/"):
        return {"path": rel, "diff": "Diff content is hidden for local settings, graph data, and secret files."}
    tracked = _run_git(root, "ls-files", "--error-unmatch", "--", rel)
    if tracked.returncode != 0:
        return {"path": rel, "diff": "This file is untracked; Git has no diff to show yet."}
    unstaged = _run_git(root, "diff", "--no-ext-diff", "--no-textconv", "--no-color", "--", rel, timeout=8)
    staged = _run_git(root, "diff", "--cached", "--no-ext-diff", "--no-textconv", "--no-color", "--", rel, timeout=8)
    result = ""
    if staged.stdout:
        result += "STAGED\n" + staged.stdout.decode("utf-8", "replace") + "\n"
    if unstaged.stdout:
        result += "WORKTREE\n" + unstaged.stdout.decode("utf-8", "replace")
    return {"path": rel, "diff": _redact_diff(result) if result else "No diff for this file."}


class MonitorHandler(BaseHTTPRequestHandler):
    server_version = "BurgerBitesMonitor/2.0"

    @property
    def project_root(self) -> Path:
        return self.server.project_root

    @property
    def sessions(self) -> SessionIndex:
        return self.server.session_index

    def log_message(self, format: str, *args) -> None:
        return

    def _headers(self, content_type: str, length: int) -> None:
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(length))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        self.end_headers()

    def _json(self, value: object, status: int = 200) -> None:
        payload = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        self.end_headers()
        self.wfile.write(payload)

    def _local_request_allowed(self, require_origin: bool = False) -> bool:
        host = (self.headers.get("Host") or "").split(":", 1)[0].strip("[]").lower()
        if host not in {"127.0.0.1", "localhost"}:
            return False
        try:
            if not ipaddress.ip_address(self.client_address[0]).is_loopback:
                return False
        except ValueError:
            return False
        if require_origin:
            port = int(self.server.server_address[1])
            origin = self.headers.get("Origin", "")
            if origin not in {f"http://127.0.0.1:{port}", f"http://localhost:{port}"}:
                return False
        return True

    def do_GET(self) -> None:  # noqa: N802 - stdlib handler method name
        if not self._local_request_allowed():
            self._json({"error": "Use the local dashboard address."}, 403)
            return
        parsed = urlsplit(self.path)
        query = parse_qs(parsed.query, keep_blank_values=True)
        try:
            if parsed.path == "/":
                self._static("index.html", "text/html; charset=utf-8")
            elif parsed.path in ("/app.js", "/city.js", "/style.css", "/city.css"):
                name = parsed.path.lstrip("/")
                content_type = "text/javascript; charset=utf-8" if name.endswith(".js") else "text/css; charset=utf-8"
                self._static(name, content_type)
            elif parsed.path == "/api/overview":
                self._json({
                    "project": self.project_root.name,
                    "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
                    "git": git_snapshot(self.project_root),
                    "sessions": self.sessions.list(),
                    "codex_processes": codex_process_snapshot(),
                    "agents": agent_overview(),
                    "design_system": design_system_snapshot(self.project_root),
                    "notes": [path for path in NOTE_FILES if (self.project_root / path).is_file()],
                    "images": list_images(self.project_root),
                    "limits": [
                        "Task/session details are local JSONL records; the separate Windows process snapshot is name-matched OS data and is not linked to a session or role.",
                        "Existing session records remain log-derived. Worker activity comes from the isolated Codex CLI JSON event stream; prompts, tool arguments, command text, and raw output are withheld.",
                        "Agent role metrics come only from explicit local agent-event records; this is not a live agent API.",
                        "Agent 5 cannot inspect a browser DevTools session; console or API error text must be provided by the user, with secrets and customer data removed.",
                        "GitHub is not contacted. Ahead/behind counts use cached remote-tracking refs only.",
                        "Coding, debugging, and QA workers run one at a time in isolated worktrees based on committed HEAD. The main worktree is not changed by workers.",
                    ],
                })
            elif parsed.path == "/api/design-system":
                self._json(design_system_snapshot(self.project_root))
            elif parsed.path == "/api/tasks":
                self._json(self.server.worker_manager.list_tasks())
            elif parsed.path.startswith("/api/tasks/") and re.fullmatch(r"/api/tasks/[0-9a-f]{32}", parsed.path):
                self._json(self.server.worker_manager.get_task(parsed.path.rsplit("/", 1)[-1]))
            elif parsed.path == "/api/task-diff":
                self._json(self.server.worker_manager.task_diff(query.get("task_id", [""])[0], query.get("path", [""])[0]))
            elif parsed.path == "/api/diff":
                self._json(file_diff(self.project_root, query.get("path", [""])[0]))
            elif parsed.path == "/api/note":
                rel = query.get("path", [""])[0]
                if rel not in NOTE_FILES:
                    raise ValueError("Choose one of the listed project notes.")
                path = _safe_repo_file(self.project_root, rel, ("docs",), {".md"})
                if path.stat().st_size > 500_000:
                    raise ValueError("Note exceeds the preview size limit.")
                content = path.read_text(encoding="utf-8", errors="replace")
                self._json({"path": rel, "content": _redact_diff(content)})
            elif parsed.path == "/api/image":
                rel = query.get("path", [""])[0]
                allowed_roots = tuple(folder for folder in IMAGE_ROOTS if (self.project_root / folder).is_dir())
                path = _safe_repo_file(self.project_root, rel, allowed_roots, IMAGE_EXTENSIONS)
                if path.stat().st_size > 20 * 1024 * 1024:
                    raise ValueError("Image exceeds the preview size limit.")
                content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
                body = path.read_bytes()
                self._headers(content_type, len(body))
                self.wfile.write(body)
            else:
                self._json({"error": "Not found."}, 404)
        except ValueError as exc:
            self._json({"error": str(exc)}, 400)
        except (OSError, subprocess.TimeoutExpired):
            self._json({"error": "Local read operation failed."}, 500)

    def do_POST(self) -> None:  # noqa: N802 - stdlib handler method name
        if not self._local_request_allowed(require_origin=True):
            self._json({"error": "Worker controls accept same-origin requests from the local dashboard only."}, 403)
            return
        if self.headers.get_content_type() != "application/json":
            self._json({"error": "Send a JSON request body."}, 415)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length < 2 or length > 16_384:
            self._json({"error": "Request body must be between 2 bytes and 16 KB."}, 413)
            return
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self._json({"error": "Request body is not valid JSON."}, 400)
            return
        if not isinstance(payload, dict) or payload.get("confirm") is not True:
            self._json({"error": "Review the isolated-worker notice and explicitly confirm before starting or cancelling work."}, 400)
            return
        path = urlsplit(self.path).path
        try:
            if path == "/api/tasks":
                task = self.server.worker_manager.start_coding_task(
                    payload.get("agent_id", "agent-1"), payload.get("label", ""), payload.get("prompt", "")
                )
                self._json(task, 202)
            elif re.fullmatch(r"/api/tasks/[0-9a-f]{32}/qa", path):
                task_id = path.split("/")[3]
                self._json(self.server.worker_manager.start_qa_task(task_id), 202)
            elif re.fullmatch(r"/api/tasks/[0-9a-f]{32}/cancel", path):
                task_id = path.split("/")[3]
                self._json(self.server.worker_manager.cancel(task_id), 202)
            else:
                self._json({"error": "Not found."}, 404)
        except ValueError as exc:
            self._json({"error": str(exc)}, 400)
        except RuntimeError as exc:
            self._json({"error": str(exc)}, 409)
        except (OSError, subprocess.SubprocessError):
            self._json({"error": "Worker request failed before it could be safely started."}, 500)

    def _static(self, name: str, content_type: str) -> None:
        path = STATIC_ROOT / name
        body = path.read_bytes()
        self._headers(content_type, len(body))
        self.wfile.write(body)

class MonitorServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(self, address: tuple[str, int], project_root: Path, codex_home: Path, codex_executable: str | None = None, worker_state_root: Path | None = None):
        super().__init__(address, MonitorHandler)
        self.project_root = project_root.resolve()
        self.session_index = SessionIndex(codex_home)
        self.worker_manager = WorkerManager(
            self.project_root,
            worker_state_root or STATIC_ROOT / ".state" / "agent-city",
            codex_executable,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the local BurgerBites agent monitor and isolated Codex worker controls.")
    parser.add_argument("--host", default="127.0.0.1", help="Loopback address only (default: 127.0.0.1).")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT, help="BurgerBites project root.")
    parser.add_argument("--open", action="store_true", help="Open the local Agent Monitor in the default browser on startup.")
    args = parser.parse_args()
    try:
        if args.host != "127.0.0.1" or not ipaddress.ip_address(args.host).is_loopback:
            parser.error("Only a loopback host is allowed.")
    except ValueError:
        parser.error("Host must be a loopback IP address such as 127.0.0.1.")
    root = args.root.resolve()
    if not (root / ".git").exists():
        parser.error("Project root must be a Git working tree.")
    codex_home = Path(os.environ.get("CODEX_HOME") or (Path.home() / ".codex")).expanduser()
    server = MonitorServer((args.host, args.port), root, codex_home)
    url = f"http://{args.host}:{args.port}"
    print(f"Local Agent Monitor: {url}")
    print(f"Agent City 2D Office Simulation: {url}/#city")
    print(f"Project: {root}")
    print("Press Ctrl+C to stop. Worker controls are loopback-only and use isolated Git worktrees.")
    if args.open:
        threading.Timer(0.25, lambda: webbrowser.open(f"{url}/#city")).start()
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
