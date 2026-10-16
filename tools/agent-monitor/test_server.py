import json
import subprocess
import threading
import tempfile
import unittest
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

import server


class MonitorTests(unittest.TestCase):
    def test_codex_process_filter_keeps_only_safe_codex_metadata(self):
        entries = [
            {
                "pid": 101,
                "parent_pid": 100,
                "name": "codex.exe",
                "started_at": "2026-10-16T08:30:00Z",
                "executable_path": "C:/Users/private/codex.exe",
                "command_line": "codex --api-key secret-value",
            },
            {
                "pid": 102,
                "parent_pid": None,
                "name": "Codex",
                "started_at": None,
                "path": "C:/private/codex",
                "cmdline": "contains private input",
            },
            {"pid": 103, "parent_pid": 100, "name": "node.exe", "started_at": None},
            {"pid": "invalid", "parent_pid": None, "name": "codex.exe", "started_at": None},
            {"pid": 104, "parent_pid": None, "name": "codex-helper.exe", "started_at": None},
        ]

        result = server._filter_codex_processes(entries)

        self.assertEqual({row["pid"] for row in result}, {101, 102})
        for row in result:
            self.assertEqual(set(row), {"pid", "parent_pid", "name", "started_at"})
        encoded = json.dumps(result)
        for private in ("C:/Users/private", "api-key", "secret-value", "contains private input"):
            self.assertNotIn(private, encoded)

    def test_codex_process_snapshot_reports_supported_empty_result(self):
        with patch("server.os.name", "nt"), patch("server._windows_codex_processes", return_value=[]):
            result = server.codex_process_snapshot()

        self.assertTrue(result["available"])
        self.assertEqual(result["source"], "Windows Toolhelp32Snapshot")
        self.assertEqual(result["processes"], [])
        self.assertIn("observed_at", result)
        datetime.fromisoformat(result["observed_at"].replace("Z", "+00:00"))

    def test_codex_process_snapshot_reports_unsupported_platform(self):
        with patch("server.os.name", "posix"), patch("server._windows_codex_processes") as enumerate_processes:
            result = server.codex_process_snapshot()

        enumerate_processes.assert_not_called()
        self.assertFalse(result["available"])
        self.assertEqual(result["source"], "unsupported")
        self.assertEqual(result["error"], "unsupported_platform")
        datetime.fromisoformat(result["observed_at"].replace("Z", "+00:00"))

    def test_codex_process_snapshot_normalizes_native_enumeration_errors(self):
        with patch("server.os.name", "nt"), patch(
            "server._windows_codex_processes",
            side_effect=RuntimeError("private native error details"),
        ):
            result = server.codex_process_snapshot()

        self.assertFalse(result["available"])
        self.assertEqual(result["source"], "Windows Toolhelp32Snapshot")
        self.assertEqual(result["error"], "process_snapshot_unavailable")
        self.assertEqual(result["processes"], [])
        self.assertNotIn("private native error details", json.dumps(result))
        datetime.fromisoformat(result["observed_at"].replace("Z", "+00:00"))

    def test_session_parser_keeps_metadata_and_omits_private_content(self):
        records = [
            {"type": "session_meta", "timestamp": "2026-10-15T10:00:00Z", "payload": {"session_id": "12345678-secret", "cli_version": "1.2.3", "cwd": "C:/private"}},
            {"type": "event_msg", "timestamp": "2026-10-15T10:01:00Z", "payload": {"type": "task_started"}},
            {"type": "response_item", "timestamp": "2026-10-15T10:01:01Z", "payload": {"type": "custom_tool_call", "name": "exec", "input": "PASSWORD=hunter2"}},
            {"type": "event_msg", "timestamp": "2026-10-15T10:01:02Z", "payload": {"type": "item_completed", "item": {"type": "CommandExecution", "exit_code": 1, "command": "echo SECRET=abc", "aggregated_output": "private output"}}},
            {"type": "token_usage_record", "timestamp": "2026-10-15T10:01:03Z", "payload": {"thread_token_usage": {"input_tokens": 10, "output_tokens": 3, "total_tokens": 13}}},
        ]
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "session.jsonl"
            path.write_text("\n".join(json.dumps(item) for item in records) + "\n", encoding="utf-8")
            result = server.parse_session_file(path)
        encoded = json.dumps(result)
        self.assertEqual(result["session_id"], "12345678")
        self.assertEqual(result["task_started"], 1)
        self.assertEqual(result["usage"]["total_tokens"], 13)
        self.assertTrue(result["errors"])
        for private in ("hunter2", "SECRET=abc", "private output", "C:/private", "12345678-secret"):
            self.assertNotIn(private, encoded)

    def test_path_guard_rejects_parent_traversal_and_accepts_project_image(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "assets").mkdir()
            (root / "assets" / "actual.png").write_bytes(b"image")
            path = server._safe_repo_file(root, "assets/actual.png", ("assets",), server.IMAGE_EXTENSIONS)
            self.assertEqual(path.name, "actual.png")
            with self.assertRaises(ValueError):
                server._safe_repo_file(root, "../outside.png", ("assets",), server.IMAGE_EXTENSIONS)

    def test_diff_redacts_common_secret_fields(self):
        text = "+password = example-password\n+Authorization: Bearer abcdef\n+safe = true"
        result = server._redact_diff(text)
        self.assertNotIn("example-password", result)
        self.assertNotIn("abcdef", result)
        self.assertIn("safe = true", result)

    def test_git_diff_preview_redacts_secret_assignment(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "settings.txt").write_text("password = local-example-secret\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(root), "add", "--", "settings.txt"], check=True)
            result = server.file_diff(root, "settings.txt")["diff"]
            self.assertNotIn("local-example-secret", result)
            self.assertIn("[redacted]", result)

    def test_incremental_reader_waits_for_a_complete_record(self):
        first = {"type": "event_msg", "timestamp": "2026-10-15T10:00:00Z", "payload": {"type": "task_started"}}
        second = {"type": "event_msg", "timestamp": "2026-10-15T10:01:00Z", "payload": {"type": "task_complete"}}
        encoded_second = json.dumps(second).encode("utf-8")
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "incremental.jsonl"
            path.write_bytes(json.dumps(first).encode("utf-8") + b"\n" + encoded_second[:30])
            state, offset = server.read_session_records(path)
            self.assertEqual(state["task_started"], 1)
            self.assertEqual(state["task_completed"], 0)
            with path.open("ab") as stream:
                stream.write(encoded_second[30:] + b"\n")
            state, offset = server.read_session_records(path, state, offset)
            self.assertEqual(state["task_completed"], 1)
            self.assertGreater(offset, 0)

    def test_local_http_preview_routes_and_path_rejection(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "project"
            (root / "docs").mkdir(parents=True)
            (root / "assets").mkdir()
            (root / ".git").mkdir()
            (root / "docs" / "AGENT_TEAM.md").write_text("# Agent team\nSafe role definitions", encoding="utf-8")
            (root / "docs" / "NEXT_SESSION.md").write_text("# Memory note\nSafe preview", encoding="utf-8")
            (root / "assets" / "sample.png").write_bytes(b"actual image bytes")
            srv = server.MonitorServer(("127.0.0.1", 0), root, Path(temp) / "codex")
            thread = threading.Thread(target=srv.serve_forever, daemon=True)
            thread.start()
            base = f"http://127.0.0.1:{srv.server_address[1]}"
            try:
                with urllib.request.urlopen(base + "/api/overview") as response:
                    overview = json.load(response)
                self.assertEqual(overview["notes"], ["docs/AGENT_TEAM.md", "docs/NEXT_SESSION.md"])
                self.assertEqual(len(overview["agents"]["roles"]), 4)
                self.assertEqual(overview["agents"]["roles"][1]["role"], "Backend/API Developer")
                self.assertEqual(overview["images"][0]["path"], "assets/sample.png")
                with urllib.request.urlopen(base + "/api/note?path=docs%2FAGENT_TEAM.md") as response:
                    self.assertIn("Safe role definitions", json.load(response)["content"])
                with urllib.request.urlopen(base + "/api/note?path=docs%2FNEXT_SESSION.md") as response:
                    self.assertIn("Safe preview", json.load(response)["content"])
                with urllib.request.urlopen(base + "/api/image?path=assets%2Fsample.png") as response:
                    self.assertEqual(response.read(), b"actual image bytes")
                with self.assertRaises(urllib.error.HTTPError) as error:
                    urllib.request.urlopen(base + "/api/note?path=..%2Foutside.md")
                self.assertEqual(error.exception.code, 400)
                error.exception.close()
                request = urllib.request.Request(base + "/api/overview", headers={"Host": "example.com"})
                with self.assertRaises(urllib.error.HTTPError) as error:
                    urllib.request.urlopen(request)
                self.assertEqual(error.exception.code, 403)
                error.exception.close()
            finally:
                srv.shutdown()
                srv.server_close()
                thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main()
