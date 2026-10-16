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

async function getJson(url) {
  const response = await fetch(url, { cache: "no-store" });
  const body = await response.json();
  if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
  return body;
}

function tabSetup() {
  document.querySelectorAll(".tab").forEach((button) => button.addEventListener("click", () => {
    document.querySelectorAll(".tab,.panel").forEach((node) => node.classList.remove("active"));
    button.classList.add("active");
    $(`panel-${button.dataset.tab}`).classList.add("active");
  }));
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
    overview = await getJson("/api/overview");
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
$("refresh").addEventListener("click", refresh);
refresh();
setInterval(refresh, 5000);
