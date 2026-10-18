const agentIds = ["agent-1", "agent-2", "agent-3", "agent-4", "agent-5"];
const deskPositions = [
  [250, 285], [390, 230], [535, 185], [590, 287], [610, 325],
  [306, 367], [455, 327], [510, 392],
];
const idlePositions = {
  "agent-1": [150, 270],
  "agent-2": [250, 349],
  "agent-3": [384, 438],
  "agent-4": [535, 367],
  "agent-5": [630, 269],
};
const agentNames = {
  "agent-1": "Agent 1 Frontend Developer",
  "agent-2": "Agent 2 Backend/API Developer",
  "agent-3": "Agent 3 QA Tester",
  "agent-4": "Agent 4 Code Reviewer",
  "agent-5": "Agent 5 Customer/Admin Debugger",
};
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
let latestCityData = {};

function transform(position) {
  return `translate(${position[0]} ${position[1]})`;
}

function stableIndex(value) {
  let hash = 0;
  for (const character of value) hash = (hash * 31 + character.charCodeAt(0)) >>> 0;
  return hash % deskPositions.length;
}

function activeDeskAssignments(latestByAgent) {
  const working = agentIds
    .filter((id) => ["preparing", "running", "active", "blocked"].includes(latestByAgent[id]?.status))
    .sort();
  const reserved = new Set();
  const assignments = {};
  for (const id of working) {
    const task = latestByAgent[id] || {};
    const key = `${id}:${task.task_id || task.started_at || task.task || task.label || "task"}`;
    const first = stableIndex(key);
    let chosen = first;
    for (let offset = 0; offset < deskPositions.length; offset += 1) {
      const candidate = (first + offset) % deskPositions.length;
      if (!reserved.has(candidate)) {
        chosen = candidate;
        break;
      }
    }
    reserved.add(chosen);
    assignments[id] = deskPositions[chosen];
  }
  return assignments;
}

function stateLabel(status, source) {
  if (status === "preparing") return "STARTING";
  if (status === "running") return source === "Codex CLI worker record" ? "WORKING · CODEX" : "WORKING";
  if (status === "active") return "ACTIVE · LOG";
  if (status === "blocked") return "BLOCKED";
  if (status === "completed") return "DONE";
  if (status === "failed") return "FAILED";
  if (status === "cancelled") return "CANCELLED";
  if (status === "timed_out") return "TIMED OUT";
  if (status === "interrupted") return "INTERRUPTED";
  return "AVAILABLE";
}

function updateOffice(latestByAgent = {}) {
  latestCityData = latestByAgent;
  const assignments = activeDeskAssignments(latestByAgent);
  for (const id of agentIds) {
    const group = document.getElementById(`pixel-agent-${id}`);
    if (!group) continue;
    const task = latestByAgent[id] || {};
    const status = task.status || "idle";
    const source = task.source || "No task recorded";
    const target = transform(assignments[id] || idlePositions[id]);
    const previousTarget = group.dataset.cityTarget || group.dataset.idleTransform;
    group.dataset.cityTarget = target;
    group.dataset.recordedStatus = status;
    group.dataset.source = source;

    if (target !== previousTarget) {
      if (group._cityMoveTimer) window.clearTimeout(group._cityMoveTimer);
      group.dataset.status = reduceMotion.matches ? status : "walking";
      group.setAttribute("transform", target);
      if (!reduceMotion.matches) {
        group._cityMoveTimer = window.setTimeout(() => {
          if (group.dataset.cityTarget === target) group.dataset.status = group.dataset.recordedStatus || "idle";
          group._cityMoveTimer = 0;
        }, 1050);
      }
    } else {
      group.dataset.status = status;
    }

    const state = stateLabel(status, source);
    group.setAttribute("aria-label", `${agentNames[id]}, ${state.toLowerCase()}, ${source}`);
    const statusText = group.querySelector(`#pixel-${id}-state`);
    if (statusText) statusText.textContent = state;
  }
}

document.addEventListener("monitor:city-data", (event) => updateOffice(event.detail?.latest_by_agent || {}));
document.addEventListener("monitor:city-visible", () => updateOffice(latestCityData));
reduceMotion.addEventListener?.("change", () => updateOffice(latestCityData));
