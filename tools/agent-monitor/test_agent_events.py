import json
import tempfile
import unittest
from pathlib import Path

import agent_events


class AgentEventTests(unittest.TestCase):
    def test_registry_preserves_five_assigned_roles(self):
        agents = agent_events.load_agents()
        self.assertEqual([agent["agent_id"] for agent in agents], ["agent-1", "agent-2", "agent-3", "agent-4", "agent-5"])
        self.assertEqual(agents[1]["role"], "Backend/API Developer")
        self.assertEqual(agents[4]["role"], "Customer/Admin Debugger")

    def test_metrics_use_only_recorded_run_events(self):
        agents = agent_events.load_agents()
        run_id = "11111111-2222-4333-8444-555555555555"
        events = [
            {"timestamp": "2026-10-16T10:00:00+00:00", "event": "started", "run_id": run_id,
             "agent_id": "agent-3", "task": "Run Flutter widget tests"},
            {"timestamp": "2026-10-16T10:01:00+00:00", "event": "verification", "run_id": run_id,
             "agent_id": "agent-3", "label": "Flutter tests", "passed": 10, "failed": 0},
            {"timestamp": "2026-10-16T10:02:00+00:00", "event": "finished", "run_id": run_id,
             "agent_id": "agent-3", "status": "completed", "files": ["test/widget_test.dart"]},
        ]

        result = agent_events.build_overview(agents, events)
        qa = next(item for item in result["roles"] if item["agent_id"] == "agent-3")
        self.assertEqual(qa["metrics"]["recorded_runs"], 1)
        self.assertEqual(qa["metrics"]["completion_rate_percent"], 100)
        self.assertEqual(qa["metrics"]["average_completion_seconds"], 120)
        self.assertEqual(qa["metrics"]["verification_passed"], 10)
        self.assertEqual(qa["metrics"]["verification_failed"], 0)
        self.assertEqual(qa["metrics"]["reported_changed_files"], 1)

    def test_unfinished_run_and_blocker_are_not_counted_as_completed(self):
        agents = agent_events.load_agents()
        run_id = "11111111-2222-4333-8444-555555555555"
        result = agent_events.build_overview(agents, [
            {"timestamp": "2026-10-16T10:00:00+00:00", "event": "started", "run_id": run_id,
             "agent_id": "agent-1", "task": "Implement dashboard UI"},
            {"timestamp": "2026-10-16T10:01:00+00:00", "event": "blocked", "run_id": run_id,
             "agent_id": "agent-1", "label": "Waiting for source data"},
        ])
        frontend = next(item for item in result["roles"] if item["agent_id"] == "agent-1")
        self.assertEqual(frontend["metrics"]["blocked"], 1)
        self.assertEqual(frontend["metrics"]["completed"], 0)
        self.assertEqual(result["runs"][0]["status"], "blocked")
        self.assertEqual(result["runs"][0]["events"][1]["event"], "blocked")
        self.assertEqual(result["runs"][0]["events"][1]["label"], "Waiting for source data")
        self.assertTrue(result["available"])

    def test_empty_event_ledger_reports_no_recorded_data(self):
        result = agent_events.build_overview(agent_events.load_agents(), [])
        self.assertFalse(result["available"])
        self.assertEqual(result["event_count"], 0)
        self.assertEqual(len(result["roles"]), 5)

    def test_malformed_finished_status_is_unknown_instead_of_crashing(self):
        agents = agent_events.load_agents()
        run_id = "11111111-2222-4333-8444-555555555555"
        result = agent_events.build_overview(agents, [
            {"timestamp": "2026-10-16T10:00:00+00:00", "event": "started", "run_id": run_id,
             "agent_id": "agent-1", "task": "Review data"},
            {"timestamp": "2026-10-16T10:01:00+00:00", "event": "finished", "run_id": run_id,
             "agent_id": "agent-1", "status": []},
        ])
        self.assertEqual(result["runs"][0]["status"], "unknown")

    def test_dot_file_path_is_rejected_without_traceback(self):
        with self.assertRaises(ValueError):
            agent_events._valid_files(["."])

    def test_labels_reject_secret_or_personal_contact_values(self):
        for value in ("reset user@example.com", "customer 09171234567", "password=private-value", "Bearer abc123"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                agent_events._label(value, "task label")

    def test_overview_withholds_unsafe_verification_labels_from_edited_ledger(self):
        agents = agent_events.load_agents()
        run_id = "11111111-2222-4333-8444-555555555555"
        result = agent_events.build_overview(agents, [
            {"timestamp": "2026-10-16T10:00:00+00:00", "event": "started", "run_id": run_id,
             "agent_id": "agent-3", "task": "Run monitor checks"},
            {"timestamp": "2026-10-16T10:01:00+00:00", "event": "verification", "run_id": run_id,
             "agent_id": "agent-3", "label": "password=privatevalue", "passed": 0, "failed": 1},
        ])
        encoded = json.dumps(result)
        self.assertNotIn("privatevalue", encoded)
        self.assertEqual(result["runs"][0]["checks"][0]["label"], "[withheld]")

    def test_event_file_round_trip_and_size_limit(self):
        event = {"timestamp": "2026-10-16T10:00:00+00:00", "event": "started",
                 "run_id": "11111111-2222-4333-8444-555555555555", "agent_id": "agent-1",
                 "task": "Style the dashboard"}
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "agent-events.jsonl"
            agent_events.append_event(event, path)
            self.assertEqual(agent_events.read_events(path), [event])
            path.write_bytes(b"0" * (agent_events.MAX_LOG_BYTES + 1))
            with self.assertRaises(ValueError):
                agent_events.read_events(path)


if __name__ == "__main__":
    unittest.main()
