const $ = (id) => document.getElementById(id);
const number = (value) => new Intl.NumberFormat().format(Number(value || 0));
const dateText = (value) => {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? value : date.toLocaleString();
};
const el = (tag, className, text) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
};
let overview = null;
let lastNotes = "";
let lastImages = "";
let lastFiles = "";
let attachmentUrl = "";
let cityTasks = null;
let citySelectedTask = "";

const CITY_AGENT_ROLES = [
  { id: "agent-1", name: "Agent 1 · Frontend Developer" },
  { id: "agent-2", name: "Agent 2 · Backend/API Developer" },
  { id: "agent-3", name: "Agent 3 · QA Tester" },
  { id: "agent-4", name: "Agent 4 · Code Reviewer" },
  { id: "agent-5", name: "Agent 5 · Customer/Admin Debugger" },
];
const DEBUG_TASK_LABEL = "Debug customer/admin login and registration";
const DEBUG_TASK_PROMPT = "Inspect the customer and admin sign-in and account-creation flows. Review the relevant code and existing checks. Use any redacted browser console/API error details I paste below as evidence. If no browser console output is included, state that you cannot see my live DevTools and do a code/test investigation instead. Fix a root cause only when supported by evidence, run relevant existing checks without installing dependencies, and report exact results and any manual browser verification I still need. Never use real customer accounts, credentials, or production data.\n\nConsole/API errors or reproduction details (optional):";

async function getJson(url) {
  const response = await fetch(url, { cache: "no-store" });
  const body = await response.json();
  if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
  return body;
}

async function postJson(url, value) {
  const response = await fetch(url, {
    method: "POST",
    cache: "no-store",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(value),
  });
  const body = await response.json();
  if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
  return body;
}

function tabSetup() {
  document.querySelectorAll(".tab").forEach((button) => button.addEventListener("click", () => {
    const currentTab = document.querySelector(".tab.active")?.dataset.tab;
    if (currentTab === "city" && button.dataset.tab !== "city") document.dispatchEvent(new CustomEvent("monitor:city-hidden"));
    document.querySelectorAll(".tab,.panel").forEach((node) => node.classList.remove("active"));
    button.classList.add("active");
    $(`panel-${button.dataset.tab}`).classList.add("active");
    if (button.dataset.tab === "city") document.dispatchEvent(new CustomEvent("monitor:city-visible"));
  }));
}

function cityActivityByAgent() {
  const timestamp = (value) => {
    const parsed = Date.parse(value || "");
    return Number.isFinite(parsed) ? parsed : 0;
  };
  const workerTasks = Array.isArray(cityTasks?.tasks) ? cityTasks.tasks : [];
  const workerLatest = {};
  [...workerTasks]
    .sort((a, b) => timestamp(b.created_at) - timestamp(a.created_at))
    .forEach((task) => {
      if (task.agent_id && !workerLatest[task.agent_id]) workerLatest[task.agent_id] = task;
    });

  const roleLatest = {};
  const roleRuns = Array.isArray(overview?.agents?.runs) ? overview.agents.runs : [];
  [...roleRuns]
    .sort((a, b) => timestamp(b.started_at) - timestamp(a.started_at))
    .forEach((run) => {
      if (run.agent_id && !roleLatest[run.agent_id]) roleLatest[run.agent_id] = run;
    });

  return Object.fromEntries(CITY_AGENT_ROLES.map(({ id }) => {
    const worker = workerLatest[id];
    const recorded = roleLatest[id];
    const workerIsLive = worker && ["preparing", "running", "blocked"].includes(worker.status);
    const recordedIsNewer = Boolean(recorded && (!worker || timestamp(recorded.started_at) > timestamp(worker.created_at)));
    const current = workerIsLive ? worker : recordedIsNewer ? recorded : worker || recorded;
    if (!current) return [id, { status: "idle", source: "No task recorded", task: "" }];
    return [id, {
      status: current.status || "unknown",
      source: current === worker ? "Codex CLI worker record" : "Explicit local role log",
      task: current.label || current.task || "Task label not recorded",
      started_at: current.started_at || current.created_at || "",
    }];
  }));
}

function renderCityAgentActivity(latestByAgent) {
  const list = $("city-agent-live-status");
  if (!list) return;
  list.replaceChildren();
  CITY_AGENT_ROLES.forEach((agent) => {
    const activity = latestByAgent[agent.id] || { status: "idle", source: "No task recorded", task: "" };
    const status = activity.status || "unknown";
    const isWorking = ["preparing", "running", "active"].includes(status);
    const isAtStation = isWorking || status === "blocked";
    const row = el("article", `city-agent-live-row ${status}`);
    const heading = el("div", "city-agent-live-heading");
    heading.append(el("b", "", agent.name), el("span", `city-state ${status}`, status));
    row.append(heading);
    row.append(el("span", "city-agent-location", `Location · ${isAtStation ? "Shared office desk" : "Office floor · available"}`));
    row.append(el("span", "city-agent-source", `Source · ${activity.source || "Source unavailable"}`));
    if (activity.task) row.append(el("span", "city-agent-task", `Task · ${activity.task}`));
    else row.append(el("span", "city-agent-task", "No active task recorded"));
    list.append(row);
  });
}

function renderCityTasks(data) {
  cityTasks = data && typeof data === "object" ? data : { tasks: [], codex: {} };
  const codex = cityTasks.codex || {};
  const availability = $("city-codex-status");
  const loginText = codex.authenticated ? "Authenticated" : codex.available ? "Login required" : "CLI unavailable";
  availability.className = `city-availability ${codex.authenticated ? "ready" : "unavailable"}`;
  availability.textContent = `${loginText}${codex.model ? ` · ${codex.model}` : ""}`;
  $("city-worker-note").textContent = codex.authenticated
    ? `${codex.version || "Codex CLI"} · ${codex.model_source === "user-configured model" ? "using configured model" : codex.model_source?.startsWith("catalog fallback") ? `configured model is unavailable; using ${codex.model}` : `using ${codex.model} from the authenticated CLI catalog`}. Workers run one at a time in isolated worktrees based on committed HEAD.`
    : codex.available
      ? "Run codex login in PowerShell, then refresh. No worker has been started."
      : "Codex CLI was not found on PATH. No worker has been started.";

  const tasks = Array.isArray(cityTasks.tasks) ? cityTasks.tasks : [];
  const selected = tasks.find((task) => task.task_id === citySelectedTask) || tasks[0];
  citySelectedTask = selected?.task_id || "";
  renderCityTaskList(tasks);
  renderCityTaskDetail(selected);
  refreshQaTargets(tasks);
  const latestByAgent = cityActivityByAgent();
  renderCityAgentActivity(latestByAgent);
  document.dispatchEvent(new CustomEvent("monitor:city-data", { detail: { tasks, latest_by_agent: latestByAgent } }));
}

function refreshQaTargets(tasks) {
  const select = $("city-qa-target");
  const prior = select.value;
  select.replaceChildren();
  const candidates = tasks.filter((task) => task.agent_id === "agent-1" && task.status === "completed");
  candidates.forEach((task) => {
    const option = document.createElement("option");
    option.value = task.task_id;
    option.textContent = `${task.label} · ${task.task_id.slice(0, 8)}`;
    select.append(option);
  });
  if (candidates.some((task) => task.task_id === prior)) select.value = prior;
  $("city-start-worker").disabled = !cityTasks?.codex?.authenticated || Boolean(cityTasks?.active_task) || ($("city-agent").value === "agent-3" && !candidates.length);
}

function renderCityTaskList(tasks) {
  const list = $("city-task-history");
  list.replaceChildren();
  if (!tasks.length) {
    list.append(el("p", "empty", "No Codex worker tasks have run yet. The live roster can still show explicit role-log activity; a role-log entry does not prove a Codex process is running."));
    return;
  }
  tasks.forEach((task) => {
    const row = el("article", `city-task-row${task.task_id === citySelectedTask ? " selected" : ""}`);
    const choose = el("button", "city-task-select");
    choose.type = "button";
    choose.append(el("b", "", task.label || "Task label unavailable"));
    choose.append(el("span", "city-task-meta", `${task.role || task.agent_id} · ${task.status} · ${dateText(task.created_at)}`));
    choose.addEventListener("click", () => { citySelectedTask = task.task_id; renderCityTasks(cityTasks); });
    row.append(choose);
    if (task.agent_id === "agent-1" && task.status === "completed") {
      const qa = el("button", "quiet-button city-qa-button", "Run QA worker");
      qa.type = "button";
      qa.addEventListener("click", () => {
        $("city-agent").value = "agent-3";
        refreshQaTargets(tasks);
        $("city-qa-target").value = task.task_id;
        updateWorkerForm();
        $("city-confirm").checked = false;
        $("city-worker-form").scrollIntoView({ behavior: "smooth", block: "center" });
      });
      row.append(qa);
    }
    list.append(row);
  });
}

function renderCityTaskDetail(task) {
  const box = $("city-task-detail");
  box.replaceChildren();
  if (!task) {
    box.append(el("p", "empty", "Select a task to inspect its recorded events, results, and changed files."));
    return;
  }
  const heading = el("div", "row-between");
  heading.append(el("h3", "", task.label || "Task"), el("span", `city-state ${task.status || "unknown"}`, task.status || "unknown"));
  box.append(heading);
  const meta = el("div", "city-detail-meta");
  meta.append(el("span", "", `${task.role || task.agent_id} · ${task.source || "worker source unavailable"}`));
  meta.append(el("span", "", `Created ${dateText(task.created_at)}`));
  if (task.finished_at) meta.append(el("span", "", `Finished ${dateText(task.finished_at)}`));
  if (task.baseline_commit) meta.append(el("span", "", `Isolated baseline ${task.baseline_commit}`));
  if (task.worktree) meta.append(el("span", "", `Worktree ${task.worktree}`));
  if (task.exit_code !== null && task.exit_code !== undefined) meta.append(el("span", "", `Exit code ${task.exit_code}`));
  box.append(meta);
  if (task.error) box.append(el("p", task.approval_required ? "city-approval-note" : "city-error-note", task.error));
  const events = Array.isArray(task.events) ? task.events.slice(-24).reverse() : [];
  const eventList = el("ol", "city-event-list");
  events.forEach((event) => {
    const item = el("li", `city-event ${event.category || "info"}`);
    item.append(el("time", "", dateText(event.timestamp)), el("span", "", `${event.label || "Recorded event"}${event.exit_code !== undefined ? ` · exit ${event.exit_code}` : ""}`));
    eventList.append(item);
  });
  if (events.length) box.append(eventList);
  const files = Array.isArray(task.changed_files) ? task.changed_files : [];
  box.append(el("h4", "", `Changed files observed (${files.length})`));
  if (!files.length) box.append(el("p", "fineprint", "No changed paths were observed in this isolated worktree."));
  files.forEach((path) => {
    const button = el("button", "city-path", path);
    button.type = "button";
    button.addEventListener("click", async () => {
      $("city-diff").textContent = "Loading redacted task diff…";
      try {
        const diff = await getJson(`/api/task-diff?task_id=${encodeURIComponent(task.task_id)}&path=${encodeURIComponent(path)}`);
        $("city-diff").textContent = diff.diff;
      } catch (error) { $("city-diff").textContent = error.message; }
    });
    box.append(button);
  });
  if (["preparing", "running"].includes(task.status) && cityTasks?.active_task?.task_id === task.task_id) {
    const cancel = el("button", "danger-button", "Cancel worker");
    cancel.type = "button";
    cancel.addEventListener("click", async () => {
      if (!window.confirm("Stop the active Codex process? Partial work remains in its isolated worktree.")) return;
      try { await postJson(`/api/tasks/${task.task_id}/cancel`, { confirm: true }); await refresh(); }
      catch (error) { $("city-request-error").textContent = error.message; }
    });
    box.append(cancel);
  }
}

function updateWorkerForm() {
  const qa = $("city-agent").value === "agent-3";
  const debug = $("city-agent").value === "agent-5";
  if (debug) {
    if (!$("city-task-label").value.trim()) $("city-task-label").value = DEBUG_TASK_LABEL;
    if (!$("city-task-prompt").value.trim()) $("city-task-prompt").value = DEBUG_TASK_PROMPT;
  } else {
    if ($("city-task-label").value === DEBUG_TASK_LABEL) $("city-task-label").value = "";
    if ($("city-task-prompt").value === DEBUG_TASK_PROMPT) $("city-task-prompt").value = "";
  }
  $("city-prompt-fields").classList.toggle("hidden", qa);
  $("city-qa-fields").classList.toggle("hidden", !qa);
  $("city-task-label").required = !qa;
  $("city-task-prompt").required = !qa;
  $("city-qa-target").required = qa;
  $("city-worker-form-title").textContent = qa ? "Run the QA Tester" : debug ? "Start the debugging worker" : "Start the coding worker";
  $("city-start-worker").textContent = qa ? "Start QA worker" : debug ? "Start Agent 5" : "Start Agent 1";
  $("city-task-prompt-label").textContent = debug ? "Issue details and optional redacted console output for Agent 5" : "Instructions for Agent 1";
  $("city-task-prompt").placeholder = debug
    ? "Describe the customer/admin sign-in or account-creation failure. Paste relevant browser console/API errors after removing passwords, tokens, emails, and customer data. Without pasted logs, Agent 5 can inspect code and existing checks but cannot see your browser console."
    : "Describe the focused change. Do not include passwords, tokens, or customer data.";
  $("city-debug-limit").classList.toggle("hidden", !debug);
  refreshQaTargets(cityTasks?.tasks || []);
}

function setupCityControls() {
  $("city-agent").addEventListener("change", updateWorkerForm);
  $("city-worker-form").addEventListener("submit", async (event) => {
    event.preventDefault();
    $("city-request-error").textContent = "";
    if (!$("city-confirm").checked) {
      $("city-request-error").textContent = "Confirm the isolated worker notice before starting.";
      return;
    }
    $("city-start-worker").disabled = true;
    try {
      if ($("city-agent").value === "agent-3") {
        const target = $("city-qa-target").value;
        if (!target) throw new Error("Select a completed Agent 1 task for QA.");
        const task = await postJson(`/api/tasks/${target}/qa`, { confirm: true });
        citySelectedTask = task.task_id;
      } else {
        const task = await postJson("/api/tasks", {
          agent_id: $("city-agent").value,
          label: $("city-task-label").value,
          prompt: $("city-task-prompt").value,
          confirm: true,
        });
        citySelectedTask = task.task_id;
        $("city-worker-form").reset();
      }
      $("city-confirm").checked = false;
      await refresh();
    } catch (error) {
      $("city-request-error").textContent = error.message;
      await loadCityTasks();
    } finally {
      updateWorkerForm();
    }
  });
}

async function loadCityTasks() {
  const data = await getJson("/api/tasks");
  renderCityTasks(data);
}

function renderSessions(sessions) {
  const container = $("sessions");
  container.replaceChildren();
  if (!sessions.length) {
    container.append(el("p", "empty", "No local Codex session JSONL records were found. The monitor will still show Git and project previews."));
    return;
  }
  sessions.slice(0, 5).forEach((session) => {
    const card = el("div", "session");
    const top = el("div", "session-top");
    top.append(el("span", "session-id", `Codex · ${session.session_id}`));
    const status = el("span", `status${session.status === "Idle" ? " idle" : session.status === "Interrupted" ? " interrupted" : ""}`, session.status);
    top.append(status);
    card.append(top);
    const meta = el("div", "session-meta");
    meta.append(el("span", "", `Updated ${dateText(session.modified_at)}`));
    meta.append(el("span", "", `Tasks ${session.task_completed}/${session.task_started} completed`));
    if (session.cli_version) meta.append(el("span", "", `Codex ${session.cli_version}`));
    card.append(meta);
    card.append(el("div", "fineprint", session.source_label));
    container.append(card);
  });
}

function renderProcesses(snapshot) {
  const container = $("codex-processes");
  container.replaceChildren();
  if (!snapshot || snapshot.available !== true) {
    container.append(el("p", "empty process-empty", "OS process snapshot unavailable. The monitor could not verify whether a Codex process is running."));
    return;
  }

  const source = typeof snapshot.source === "string" && snapshot.source.trim() ? snapshot.source : "OS process snapshot";
  container.append(el("p", "process-observation fineprint", `Source: ${source} · Observed ${dateText(snapshot.observed_at)}`));

  const processes = Array.isArray(snapshot.processes) ? snapshot.processes : [];
  if (!processes.length) {
    container.append(el("p", "empty process-empty", "No Codex processes were found in this OS snapshot."));
    return;
  }

  const list = el("div", "process-items");
  processes.forEach((process) => {
    const item = el("div", "process-item");
    const name = typeof process?.name === "string" && process.name.trim() ? process.name : "Unnamed process";
    item.append(el("b", "process-name", name));
    const details = el("div", "process-meta");
    details.append(
      el("span", "", `PID ${process?.pid ?? "—"}`),
      el("span", "", `Parent PID ${process?.parent_pid ?? "—"}`),
      el("span", "", `Started ${dateText(process?.started_at)}`),
    );
    item.append(details);
    list.append(item);
  });
  container.append(list);
}

function renderTasks(sessions) {
  const container = $("tasks");
  container.replaceChildren();
  const tasks = sessions.flatMap((session) => session.tasks.map((task) => ({ ...task, session: session.session_id })))
    .sort((a, b) => new Date(b.started_at) - new Date(a.started_at)).slice(0, 24);
  if (!tasks.length) return container.append(el("p", "empty", "No task markers are available."));
  tasks.forEach((task) => {
    const row = el("div", "task");
    row.append(el("b", "", `Task ${task.number} · ${task.session}`));
    const state = el("span", `task-state ${task.status}`, task.status);
    row.append(state);
    container.append(row);
  });
}

function renderUsage(sessions) {
  const container = $("usage");
  container.replaceChildren();
  const session = sessions.find((item) => Object.keys(item.usage || {}).length);
  const usage = session?.usage || {};
  const fields = [
    ["input_tokens", "Input tokens"], ["cached_input_tokens", "Cached input"],
    ["output_tokens", "Output tokens"], ["reasoning_output_tokens", "Reasoning output"],
    ["total_tokens", "Thread total"],
  ].filter(([key]) => usage[key] !== undefined);
  if (!fields.length) return container.append(el("p", "empty", "No reliable token-usage record is available."));
  fields.forEach(([key, label]) => {
    const item = el("div", "usage");
    item.append(el("b", "", number(usage[key])));
    item.append(el("span", "", label));
    container.append(item);
  });
  $("usage").dataset.session = session.session_id;
}

function metricText(value) {
  if (value === null || value === undefined || value === "") return "—";
  const numeric = Number(value);
  return Number.isFinite(numeric) ? number(numeric) : "—";
}

function durationText(value) {
  if (value === null || value === undefined || value === "") return "—";
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds < 0) return "—";
  if (seconds < 60) return String(Math.round(seconds)) + " sec";
  const minutes = Math.floor(seconds / 60);
  const remainder = Math.round(seconds % 60);
  return remainder ? minutes + " min " + remainder + " sec" : minutes + " min";
}

function statusClass(status) {
  return ["active", "blocked", "completed", "failed"].includes(status) ? status : "unknown";
}

function runCheckSummary(checks) {
  return (Array.isArray(checks) ? checks : []).reduce((sum, check) => {
    sum.passed += Number(check?.passed) || 0;
    sum.failed += Number(check?.failed) || 0;
    return sum;
  }, { passed: 0, failed: 0 });
}

function renderAgentRuns(runs) {
  const container = $("agent-runs");
  container.replaceChildren();
  const items = Array.isArray(runs) ? runs : [];
  if (!items.length) {
    container.append(el("p", "empty", "No named-agent task runs have been recorded yet. Start and finish work through the local agent event logger to create history."));
    return;
  }
  items.slice(0, 20).forEach((run) => {
    const card = el("article", "agent-run");
    const heading = el("div", "agent-run-heading");
    const identity = el("div", "agent-run-identity");
    identity.append(el("b", "", run.name || run.agent_id || "Agent name unavailable"));
    identity.append(el("span", "agent-run-role", run.role || "Role not set"));
    heading.append(identity, el("span", "agent-run-status " + statusClass(run.status), run.status || "Status not recorded"));
    card.append(heading);

    card.append(el("p", "agent-run-task", run.task || "Task label not recorded"));
    const meta = el("div", "agent-run-meta");
    meta.append(el("span", "", "Started " + dateText(run.started_at)));
    if (run.finished_at) meta.append(el("span", "", "Finished " + dateText(run.finished_at)));
    meta.append(el("span", "", "Duration " + durationText(run.duration_seconds)));
    meta.append(el("span", "", "Blockers " + metricText(run.blocker_count)));
    card.append(meta);

    const checks = Array.isArray(run.checks) ? run.checks : [];
    const totals = runCheckSummary(checks);
    const checksBox = el("div", "agent-run-checks");
    checksBox.append(el("b", "", "Verification: " + number(totals.passed) + " passed · " + number(totals.failed) + " failed"));
    if (checks.length) {
      const list = el("ul", "agent-check-list");
      checks.forEach((check) => {
        const item = el("li", "");
        item.append(el("span", "", check.label || "Check label not recorded"));
        item.append(el("span", "", metricText(check.passed) + " passed · " + metricText(check.failed) + " failed"));
        list.append(item);
      });
      checksBox.append(list);
    } else {
      checksBox.append(el("span", "fineprint", "No verification checks recorded."));
    }
    card.append(checksBox);

    const events = Array.isArray(run.events) ? run.events.slice(-20) : [];
    const activity = el("div", "agent-run-events");
    activity.append(el("b", "", "Recorded activity (" + number(events.length) + ")"));
    if (events.length) {
      const list = el("ol", "agent-event-list");
      events.forEach((event) => {
        const item = el("li", "agent-event");
        const type = ({ started: "Started", blocked: "Blocker", verification: "Verification", finished: "Finished" })[event.event] || "Recorded event";
        item.append(el("time", "agent-event-time", dateText(event.timestamp)));
        const description = [type, event.label, event.status].filter(Boolean).join(" · ");
        item.append(el("span", "", description));
        list.append(item);
      });
      activity.append(list);
    } else {
      activity.append(el("span", "fineprint", "No activity events recorded."));
    }
    card.append(activity);

    const files = Array.isArray(run.files) ? run.files : [];
    const changed = el("div", "agent-run-files");
    changed.append(el("b", "", "Changed paths (" + number(files.length) + ")"));
    if (files.length) {
      const list = el("ul", "agent-path-list");
      files.forEach((path) => list.append(el("li", "", path)));
      changed.append(list);
    } else {
      changed.append(el("span", "fineprint", "No changed paths recorded."));
    }
    card.append(changed);
    container.append(card);
  });
}

function renderAgents(agentData) {
  const data = agentData && typeof agentData === "object" ? agentData : {};
  const roles = Array.isArray(data.roles) ? data.roles : [];
  const runs = Array.isArray(data.runs) ? data.runs : [];
  const available = data.available === true;
  const source = data.source || (agentData ? "Source label not provided" : "Agent records are not exposed in this overview response.");
  const sourceBox = $("agents-source");
  sourceBox.replaceChildren();
  const sourceStatus = available ? "Recorded run data available" : data.error ? "Agent ledger unavailable" : "No runs recorded yet";
  sourceBox.append(el("span", "agents-availability" + (available ? " available" : " unavailable"), sourceStatus));
  sourceBox.append(el("span", "agents-source-text", "Source: " + source));
  if (!available && data.error) {
    sourceBox.append(el("p", "fineprint", "The role definitions may still be listed below, but the local event log could not be read safely."));
  } else if (!available) {
    sourceBox.append(el("p", "fineprint", "The role definitions are configured. Counts stay at zero until task runs are recorded with the local event logger."));
  }

  const roleGrid = $("agent-role-grid");
  roleGrid.replaceChildren();
  if (!roles.length) {
    roleGrid.append(el("p", "empty agent-empty", "No named agent roles are configured in the returned data."));
  }
  roles.forEach((agent) => {
    const card = el("article", "card agent-role-card");
    const heading = el("div", "card-heading agent-role-heading");
    const identity = el("div", "");
    identity.append(el("p", "eyebrow", agent.agent_id || "AGENT"));
    identity.append(el("h2", "", agent.name || "Agent name unavailable"));
    identity.append(el("p", "agent-role-name", agent.role || "Role not set"));
    const metrics = agent.metrics && typeof agent.metrics === "object" ? agent.metrics : {};
    const active = Number(metrics.active) || 0;
    const blocked = Number(metrics.blocked) || 0;
    const state = active > 0 ? metricText(metrics.active) + " active record" + (active === 1 ? "" : "s")
      : blocked > 0 ? metricText(metrics.blocked) + " blocked record" + (blocked === 1 ? "" : "s")
        : "No active run recorded";
    heading.append(identity, el("span", "agent-role-state" + (active > 0 ? " active" : blocked > 0 ? " blocked" : ""), state));
    card.append(heading);

    const grid = el("div", "agent-metrics");
    const rate = metrics.completion_rate_percent === null || metrics.completion_rate_percent === undefined ? "—" : metricText(metrics.completion_rate_percent) + "%";
    const entries = [
      ["Recorded runs", metricText(metrics.recorded_runs)],
      ["Completed", metricText(metrics.completed)],
      ["Active", metricText(metrics.active)],
      ["Blocked", metricText(metrics.blocked)],
      ["Failed", metricText(metrics.failed)],
      ["Completion rate", rate],
      ["Average completion", durationText(metrics.average_completion_seconds)],
      ["Checks passed / failed", metricText(metrics.verification_passed) + " / " + metricText(metrics.verification_failed)],
      ["Reported changed files", metricText(metrics.reported_changed_files)]
    ];
    entries.forEach(([label, value]) => {
      const item = el("div", "agent-metric");
      item.append(el("span", "", label), el("b", "", value));
      grid.append(item);
    });
    card.append(grid);
    roleGrid.append(card);
  });
  const eventCount = metricText(data.event_count);
  $("agent-event-count").textContent = eventCount + " recorded event" + (Number(data.event_count) === 1 ? "" : "s");
  renderAgentRuns(runs);
}

function renderGit(git) {
  $("branch").textContent = git.branch || "Git unavailable";
  const box = $("git-summary");
  box.replaceChildren();
  const data = [
    [number(git.changed_count || 0), "Changed files"],
    [git.upstream || "No upstream", "Tracking branch"],
    [git.divergence ? `${git.divergence.ahead} ahead · ${git.divergence.behind} behind` : "Not verified", "Local remote status"],
    [(git.remotes_configured || []).join(", ") || "No remote", "Configured remotes"],
  ];
  data.forEach(([value, label]) => {
    const item = el("div", "mini");
    item.append(el("b", "", value));
    item.append(el("span", "", label));
    box.append(item);
  });
}

function renderFiles(files) {
  const signature = JSON.stringify(files.map(({ path, state }) => [path, state]));
  if (signature === lastFiles) return;
  lastFiles = signature;
  const list = $("file-list");
  list.replaceChildren();
  $("change-count").textContent = `${files.length} file${files.length === 1 ? "" : "s"}`;
  if (!files.length) return list.append(el("p", "empty", "Working tree is clean."));
  files.forEach((file) => {
    const button = el("button", "file-button");
    button.type = "button";
    button.append(el("span", "file-state", file.state));
    button.append(document.createTextNode(file.path));
    button.addEventListener("click", async () => {
      list.querySelectorAll(".file-button").forEach((node) => node.classList.remove("active"));
      button.classList.add("active");
      $("diff").textContent = "Loading redacted Git diff…";
      try {
        const result = await getJson(`/api/diff?path=${encodeURIComponent(file.path)}`);
        $("diff").textContent = result.diff;
      } catch (error) { $("diff").textContent = error.message; }
    });
    list.append(button);
  });
}

function renderEvents(sessions) {
  const timeline = $("timeline");
  timeline.replaceChildren();
  const events = sessions.flatMap((session) => session.events.map((event) => ({ ...event, session: session.session_id })))
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)).slice(0, 180);
  if (!events.length) timeline.append(el("p", "empty", "No event records are available."));
  events.forEach((event) => {
    const row = el("div", "event");
    row.append(el("span", "event-time", dateText(event.timestamp)));
    row.append(el("span", "event-category", event.category));
    row.append(el("span", "", `${event.label}${event.detail ? ` · ${event.detail}` : ""} · ${event.session}`));
    timeline.append(row);
  });
  const errors = $("errors");
  errors.replaceChildren();
  const allErrors = sessions.flatMap((session) => session.errors.map((item) => ({ ...item, session: session.session_id })))
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)).slice(0, 30);
  if (!allErrors.length) errors.append(el("p", "empty", "No recorded command failures or interrupted turns."));
  allErrors.forEach((item) => {
    const row = el("div", "error-item");
    row.textContent = `${dateText(item.timestamp)} · ${item.label} · ${item.session}`;
    errors.append(row);
  });
}

function renderNotes(notes) {
  const select = $("note-select");
  const signature = JSON.stringify(notes);
  if (signature === lastNotes) return;
  lastNotes = signature;
  const previous = select.value;
  select.replaceChildren();
  notes.forEach((path) => {
    const option = el("option", "", path);
    option.value = path;
    select.append(option);
  });
  if (notes.includes(previous)) select.value = previous;
  select.onchange = loadNote;
  if (notes.length) loadNote();
  else $("note-preview").textContent = "No selected notes are available.";
}

async function loadNote() {
  const path = $("note-select").value;
  if (!path) return;
  $("note-preview").textContent = "Loading note…";
  try {
    const note = await getJson(`/api/note?path=${encodeURIComponent(path)}`);
    $("note-preview").textContent = note.content;
  } catch (error) { $("note-preview").textContent = error.message; }
}

function renderImages(images) {
  const signature = JSON.stringify(images.map((image) => image.path));
  if (signature === lastImages) return;
  lastImages = signature;
  const grid = $("image-grid");
  grid.replaceChildren();
  if (!images.length) return grid.append(el("p", "empty", "No project images were found in the allowed asset folders."));
  images.forEach((image) => {
    const figure = el("figure", "image-tile");
    const preview = document.createElement("img");
    preview.loading = "lazy";
    preview.alt = image.path;
    preview.src = `/api/image?path=${encodeURIComponent(image.path)}`;
    figure.append(preview, el("figcaption", "", image.path));
    grid.append(figure);
  });
}

async function refresh() {
  $("error").classList.add("hidden");
  try {
    const results = await Promise.all([getJson("/api/overview"), getJson("/api/tasks")]);
    overview = results[0];
    $("updated").textContent = `Updated ${new Date(overview.updated_at).toLocaleTimeString()}`;
    const activeSession = overview.sessions[0];
    const cards = [
      [overview.sessions.length, "Local sessions", "Latest available records"],
      [activeSession?.status || "No records", "Latest session", activeSession ? `Observed ${dateText(activeSession.modified_at)}` : "Codex log folder not found"],
      [overview.git.changed_count || 0, "Worktree changes", overview.git.branch || "Git unavailable"],
      [overview.git.divergence ? `${overview.git.divergence.ahead}/${overview.git.divergence.behind}` : "—", "Ahead / behind", "Cached remote refs only"],
    ];
    const summary = $("summary");
    summary.replaceChildren();
    cards.forEach(([value, label, sub]) => {
      const card = el("div", "stat");
      card.append(el("div", "stat-label", label), el("div", "stat-value", value), el("div", "stat-sub", sub));
      summary.append(card);
    });
    renderProcesses(overview.codex_processes);
    renderSessions(overview.sessions);
    renderTasks(overview.sessions);
    renderUsage(overview.sessions);
    renderGit(overview.git);
    renderFiles(overview.git.files || []);
    renderEvents(overview.sessions);
    renderNotes(overview.notes);
    renderImages(overview.images);
    renderAgents(overview.agents);
    renderCityTasks(results[1]);
    const limits = $("limits");
    limits.replaceChildren();
    overview.limits.forEach((line) => limits.append(el("li", "", line)));
  } catch (error) {
    $("error").textContent = `Could not load dashboard data: ${error.message}`;
    $("error").classList.remove("hidden");
  }
}

$("attachment-file").addEventListener("change", async (event) => {
  const file = event.target.files?.[0];
  const preview = $("attachment-preview");
  preview.replaceChildren();
  if (attachmentUrl) URL.revokeObjectURL(attachmentUrl);
  attachmentUrl = "";
  if (!file) return;
  preview.append(el("div", "fineprint", `Selected locally: ${file.name} · ${number(file.size)} bytes`));
  const isImage = file.type.startsWith("image/") || /\.(png|jpe?g|webp|gif|bmp)$/i.test(file.name);
  if (isImage) {
    if (file.size > 20_000_000) {
      preview.append(el("div", "error", "Image preview is limited to 20 MB."));
      return;
    }
    attachmentUrl = URL.createObjectURL(file);
    const image = document.createElement("img");
    image.alt = file.name;
    image.src = attachmentUrl;
    preview.append(image);
    return;
  }
  if (file.name.toLowerCase().endsWith(".md") || file.type === "text/markdown") {
    if (file.size > 1_000_000) {
      preview.append(el("div", "error", "Markdown preview is limited to 1 MB."));
      return;
    }
    const text = await file.text();
    const content = el("pre", "markdown-preview");
    content.textContent = text;
    preview.append(content);
    return;
  }
  preview.append(el("div", "error", "Choose an image or Markdown file."));
});

tabSetup();
setupCityControls();
updateWorkerForm();
$("refresh").addEventListener("click", refresh);
refresh();
setInterval(refresh, 5000);
