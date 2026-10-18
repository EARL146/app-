import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from worker_runtime import ALLOWED_WORKERS, WorkerManager, _event_summary, _qa_result, _safe_text, _select_model, _worker_prompt, _worktree_changes


def git(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True, text=True)
    return result.stdout.strip()


class WorkerRuntimeTests(unittest.TestCase):
    def make_repo(self, root: Path) -> WorkerManager:
        root.mkdir(parents=True, exist_ok=True)
        git(root, "init", "-q")
        git(root, "config", "user.name", "Monitor Test")
        git(root, "config", "user.email", "monitor-test@example.invalid")
        (root / ".gitignore").write_text(".state/\n", encoding="utf-8")
        (root / "source.txt").write_text("committed baseline\n", encoding="utf-8")
        git(root, "add", "--", ".gitignore", "source.txt")
        git(root, "commit", "-q", "-m", "test baseline")
        state = root / "tools" / "agent-monitor" / ".state" / "agent-city"
        return WorkerManager(root, state, codex_executable="codex-test")

    def test_codex_json_events_keep_status_but_omit_commands_and_outputs(self):
        summary, approval = _event_summary({
            "type": "item.completed",
            "item": {
                "type": "command_execution",
                "command": "flutter test --token=sk-super-secret-value",
                "exit_code": 1,
                "aggregated_output": "password=hunter2 private data",
            },
        })

        self.assertFalse(approval)
        encoded = json.dumps(summary)
        self.assertEqual(summary["exit_code"], 1)
        self.assertIn("Command completed", encoded)
        for hidden in ("flutter test", "super-secret", "hunter2", "private data", "aggregated_output"):
            self.assertNotIn(hidden, encoded)

    def test_approval_event_is_classified_without_exposing_payload(self):
        summary, approval = _event_summary({
            "type": "approval.requested",
            "command": "remove user data",
            "secret": "private-value",
        })

        self.assertTrue(approval)
        self.assertEqual(summary["category"], "approval")
        self.assertNotIn("private-value", json.dumps(summary))
        self.assertNotIn("remove user data", json.dumps(summary))

    def test_codex_error_event_shows_sanitized_reason_without_tokens(self):
        summary, _ = _event_summary({
            "type": "error",
            "message": json.dumps({"error": {"message": "Request failed: API_KEY=sk-abcdefghijklmnopqrstuvwxyz is invalid."}}),
        })
        self.assertIn("Request failed", summary["label"])
        self.assertNotIn("abcdefghijklmnopqrstuvwxyz", json.dumps(summary))

    def test_error_sanitizer_redacts_credentials_and_local_personal_data(self):
        value = _safe_text("Authorization: Bearer abcdef; api_key=sk-abcdefghijklmnopqrstuvwxyz; earl@example.com C:\\Users\\private\\AppData")
        self.assertNotIn("abcdef", value)
        self.assertNotIn("abcdefghijklmnopqrstuvwxyz", value)
        self.assertNotIn("earl@example.com", value)
        self.assertNotIn("C:\\Users\\private", value)

    def test_model_selection_uses_config_only_when_present_in_cli_catalog(self):
        rows = [
            {"slug": "model-a", "visibility": "list", "supported_in_api": True},
            {"slug": "model-hidden", "visibility": "hide", "supported_in_api": True},
            {"slug": "model-disabled", "visibility": "list", "supported_in_api": False},
            {"slug": "model-b", "visibility": "list", "supported_in_api": True},
        ]
        self.assertEqual(_select_model(rows, "model-b"), "model-b")
        self.assertEqual(_select_model(rows, "missing-model"), "model-a")
        self.assertEqual(_select_model([], "model-a"), "")

    def test_qa_status_requires_recorded_successful_checks(self):
        self.assertEqual(_qa_result(0, 0, 0)[0], "failed")
        self.assertEqual(_qa_result(0, 3, 1), ("failed", "1 of 3 recorded QA check commands returned nonzero exit codes."))
        self.assertEqual(_qa_result(0, 2, 0), ("completed", ""))
        self.assertEqual(_qa_result(1, 2, 0)[0], "failed")

    def test_worktree_starts_at_committed_head_and_preserves_dirty_main_worktree(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "repo"
            manager = self.make_repo(root)
            (root / "source.txt").write_text("uncommitted user edit\n", encoding="utf-8")
            (root / "user-untracked.txt").write_text("keep this file\n", encoding="utf-8")
            task = manager._create_task("agent-1", "Safe task", "coding", None, None)

            worktree, baseline = manager._create_worktree(task)

            self.assertTrue(baseline)
            self.assertEqual((worktree / "source.txt").read_text(encoding="utf-8"), "committed baseline\n")
            self.assertEqual((root / "source.txt").read_text(encoding="utf-8"), "uncommitted user edit\n")
            self.assertEqual((root / "user-untracked.txt").read_text(encoding="utf-8"), "keep this file\n")
            self.assertEqual(git(worktree, "rev-parse", "--is-inside-work-tree"), "true")
            self.assertEqual(git(worktree, "status", "--porcelain"), "")

    def test_task_prompt_is_not_persisted_in_task_history(self):
        with tempfile.TemporaryDirectory() as temp:
            manager = self.make_repo(Path(temp) / "repo")
            sensitive_prompt = "Change only the greeting. private-token=sk-abcdefghijklmnopqrstuvwxyz"
            with patch.object(manager, "_check_cli", return_value={"available": True, "authenticated": True, "model": "model-a"}), patch("worker_runtime.threading.Thread") as thread:
                task = manager.start_coding_task("agent-1", "Greeting update", sensitive_prompt)
                thread.return_value.start.assert_called_once()

            encoded = json.dumps(task)
            self.assertNotIn("Change only the greeting", encoded)
            self.assertNotIn("abcdefghijklmnopqrstuvwxyz", encoded)
            metadata = (manager._task_dir(task["task_id"]) / "task.json").read_text(encoding="utf-8")
            self.assertNotIn("Change only the greeting", metadata)
            self.assertNotIn("abcdefghijklmnopqrstuvwxyz", metadata)

    def test_agent5_is_a_scoped_debug_worker_and_uses_supplied_console_evidence(self):
        self.assertEqual(ALLOWED_WORKERS["agent-5"], "Customer/Admin Debugger")
        prompt = _worker_prompt("agent-5", "Debug customer account creation", "TypeError: submit callback failed")
        self.assertIn("customer and admin sign-in and account-creation", prompt)
        self.assertIn("cannot see the user's browser DevTools", prompt)
        self.assertIn("TypeError: submit callback failed", prompt)
        self.assertIn("real passwords", prompt)

    def test_agent5_task_is_recorded_as_debugging_without_storing_prompt(self):
        with tempfile.TemporaryDirectory() as temp:
            manager = self.make_repo(Path(temp) / "repo")
            error_text = "TypeError: removeChild failed in the customer registration form"
            with patch.object(manager, "_check_cli", return_value={"available": True, "authenticated": True, "model": "model-a"}), patch("worker_runtime.threading.Thread") as thread:
                task = manager.start_coding_task("agent-5", "Debug customer registration", error_text)
                thread.return_value.start.assert_called_once()

            self.assertEqual(task["role"], "Customer/Admin Debugger")
            self.assertEqual(task["kind"], "debugging")
            self.assertIn(error_text, thread.call_args.kwargs["args"][1])
            self.assertNotIn(error_text, json.dumps(task))

    def test_qa_worker_reuses_completed_coding_worktree_and_baseline(self):
        with tempfile.TemporaryDirectory() as temp:
            manager = self.make_repo(Path(temp) / "repo")
            coder = manager._create_task("agent-1", "Update layout", "coding", None, None)
            _, baseline = manager._create_worktree(coder)
            with manager._lock:
                manager._tasks[coder["task_id"]].update(status="completed", baseline_commit=baseline)
                manager._active_id = None
            with patch.object(manager, "_check_cli", return_value={"available": True, "authenticated": True, "model": "model-a"}), patch("worker_runtime.threading.Thread") as thread:
                qa = manager.start_qa_task(coder["task_id"])
                thread.return_value.start.assert_called_once()
            self.assertEqual(qa["agent_id"], "agent-3")
            self.assertEqual(qa["parent_task_id"], coder["task_id"])
            self.assertEqual(qa["baseline_commit"], baseline)
            self.assertEqual(manager._tasks[qa["task_id"]]["worktree_key"], manager._tasks[coder["task_id"]]["worktree_key"])

    def test_changed_path_snapshot_handles_windows_git_status_bytes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "repo"
            manager = self.make_repo(root)
            task = manager._create_task("agent-1", "Changed path test", "coding", None, None)
            worktree, _ = manager._create_worktree(task)
            (worktree / "new file.txt").write_text("new\n", encoding="utf-8")
            self.assertEqual(_worktree_changes(worktree), ["new file.txt"])

    def test_task_diff_is_limited_to_changed_files_and_redacts_secrets(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "repo"
            manager = self.make_repo(root)
            task = manager._create_task("agent-1", "Secret diff test", "coding", None, None)
            worktree, _ = manager._create_worktree(task)
            (worktree / "source.txt").write_text("api_key=sk-abcdefghijklmnopqrstuvwxyz\n", encoding="utf-8")
            with manager._lock:
                manager._tasks[task["task_id"]]["changed_files"] = ["source.txt"]
            result = manager.task_diff(task["task_id"], "source.txt")
            self.assertIn("[redacted]", result["diff"])
            self.assertNotIn("abcdefghijklmnopqrstuvwxyz", result["diff"])
            with self.assertRaises(ValueError):
                manager.task_diff(task["task_id"], "../outside.txt")


if __name__ == "__main__":
    unittest.main()
