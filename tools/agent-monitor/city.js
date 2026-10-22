/*
 * BurgerBites Agent City — interactive 2D office simulation.
 *
 * The office is a data-driven tile map (rooms, walls, doors, hallways, desks,
 * furniture). Agents are independent objects that plan routes with A* over the
 * walkable tiles, reserve tiles so they never overlap, and animate while they
 * walk, work, or wait. Rendering uses a <canvas> with zoom, pan, minimap, and
 * screen-space labels. The simulation core has no DOM dependency so it can be
 * exercised headlessly by `node --test tools/agent-monitor/test_city_sim.cjs`.
 *
 * Agent destinations come only from recorded task state supplied by app.js
 * (Codex worker records and explicit role logs). Nothing here invents task
 * progress; idle agents simply patrol the office.
 */
(function () {
  "use strict";

  const TILE = 24;
  const COLS = 44;
  const ROWS = 30;
  const FLOOR = 0;
  const WALL = 1;
  const FURNITURE = 2;
  const DOOR = 3;
  const SQRT2 = Math.SQRT2;
  const WALK_SPEED_TILES = 3.1;
  const REPLAN_AFTER_SECONDS = 0.6;
  const GIVE_UP_AFTER_SECONDS = 3.2;

  // ---------------------------------------------------------------------------
  // Office layout data
  // ---------------------------------------------------------------------------

  const ROOM_DEFS = [
    { id: "frontend", name: "Frontend Room", short: "FRONTEND ROOM", subtitle: "UI Studio Desk · Agent 1", x: 1, y: 1, w: 13, h: 11, floor: "#fbe7dc", floorAlt: "#f6dccd", accent: "#ff642e" },
    { id: "command", name: "Command Center", short: "COMMAND CENTER", subtitle: "Briefings & completed-task reports", x: 15, y: 1, w: 14, h: 11, floor: "#e4ede2", floorAlt: "#d9e5d6", accent: "#3f7a69" },
    { id: "backend", name: "Backend Room", short: "BACKEND ROOM", subtitle: "API & SQL Console · Agent 2", x: 30, y: 1, w: 13, h: 11, floor: "#e1ebf7", floorAlt: "#d4e2f2", accent: "#4d9de0" },
    { id: "hallway", name: "Main Hallway", short: "MAIN HALLWAY", subtitle: "Connects every room", x: 1, y: 13, w: 42, h: 4, floor: "#efe5d1", floorAlt: "#e5d8bf", accent: "#a88d62", hallway: true },
    { id: "lounge", name: "Coffee & Bites Lounge", short: "COFFEE & BITES", subtitle: "Break area", x: 8, y: 13, w: 6, h: 4, floor: "#f3dcc3", floorAlt: "#eccfb1", accent: "#b86b35", overlay: true },
    { id: "qa", name: "QA Testing Room", short: "QA TESTING ROOM", subtitle: "Verification Lab · Agent 3", x: 1, y: 18, w: 9, h: 11, floor: "#def3e9", floorAlt: "#d0ecdf", accent: "#2fb386" },
    { id: "review", name: "Code Review Room", short: "CODE REVIEW ROOM", subtitle: "Diff Desk · Agent 4", x: 11, y: 18, w: 10, h: 11, floor: "#ece5f8", floorAlt: "#e2d8f3", accent: "#845ec2" },
    { id: "security", name: "Security Vault", short: "SECURITY VAULT", subtitle: "Cyber Shield Vault · Agent 6", x: 22, y: 18, w: 10, h: 11, floor: "#fce7ec", floorAlt: "#f7d6df", accent: "#e11d48" },
    { id: "debug", name: "Debugging Room", short: "DEBUGGING ROOM", subtitle: "Auth Diagnostics Bay · Agent 5", x: 33, y: 18, w: 10, h: 11, floor: "#fbe6db", floorAlt: "#f5d8c9", accent: "#e95d35" },
  ];

  const DOOR_DEFS = [
    { id: "door-frontend", label: "FRONTEND", tiles: [[6, 12], [7, 12]], orientation: "h" },
    { id: "door-command", label: "COMMAND", tiles: [[21, 12], [22, 12]], orientation: "h" },
    { id: "door-backend", label: "BACKEND", tiles: [[35, 12], [36, 12]], orientation: "h" },
    { id: "door-qa", label: "QA LAB", tiles: [[5, 17], [6, 17]], orientation: "h" },
    { id: "door-review", label: "REVIEW", tiles: [[15, 17], [16, 17]], orientation: "h" },
    { id: "door-security", label: "SECURITY", tiles: [[26, 17], [27, 17]], orientation: "h" },
    { id: "door-debug", label: "DEBUG", tiles: [[37, 17], [38, 17]], orientation: "h" },
    { id: "door-frontend-command", label: "", tiles: [[14, 6], [14, 7]], orientation: "v" },
    { id: "door-qa-review", label: "", tiles: [[10, 23], [10, 24]], orientation: "v" },
    { id: "door-review-security", label: "", tiles: [[21, 23], [21, 24]], orientation: "v" },
    { id: "door-security-debug", label: "", tiles: [[32, 23], [32, 24]], orientation: "v" },
  ];

  const FURNITURE_DEFS = [
    // Frontend Room
    { type: "desk", x: 2, y: 3, w: 3, h: 1, screen: "#5ce1e6" },
    { type: "desk", x: 6, y: 3, w: 3, h: 1, screen: "#5ce1e6" },
    { type: "desk", x: 10, y: 3, w: 3, h: 1, screen: "#5ce1e6" },
    { type: "desk", x: 2, y: 7, w: 3, h: 1, screen: "#ffb38f" },
    { type: "desk", x: 9, y: 7, w: 3, h: 1, screen: "#ffb38f" },
    { type: "plant", x: 1, y: 1, w: 1, h: 1 },
    { type: "plant", x: 13, y: 1, w: 1, h: 1 },
    // Command Center
    { type: "commandTable", x: 18, y: 4, w: 8, h: 3 },
    { type: "plant", x: 15, y: 1, w: 1, h: 1 },
    { type: "plant", x: 28, y: 1, w: 1, h: 1 },
    // Backend Room
    { type: "rack", x: 31, y: 1, w: 4, h: 1 },
    { type: "rack", x: 38, y: 1, w: 4, h: 1 },
    { type: "desk", x: 31, y: 5, w: 3, h: 1, screen: "#79d5bd" },
    { type: "desk", x: 37, y: 5, w: 3, h: 1, screen: "#79d5bd" },
    { type: "desk", x: 31, y: 8, w: 3, h: 1, screen: "#9cc8f2" },
    { type: "plant", x: 42, y: 11, w: 1, h: 1 },
    // Hallway + lounge
    { type: "counter", x: 9, y: 13, w: 4, h: 1 },
    { type: "sofa", x: 9, y: 16, w: 4, h: 1 },
    { type: "plant", x: 1, y: 13, w: 1, h: 1 },
    { type: "plant", x: 42, y: 13, w: 1, h: 1 },
    { type: "plant", x: 1, y: 16, w: 1, h: 1 },
    { type: "plant", x: 42, y: 16, w: 1, h: 1 },
    // QA Testing Room
    { type: "desk", x: 2, y: 21, w: 3, h: 1, screen: "#80ffdb" },
    { type: "bench", x: 6, y: 21, w: 3, h: 1, screen: "#80ffdb" },
    { type: "rack", x: 2, y: 28, w: 4, h: 1 },
    { type: "plant", x: 8, y: 28, w: 1, h: 1 },
    // Code Review Room
    { type: "desk", x: 12, y: 21, w: 3, h: 1, screen: "#c9b2ff" },
    { type: "desk", x: 17, y: 21, w: 3, h: 1, screen: "#c9b2ff" },
    { type: "shelf", x: 13, y: 28, w: 4, h: 1 },
    { type: "plant", x: 11, y: 18, w: 1, h: 1 },
    // Security Vault (Agent 6)
    { type: "console", x: 23, y: 21, w: 3, h: 1, screen: "#38bdf8" },
    { type: "desk", x: 28, y: 21, w: 3, h: 1, screen: "#fb7185" },
    { type: "rack", x: 23, y: 28, w: 4, h: 1 },
    { type: "plant", x: 31, y: 28, w: 1, h: 1 },
    // Debugging Room
    { type: "desk", x: 34, y: 21, w: 3, h: 1, screen: "#ffbd59" },
    { type: "console", x: 39, y: 21, w: 3, h: 1, screen: "#ff8a5c" },
    { type: "rack", x: 34, y: 28, w: 4, h: 1 },
    { type: "plant", x: 42, y: 18, w: 1, h: 1 },
  ];

  // Seats sit directly south of a desk; agents face up (toward the screen) while working.
  const SEAT_DEFS = [
    { id: "frontend-1", room: "frontend", x: 3, y: 4, owner: "agent-1" },
    { id: "frontend-2", room: "frontend", x: 7, y: 4 },
    { id: "frontend-3", room: "frontend", x: 11, y: 4 },
    { id: "frontend-4", room: "frontend", x: 3, y: 8 },
    { id: "frontend-5", room: "frontend", x: 10, y: 8 },
    { id: "command-1", room: "command", x: 19, y: 7 },
    { id: "command-2", room: "command", x: 21, y: 7 },
    { id: "command-3", room: "command", x: 23, y: 7 },
    { id: "command-4", room: "command", x: 25, y: 7 },
    { id: "backend-1", room: "backend", x: 32, y: 6, owner: "agent-2" },
    { id: "backend-2", room: "backend", x: 38, y: 6 },
    { id: "backend-3", room: "backend", x: 32, y: 9 },
    { id: "qa-1", room: "qa", x: 3, y: 22, owner: "agent-3" },
    { id: "qa-2", room: "qa", x: 7, y: 22 },
    { id: "review-1", room: "review", x: 13, y: 22, owner: "agent-4" },
    { id: "review-2", room: "review", x: 18, y: 22 },
    { id: "security-1", room: "security", x: 24, y: 22, owner: "agent-6" },
    { id: "security-2", room: "security", x: 29, y: 22 },
    { id: "debug-1", room: "debug", x: 35, y: 22, owner: "agent-5" },
    { id: "debug-2", room: "debug", x: 40, y: 22 },
  ];

  // Idle "points of interest" where patrolling agents pause.
  const POI_DEFS = {
    frontend: [[6, 9], [12, 10], [7, 1], [3, 10]],
    command: [[16, 10], [27, 10], [27, 3], [16, 3]],
    backend: [[36, 3], [41, 8], [36, 9], [40, 10]],
    hallway: [[17, 14], [28, 15], [39, 14], [3, 15]],
    lounge: [[10, 14], [12, 15], [8, 15], [13, 14]],
    qa: [[5, 25], [8, 19], [2, 25], [5, 20]],
    review: [[15, 25], [19, 25], [15, 19], [12, 25]],
    security: [[26, 25], [30, 25], [26, 19], [23, 25]],
    debug: [[37, 25], [41, 25], [37, 19], [34, 25]],
  };

  // Wall decorations drawn on the south-facing wall faces.
  const DECOR_DEFS = [
    { type: "board", x: 3, y: 0, w: 6, label: "FIGMA UI WALL", color: "#ff642e" },
    { type: "screen", x: 18, y: 0, w: 8, label: "TASK BOARD", color: "#3f7a69" },
    { type: "board", x: 35, y: 0, w: 3, label: "API", color: "#4d9de0" },
    { type: "board", x: 1, y: 17, w: 3, label: "QA TESTS", color: "#2fb386" },
    { type: "screen", x: 17, y: 17, w: 3, label: "DIFF VIEW", color: "#845ec2" },
    { type: "screen", x: 28, y: 17, w: 3, label: "SHIELD", color: "#e11d48" },
    { type: "screen", x: 39, y: 17, w: 3, label: "AUTH LOGS", color: "#e95d35" },
  ];

  const AGENT_DEFS = [
    {
      id: "agent-1", label: "AGENT 1 · FRONTEND", name: "Agent 1 Frontend Developer", homeRoom: "frontend",
      accent: "#ff642e", shirt: "#ff642e", shirtDark: "#d9481a", pants: "#2c3a47", shoes: "#ff642e", skin: "#f3c79c", hair: "#3b2621",
      gear: "headphones", gearColor: "#5ce1e6", start: [6, 9],
      itinerary: ["frontend", "lounge", "command", "review", "hallway"],
    },
    {
      id: "agent-2", label: "AGENT 2 · API LOG ONLY", name: "Agent 2 Backend/API Developer", homeRoom: "backend",
      accent: "#4d9de0", shirt: "#3b6ea5", shirtDark: "#253b52", pants: "#2e3b4e", shoes: "#1c2530", skin: "#deb896", hair: "#3a2f2d",
      gear: "glasses", gearColor: "#1e2a38", start: [36, 9],
      itinerary: ["backend", "command", "lounge", "security", "hallway"],
    },
    {
      id: "agent-3", label: "AGENT 3 · QA TESTER", name: "Agent 3 QA Tester", homeRoom: "qa",
      accent: "#2fb386", shirt: "#e9fbf4", shirtDark: "#2fb386", pants: "#2f4249", shoes: "#1f2d33", skin: "#f1c59e", hair: "#28353b",
      gear: "goggles", gearColor: "#80ffdb", start: [5, 25],
      itinerary: ["qa", "lounge", "review", "command", "hallway"],
    },
    {
      id: "agent-4", label: "AGENT 4 · REVIEW LOG ONLY", name: "Agent 4 Code Reviewer", homeRoom: "review",
      accent: "#845ec2", shirt: "#7c52b8", shirtDark: "#5a3891", pants: "#342e47", shoes: "#211d2e", skin: "#edc49f", hair: "#49333a",
      gear: "spectacles", gearColor: "#f2c876", start: [15, 25],
      itinerary: ["review", "security", "command", "backend", "lounge"],
    },
    {
      id: "agent-5", label: "AGENT 5 · DEBUGGER", name: "Agent 5 Customer/Admin Debugger", homeRoom: "debug",
      accent: "#e95d35", shirt: "#d95338", shirtDark: "#27323f", pants: "#323d4d", shoes: "#222a32", skin: "#d7a77f", hair: "#262e3d",
      gear: "visor", gearColor: "#ffbd59", start: [37, 25],
      itinerary: ["debug", "security", "hallway", "backend", "command"],
    },
    {
      id: "agent-6", label: "AGENT 6 · SECURITY", name: "Agent 6 Security Engineer", homeRoom: "security",
      accent: "#e11d48", shirt: "#e11d48", shirtDark: "#9f1239", pants: "#1e293b", shoes: "#1e1b4b", skin: "#f0c4a0", hair: "#1e1b4b",
      securityBadge: true, gear: "visor", gearColor: "#38bdf8", start: [26, 25],
      itinerary: ["security", "backend", "debug", "command", "qa", "frontend", "review"],
    },
  ];

  const ACTIVITY_ROOMS = {
    reviewing: "review",
    securing: "security",
    testing: "qa",
    debugging: "debug",
  };

  // ---------------------------------------------------------------------------
  // Map construction and pathfinding
  // ---------------------------------------------------------------------------

  function buildOfficeMap() {
    const grid = new Uint8Array(COLS * ROWS).fill(WALL);
    const roomIndex = new Int16Array(COLS * ROWS).fill(-1);
    const rooms = ROOM_DEFS.map((def, index) => ({ ...def, index, cx: def.x + def.w / 2, cy: def.y + def.h / 2 }));
    const roomById = Object.fromEntries(rooms.map((room) => [room.id, room]));
    const key = (x, y) => y * COLS + x;

    for (const room of rooms) {
      if (room.overlay) continue;
      for (let y = room.y; y < room.y + room.h; y += 1) {
        for (let x = room.x; x < room.x + room.w; x += 1) {
          grid[key(x, y)] = FLOOR;
          roomIndex[key(x, y)] = room.index;
        }
      }
    }
    for (const room of rooms) {
      if (!room.overlay) continue;
      for (let y = room.y; y < room.y + room.h; y += 1) {
        for (let x = room.x; x < room.x + room.w; x += 1) roomIndex[key(x, y)] = room.index;
      }
    }
    const doors = DOOR_DEFS.map((def) => ({ ...def }));
    for (const door of doors) {
      for (const [x, y] of door.tiles) {
        grid[key(x, y)] = DOOR;
        roomIndex[key(x, y)] = -2;
      }
    }
    const furniture = FURNITURE_DEFS.map((def) => ({ ...def }));
    for (const item of furniture) {
      for (let y = item.y; y < item.y + item.h; y += 1) {
        for (let x = item.x; x < item.x + item.w; x += 1) grid[key(x, y)] = FURNITURE;
      }
    }
    const seats = SEAT_DEFS.map((def) => ({ ...def, facing: "up" }));
    const pois = Object.fromEntries(Object.entries(POI_DEFS).map(([roomId, spots]) => [roomId, spots.map(([x, y]) => ({ x, y, room: roomId }))]));

    const map = {
      cols: COLS,
      rows: ROWS,
      tile: TILE,
      width: COLS * TILE,
      height: ROWS * TILE,
      grid,
      roomIndex,
      rooms,
      roomById,
      doors,
      furniture,
      seats,
      pois,
      decor: DECOR_DEFS.map((def) => ({ ...def })),
      key,
      inBounds(x, y) {
        return x >= 0 && y >= 0 && x < COLS && y < ROWS;
      },
      cell(x, y) {
        return this.inBounds(x, y) ? grid[key(x, y)] : WALL;
      },
      isWalkable(x, y) {
        const value = this.cell(x, y);
        return value === FLOOR || value === DOOR;
      },
      roomAt(x, y) {
        if (!this.inBounds(x, y)) return null;
        const index = roomIndex[key(Math.round(x), Math.round(y))];
        if (index === -2) return { id: "doorway", name: "Doorway", short: "DOORWAY" };
        return index >= 0 ? rooms[index] : null;
      },
    };
    return map;
  }

  class MinHeap {
    constructor() {
      this.items = [];
    }
    get size() {
      return this.items.length;
    }
    push(priority, value) {
      const items = this.items;
      items.push([priority, value]);
      let index = items.length - 1;
      while (index > 0) {
        const parent = (index - 1) >> 1;
        if (items[parent][0] <= items[index][0]) break;
        [items[parent], items[index]] = [items[index], items[parent]];
        index = parent;
      }
    }
    pop() {
      const items = this.items;
      const top = items[0];
      const last = items.pop();
      if (items.length) {
        items[0] = last;
        let index = 0;
        for (;;) {
          const left = index * 2 + 1;
          const right = left + 1;
          let smallest = index;
          if (left < items.length && items[left][0] < items[smallest][0]) smallest = left;
          if (right < items.length && items[right][0] < items[smallest][0]) smallest = right;
          if (smallest === index) break;
          [items[smallest], items[index]] = [items[index], items[smallest]];
          index = smallest;
        }
      }
      return top[1];
    }
  }

  /**
   * A* over walkable tiles with 8-way movement. Diagonal steps never cut the
   * corner of a wall, desk, or blocked tile. `blocked` is an optional Set of
   * tile keys (e.g. tiles occupied by other agents) treated as obstacles.
   * Returns the list of tiles to visit after `start`, or null when unreachable.
   */
  function findPath(map, start, goal, blocked) {
    const [sx, sy] = start;
    const [gx, gy] = goal;
    if (!map.isWalkable(gx, gy) || !map.isWalkable(sx, sy)) return null;
    const startKey = map.key(sx, sy);
    const goalKey = map.key(gx, gy);
    if (startKey === goalKey) return [];
    const isOpen = (x, y) => {
      if (!map.isWalkable(x, y)) return false;
      const tileKey = map.key(x, y);
      return !(blocked && blocked.has(tileKey) && tileKey !== goalKey);
    };
    if (blocked && blocked.has(goalKey)) return null;

    const size = map.cols * map.rows;
    const cost = new Float64Array(size).fill(Infinity);
    const came = new Int32Array(size).fill(-1);
    const closed = new Uint8Array(size);
    const heuristic = (x, y) => {
      const dx = Math.abs(x - gx);
      const dy = Math.abs(y - gy);
      return dx + dy + (SQRT2 - 2) * Math.min(dx, dy);
    };
    const heap = new MinHeap();
    cost[startKey] = 0;
    heap.push(heuristic(sx, sy), startKey);

    while (heap.size) {
      const current = heap.pop();
      if (closed[current]) continue;
      closed[current] = 1;
      if (current === goalKey) break;
      const cx = current % map.cols;
      const cy = (current - cx) / map.cols;
      for (let dy = -1; dy <= 1; dy += 1) {
        for (let dx = -1; dx <= 1; dx += 1) {
          if (!dx && !dy) continue;
          const nx = cx + dx;
          const ny = cy + dy;
          if (!isOpen(nx, ny)) continue;
          const diagonal = dx !== 0 && dy !== 0;
          if (diagonal && (!isOpen(cx + dx, cy) || !isOpen(cx, cy + dy))) continue;
          const nextKey = map.key(nx, ny);
          if (closed[nextKey]) continue;
          const nextCost = cost[current] + (diagonal ? SQRT2 : 1);
          if (nextCost < cost[nextKey]) {
            cost[nextKey] = nextCost;
            came[nextKey] = current;
            heap.push(nextCost + heuristic(nx, ny), nextKey);
          }
        }
      }
    }
    if (came[goalKey] === -1) return null;
    const path = [];
    let cursor = goalKey;
    while (cursor !== startKey && cursor !== -1) {
      const x = cursor % map.cols;
      path.push([x, (cursor - x) / map.cols]);
      cursor = came[cursor];
    }
    return path.reverse();
  }

  // ---------------------------------------------------------------------------
  // Status → activity mapping (only uses recorded task state)
  // ---------------------------------------------------------------------------

  function isWorkingStatus(status) {
    return ["preparing", "running", "active", "blocked"].includes(status);
  }

  function resolveActivity(agentId, task) {
    const status = (task && task.status) || "idle";
    const text = `${(task && (task.task || task.label)) || ""}`.toLowerCase();
    if (isWorkingStatus(status)) {
      if (agentId === "agent-6" || /\b(securing|shield|vuln|hardening|csrf|xss|sqli)\b/.test(text)) return "securing";
      if (agentId === "agent-4" || /review|diff|security/.test(text)) return "reviewing";
      if (agentId === "agent-3" || /\btest|\bqa\b|verif/.test(text)) return "testing";
      if (agentId === "agent-5" || /debug|diagnos|auth/.test(text)) return "debugging";
      return "working";
    }
    if (status === "completed") return "completed";
    return "idle";
  }

  // ---------------------------------------------------------------------------
  // Simulation core
  // ---------------------------------------------------------------------------

  class OfficeSimulation {
    constructor(map, options = {}) {
      this.map = map;
      this.time = 0;
      this.paused = false;
      this.speed = 1;
      this.reducedMotion = Boolean(options.reducedMotion);
      this.listeners = new Set();
      this.agents = AGENT_DEFS.map((def, index) => this.createAgent(def, index));
      for (const agent of this.agents) this.planNextGoal(agent);
    }

    createAgent(def, index) {
      const [x, y] = def.start;
      return {
        def,
        id: def.id,
        index,
        x,
        y,
        tileX: x,
        tileY: y,
        next: null,
        path: [],
        goal: null,
        mode: "dwelling",
        activity: "idle",
        status: "idle",
        source: "No task recorded",
        task: "",
        taskKey: "",
        facing: "down",
        walkPhase: 0,
        animTime: index * 0.37,
        dwell: 0.8 + index * 0.75,
        waitTime: 0,
        itineraryIndex: 0,
        completedReported: true,
        roomId: (this.map.roomAt(x, y) || {}).id || "",
        moving: false,
      };
    }

    onChange(listener) {
      this.listeners.add(listener);
      return () => this.listeners.delete(listener);
    }

    emit(agent, reason) {
      for (const listener of this.listeners) listener(agent, reason);
    }

    agentById(id) {
      return this.agents.find((agent) => agent.id === id) || null;
    }

    setPaused(paused) {
      this.paused = Boolean(paused);
      for (const agent of this.agents) this.emit(agent, "pause");
    }

    setSpeed(speed) {
      if (Number.isFinite(speed) && speed > 0) this.speed = Math.min(speed, 4);
    }

    setReducedMotion(value) {
      this.reducedMotion = Boolean(value);
      if (this.reducedMotion) {
        for (const agent of this.agents) if (agent.goal) this.teleport(agent, agent.goal.x, agent.goal.y);
      }
    }

    /** Apply recorded task state from app.js (`latest_by_agent`). */
    setTasks(latestByAgent = {}) {
      for (const agent of this.agents) {
        const task = latestByAgent[agent.id] || {};
        const status = task.status || "idle";
        const activity = resolveActivity(agent.id, task);
        const taskText = task.task || task.label || "";
        const key = `${status}|${activity}|${taskText}`;
        agent.source = task.source || "No task recorded";
        if (key === agent.taskKey) continue;
        const previousActivity = agent.activity;
        agent.taskKey = key;
        agent.status = status;
        agent.activity = activity;
        agent.task = taskText;
        if (activity === "completed" && previousActivity !== "completed") agent.completedReported = false;
        const needsNewGoal = activity !== previousActivity || isWorkingStatus(status) || activity === "completed";
        if (needsNewGoal) {
          agent.dwell = 0;
          this.planNextGoal(agent);
        }
        this.emit(agent, "task");
      }
    }

    /** End idle dwelling now so patrolling agents walk to their next stop. */
    skipDwell() {
      for (const agent of this.agents) {
        if (agent.mode === "dwelling" && !agent.path.length && !agent.next) {
          agent.dwell = 0;
          this.planNextGoal(agent);
        }
      }
    }

    /** Send one idle agent to its next patrol stop immediately. */
    nudgeAgent(id) {
      const agent = this.agentById(id);
      if (!agent || agent.mode === "working" || this.isTargetingWork(agent)) return;
      agent.dwell = 0;
      this.planNextGoal(agent);
    }

    isTargetingWork(agent) {
      return Boolean(agent.goal && agent.goal.kind === "seat");
    }

    workRoomFor(agent) {
      if (agent.activity === "working") return agent.def.homeRoom;
      return ACTIVITY_ROOMS[agent.activity] || agent.def.homeRoom;
    }

    claimedTiles(except) {
      const claimed = new Set();
      for (const other of this.agents) {
        if (other === except || !other.goal) continue;
        claimed.add(this.map.key(other.goal.x, other.goal.y));
      }
      return claimed;
    }

    occupiedTiles(except) {
      const occupied = new Set();
      for (const other of this.agents) {
        if (other === except) continue;
        occupied.add(this.map.key(other.tileX, other.tileY));
        if (other.next) occupied.add(this.map.key(other.next[0], other.next[1]));
      }
      return occupied;
    }

    pickSeat(agent, roomId) {
      const seats = this.map.seats.filter((seat) => seat.room === roomId);
      seats.sort((a, b) => (b.owner === agent.id) - (a.owner === agent.id));
      const claimed = this.claimedTiles(agent);
      return seats.find((seat) => !claimed.has(this.map.key(seat.x, seat.y))) || seats[0] || null;
    }

    pickSpot(agent, roomId) {
      const spots = this.map.pois[roomId] || [];
      if (!spots.length) return null;
      const claimed = this.claimedTiles(agent);
      const occupied = this.occupiedTiles(agent);
      const offset = (agent.index + agent.itineraryIndex) % spots.length;
      for (let i = 0; i < spots.length; i += 1) {
        const spot = spots[(offset + i) % spots.length];
        const tileKey = this.map.key(spot.x, spot.y);
        if (!claimed.has(tileKey) && !occupied.has(tileKey)) return spot;
      }
      return null;
    }

    planNextGoal(agent) {
      let goal = null;
      if (agent.activity !== "idle" && agent.activity !== "completed") {
        const roomId = this.workRoomFor(agent);
        const seat = this.pickSeat(agent, roomId);
        if (seat) goal = { x: seat.x, y: seat.y, room: roomId, kind: "seat", facing: seat.facing };
      } else if (agent.activity === "completed" && !agent.completedReported) {
        const seat = this.pickSeat(agent, "command");
        if (seat) goal = { x: seat.x, y: seat.y, room: "command", kind: "report", facing: seat.facing };
      }
      if (!goal) {
        const itinerary = agent.def.itinerary;
        for (let attempt = 0; attempt < itinerary.length && !goal; attempt += 1) {
          agent.itineraryIndex = (agent.itineraryIndex + 1) % itinerary.length;
          const roomId = itinerary[agent.itineraryIndex];
          const spot = this.pickSpot(agent, roomId);
          if (spot && !(spot.x === agent.tileX && spot.y === agent.tileY)) {
            goal = { x: spot.x, y: spot.y, room: roomId, kind: "poi", facing: "down" };
          }
        }
      }
      if (!goal) return;
      this.setGoal(agent, goal);
    }

    setGoal(agent, goal) {
      agent.goal = goal;
      agent.waitTime = 0;
      if (this.reducedMotion) {
        this.teleport(agent, goal.x, goal.y);
        return;
      }
      const from = agent.next || [agent.tileX, agent.tileY];
      agent.path = findPath(this.map, from, [goal.x, goal.y], null) || [];
      agent.mode = agent.path.length || agent.next ? "walking" : this.arrivalMode(agent);
      this.emit(agent, "goal");
    }

    teleport(agent, x, y) {
      agent.x = x;
      agent.y = y;
      agent.tileX = x;
      agent.tileY = y;
      agent.next = null;
      agent.path = [];
      this.arrive(agent);
    }

    arrivalMode(agent) {
      if (!agent.goal) return "dwelling";
      if (agent.goal.kind === "seat") return "working";
      if (agent.goal.kind === "report") return "reporting";
      return "dwelling";
    }

    arrive(agent) {
      agent.mode = this.arrivalMode(agent);
      if (agent.goal) agent.facing = agent.goal.facing || agent.facing;
      if (agent.mode === "dwelling") agent.dwell = 2.4 + (agent.index % 3) * 0.9;
      if (agent.mode === "reporting") agent.dwell = 2.6;
      this.updateRoom(agent);
      this.emit(agent, "arrive");
    }

    updateRoom(agent) {
      const room = this.map.roomAt(agent.tileX, agent.tileY);
      const roomId = room ? room.id : "";
      if (roomId && roomId !== "doorway" && roomId !== agent.roomId) {
        agent.roomId = roomId;
        this.emit(agent, "room");
      }
    }

    tileReservedByOther(agent, x, y) {
      for (const other of this.agents) {
        if (other === agent) continue;
        if (other.tileX === x && other.tileY === y) return true;
        if (other.next && other.next[0] === x && other.next[1] === y) return true;
      }
      return false;
    }

    canStep(agent, nextTile) {
      const [nx, ny] = nextTile;
      if (!this.map.isWalkable(nx, ny)) return false;
      if (this.tileReservedByOther(agent, nx, ny)) return false;
      const dx = nx - agent.tileX;
      const dy = ny - agent.tileY;
      if (dx && dy) {
        // Never squeeze diagonally between another agent and an obstacle.
        if (this.tileReservedByOther(agent, agent.tileX + dx, agent.tileY)) return false;
        if (this.tileReservedByOther(agent, agent.tileX, agent.tileY + dy)) return false;
      }
      return true;
    }

    step(dt) {
      if (this.paused) return;
      const scaled = Math.min(Math.max(dt, 0), 0.1) * this.speed;
      if (!scaled) return;
      this.time += scaled;
      for (const agent of this.agents) this.updateAgent(agent, scaled);
    }

    updateAgent(agent, dt) {
      agent.animTime += dt;
      const travelling = agent.next || agent.path.length;
      if (travelling) {
        this.advance(agent, dt);
        return;
      }
      agent.moving = false;
      const atGoal = agent.goal && agent.goal.x === agent.tileX && agent.goal.y === agent.tileY;
      if (agent.goal && !atGoal) {
        // The previous plan failed (blocked); retry periodically.
        agent.waitTime += dt;
        if (agent.waitTime >= REPLAN_AFTER_SECONDS) {
          const path = findPath(this.map, [agent.tileX, agent.tileY], [agent.goal.x, agent.goal.y], this.occupiedTiles(agent));
          agent.waitTime = 0;
          if (path && path.length) {
            agent.path = path;
            agent.mode = "walking";
          } else if (agent.goal.kind === "poi") {
            this.planNextGoal(agent);
          }
        }
        return;
      }
      if (agent.mode === "walking") this.arrive(agent);
      if (agent.mode === "dwelling" || agent.mode === "reporting") {
        agent.dwell -= dt;
        if (agent.dwell <= 0) {
          if (agent.mode === "reporting") agent.completedReported = true;
          this.planNextGoal(agent);
        }
      }
    }

    advance(agent, dt) {
      let budget = WALK_SPEED_TILES * dt;
      let moved = 0;
      let blocked = false;
      for (let guard = 0; budget > 1e-6 && guard < 8; guard += 1) {
        if (!agent.next) {
          if (!agent.path.length) break;
          const candidate = agent.path[0];
          if (!this.canStep(agent, candidate)) {
            blocked = true;
            break;
          }
          agent.next = candidate;
          agent.path.shift();
        }
        const dx = agent.next[0] - agent.x;
        const dy = agent.next[1] - agent.y;
        const distance = Math.hypot(dx, dy);
        if (Math.abs(dx) > 0.05 || Math.abs(dy) > 0.05) {
          agent.facing = Math.abs(dx) >= Math.abs(dy) ? (dx < 0 ? "left" : "right") : dy < 0 ? "up" : "down";
        }
        if (distance <= budget) {
          agent.x = agent.next[0];
          agent.y = agent.next[1];
          agent.tileX = agent.next[0];
          agent.tileY = agent.next[1];
          agent.next = null;
          budget -= distance;
          moved += distance;
          this.updateRoom(agent);
        } else {
          agent.x += (dx / distance) * budget;
          agent.y += (dy / distance) * budget;
          moved += budget;
          budget = 0;
        }
      }
      agent.moving = moved > 0;
      agent.walkPhase += moved * 1.7;
      if (moved > 0) agent.waitTime = 0;
      if (blocked && !agent.next) {
        agent.waitTime += dt;
        if (agent.waitTime >= REPLAN_AFTER_SECONDS) {
          const goal = agent.goal;
          const detour = goal
            ? findPath(this.map, [agent.tileX, agent.tileY], [goal.x, goal.y], this.occupiedTiles(agent))
            : null;
          if (detour && detour.length) {
            agent.path = detour;
            agent.waitTime = 0;
          } else if (agent.waitTime >= GIVE_UP_AFTER_SECONDS && goal && goal.kind === "poi") {
            agent.path = [];
            this.planNextGoal(agent);
          }
        }
      }
      if (!agent.next && !agent.path.length && agent.goal && agent.goal.x === agent.tileX && agent.goal.y === agent.tileY) {
        this.arrive(agent);
      }
    }

    statusLabel(agent) {
      if (this.paused) return "PAUSED";
      const travelling = agent.next || agent.path.length;
      if (travelling && agent.goal) {
        const room = this.map.roomById[agent.goal.room];
        return `WALKING → ${room ? room.short : "OFFICE"}`;
      }
      if (agent.mode === "working") {
        if (agent.status === "blocked") return "BLOCKED · NEEDS INPUT";
        if (agent.status === "preparing") return "STARTING TASK";
        if (agent.activity === "securing") return "SECURING SYSTEM";
        if (agent.activity === "reviewing") return "REVIEWING DIFF";
        if (agent.activity === "testing") return "TESTING";
        if (agent.activity === "debugging") return "DEBUGGING";
        return agent.status === "active" ? "WORKING · LOGGED" : "WORKING";
      }
      if (agent.mode === "reporting") return "✓ REPORTING DONE";
      if (agent.status === "completed") return "✓ COMPLETED · AVAILABLE";
      if (agent.status === "failed") return "LAST RUN FAILED";
      if (["cancelled", "timed_out", "interrupted"].includes(agent.status)) return `LAST RUN ${agent.status.replace("_", " ").toUpperCase()}`;
      return "AVAILABLE";
    }

    roomName(agent) {
      const room = this.map.roomById[agent.roomId];
      return room ? room.name : "Office floor";
    }
  }

  const findWaypointPath = findPath;
  const resolveAgentActivity = resolveActivity;

  const core = {
    TILE,
    COLS,
    ROWS,
    FLOOR,
    WALL,
    FURNITURE,
    DOOR,
    AGENT_DEFS,
    ROOM_DEFS,
    buildOfficeMap,
    findPath,
    findWaypointPath,
    resolveActivity,
    resolveAgentActivity,
    isWorkingStatus,
    OfficeSimulation,
  };

  if (typeof module === "object" && module && module.exports) {
    module.exports = core;
  }
  if (typeof document === "undefined" || typeof window === "undefined") return;

  // ---------------------------------------------------------------------------
  // Rendering helpers
  // ---------------------------------------------------------------------------

  function roundRect(ctx, x, y, w, h, r) {
    const radius = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.arcTo(x + w, y, x + w, y + h, radius);
    ctx.arcTo(x + w, y + h, x, y + h, radius);
    ctx.arcTo(x, y + h, x, y, radius);
    ctx.arcTo(x, y, x + w, y, radius);
    ctx.closePath();
  }

  function drawFloors(ctx, map) {
    ctx.fillStyle = "#3c4a43";
    ctx.fillRect(0, 0, map.width, map.height);
    for (const room of map.rooms) {
      for (let y = room.y; y < room.y + room.h; y += 1) {
        for (let x = room.x; x < room.x + room.w; x += 1) {
          if (room.hallway) ctx.fillStyle = (x + y) % 2 ? room.floor : room.floorAlt;
          else ctx.fillStyle = y % 2 ? room.floor : room.floorAlt;
          ctx.fillRect(x * TILE, y * TILE, TILE, TILE);
        }
      }
      if (!room.hallway) {
        ctx.strokeStyle = "rgba(60, 50, 40, .07)";
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let y = room.y; y <= room.y + room.h; y += 1) {
          ctx.moveTo(room.x * TILE, y * TILE + 0.5);
          ctx.lineTo((room.x + room.w) * TILE, y * TILE + 0.5);
        }
        for (let y = room.y; y < room.y + room.h; y += 1) {
          const shift = (y % 2) * (TILE * 1.5);
          for (let x = room.x * TILE + shift; x < (room.x + room.w) * TILE; x += TILE * 3) {
            ctx.moveTo(x + 0.5, y * TILE);
            ctx.lineTo(x + 0.5, (y + 1) * TILE);
          }
        }
        ctx.stroke();
      }
      if (room.overlay) {
        roundRect(ctx, room.x * TILE + 4, room.y * TILE + 4, room.w * TILE - 8, room.h * TILE - 8, 10);
        ctx.fillStyle = "rgba(184, 107, 53, .16)";
        ctx.fill();
        ctx.strokeStyle = "rgba(184, 107, 53, .45)";
        ctx.setLineDash([6, 5]);
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }
    // Hallway guide stripe.
    ctx.strokeStyle = "rgba(168, 141, 98, .35)";
    ctx.lineWidth = 2;
    ctx.setLineDash([10, 10]);
    ctx.beginPath();
    ctx.moveTo(1 * TILE, 15 * TILE);
    ctx.lineTo(43 * TILE, 15 * TILE);
    ctx.stroke();
    ctx.setLineDash([]);
  }

  function drawWalls(ctx, map) {
    for (let y = 0; y < map.rows; y += 1) {
      for (let x = 0; x < map.cols; x += 1) {
        if (map.cell(x, y) !== WALL) continue;
        const px = x * TILE;
        const py = y * TILE;
        ctx.fillStyle = "#6b5a52";
        ctx.fillRect(px, py, TILE, TILE);
        const below = map.cell(x, y + 1);
        if (y + 1 < map.rows && below !== WALL) {
          ctx.fillStyle = "#4a3c36";
          ctx.fillRect(px, py + TILE * 0.5, TILE, TILE * 0.5);
          ctx.fillStyle = "#86736a";
          ctx.fillRect(px, py + TILE * 0.5 - 2, TILE, 2);
          const shade = ctx.createLinearGradient(0, py + TILE, 0, py + TILE + 7);
          shade.addColorStop(0, "rgba(30, 20, 15, .22)");
          shade.addColorStop(1, "rgba(30, 20, 15, 0)");
          ctx.fillStyle = shade;
          ctx.fillRect(px, py + TILE, TILE, 7);
        } else {
          ctx.fillStyle = "rgba(255, 255, 255, .06)";
          ctx.fillRect(px, py, TILE, 2);
        }
      }
    }
  }

  function drawDecor(ctx, map) {
    for (const item of map.decor) {
      const px = item.x * TILE + 3;
      const py = item.y * TILE + TILE * 0.5 + 1;
      const w = item.w * TILE - 6;
      const h = TILE * 0.5 - 4;
      roundRect(ctx, px, py, w, h, 2);
      ctx.fillStyle = item.type === "screen" ? "#1f2a33" : "#fbf7ee";
      ctx.fill();
      ctx.strokeStyle = item.color;
      ctx.lineWidth = 1.5;
      ctx.stroke();
      ctx.fillStyle = item.type === "screen" ? item.color : "#5b4b40";
      ctx.font = "800 6.5px Inter, Arial, sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(item.label, px + w / 2, py + h / 2 + 0.5);
    }
  }

  function drawDoors(ctx, map) {
    const hallway = map.roomById.hallway;
    for (const door of map.doors) {
      const xs = door.tiles.map((t) => t[0]);
      const ys = door.tiles.map((t) => t[1]);
      const x0 = Math.min(...xs) * TILE;
      const y0 = Math.min(...ys) * TILE;
      const x1 = (Math.max(...xs) + 1) * TILE;
      const y1 = (Math.max(...ys) + 1) * TILE;
      ctx.fillStyle = hallway.floorAlt;
      ctx.fillRect(x0, y0, x1 - x0, y1 - y0);
      ctx.fillStyle = "rgba(120, 90, 60, .25)";
      ctx.fillStyle = "#c9b18a";
      if (door.orientation === "h") {
        ctx.fillRect(x0 + 4, y0 + TILE / 2 - 3, x1 - x0 - 8, 6);
        ctx.fillStyle = "#3a2f2a";
        ctx.fillRect(x0 - 3, y0, 4, TILE);
        ctx.fillRect(x1 - 1, y0, 4, TILE);
        // Open door leaf + swing arc.
        ctx.fillStyle = "#a8774c";
        ctx.fillRect(x0 + 1, y1 - 2, 4, TILE * 1.4);
        ctx.strokeStyle = "rgba(90, 70, 50, .35)";
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.arc(x0 + 3, y1, TILE * 1.4, 0, Math.PI / 2);
        ctx.stroke();
        ctx.setLineDash([]);
      } else {
        ctx.fillRect(x0 + TILE / 2 - 3, y0 + 4, 6, y1 - y0 - 8);
        ctx.fillStyle = "#3a2f2a";
        ctx.fillRect(x0, y0 - 3, TILE, 4);
        ctx.fillRect(x0, y1 - 1, TILE, 4);
        ctx.fillStyle = "#a8774c";
        ctx.fillRect(x1 - 2, y0 + 1, TILE * 1.2, 4);
      }
      if (door.label) {
        const plateY = door.tiles[0][1] === 12 ? y0 - TILE * 0.38 : y1 + 2;
        const plateX = (x0 + x1) / 2;
        ctx.font = "800 6px Inter, Arial, sans-serif";
        const width = ctx.measureText(door.label).width + 8;
        roundRect(ctx, plateX - width / 2, plateY - 1, width, 9, 3);
        ctx.fillStyle = "#fffaf0";
        ctx.fill();
        ctx.fillStyle = "#4a3c36";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(door.label, plateX, plateY + 3.6);
      }
    }
  }

  function drawFurnitureItem(ctx, item) {
    const px = item.x * TILE;
    const py = item.y * TILE;
    const w = item.w * TILE;
    const h = item.h * TILE;
    ctx.save();
    ctx.shadowColor = "rgba(40, 30, 20, .25)";
    ctx.shadowBlur = 5;
    ctx.shadowOffsetY = 3;
    switch (item.type) {
      case "desk":
      case "bench":
      case "console": {
        roundRect(ctx, px + 2, py + 3, w - 4, h - 4, 3);
        ctx.fillStyle = item.type === "bench" ? "#b8c4c0" : item.type === "console" ? "#5a4a44" : "#d2ab78";
        ctx.fill();
        ctx.shadowColor = "transparent";
        ctx.fillStyle = item.type === "bench" ? "#8d9a96" : item.type === "console" ? "#3f332f" : "#a9824f";
        ctx.fillRect(px + 2, py + h - 5, w - 4, 4);
        const monitors = item.type === "console" ? 3 : 1;
        for (let i = 0; i < monitors; i += 1) {
          const mw = item.type === "console" ? 16 : 22;
          const mx = px + (w / (monitors + 1)) * (i + 1) - mw / 2;
          ctx.fillStyle = "#26313a";
          roundRect(ctx, mx, py - 4, mw, 11, 2);
          ctx.fill();
          ctx.fillStyle = item.screen || "#8fd1db";
          ctx.globalAlpha = 0.55;
          ctx.fillRect(mx + 2, py - 2, mw - 4, 7);
          ctx.globalAlpha = 1;
        }
        ctx.fillStyle = "#efe7d6";
        ctx.fillRect(px + w / 2 - 9, py + h - 11, 18, 4);
        if (item.type === "bench") {
          ctx.fillStyle = "#2fb386";
          ctx.fillRect(px + 6, py + 7, 6, 5);
          ctx.fillStyle = "#ff9b42";
          ctx.fillRect(px + w - 12, py + 7, 6, 5);
        }
        break;
      }
      case "commandTable": {
        roundRect(ctx, px + 3, py + 3, w - 6, h - 6, 14);
        ctx.fillStyle = "#2e4a44";
        ctx.fill();
        ctx.shadowColor = "transparent";
        roundRect(ctx, px + 12, py + 11, w - 24, h - 22, 9);
        ctx.fillStyle = "#3f7a69";
        ctx.fill();
        ctx.strokeStyle = "rgba(160, 255, 220, .55)";
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let i = 1; i < 6; i += 1) {
          ctx.moveTo(px + 12 + ((w - 24) / 6) * i, py + 13);
          ctx.lineTo(px + 12 + ((w - 24) / 6) * i, py + h - 13);
        }
        ctx.moveTo(px + 14, py + h / 2);
        ctx.lineTo(px + w - 14, py + h / 2);
        ctx.stroke();
        ctx.fillStyle = "#ffbd59";
        ctx.font = "800 8px Inter, Arial, sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("COMMAND TABLE", px + w / 2, py + h / 2);
        break;
      }
      case "rack": {
        ctx.fillStyle = "#26323d";
        roundRect(ctx, px + 1, py + 1, w - 2, h - 2, 3);
        ctx.fill();
        ctx.shadowColor = "transparent";
        ctx.fillStyle = "#3a4b5a";
        for (let i = 0; i < item.w; i += 1) ctx.fillRect(px + i * TILE + 3, py + 4, TILE - 6, 4);
        break;
      }
      case "counter": {
        roundRect(ctx, px + 1, py + 2, w - 2, h - 3, 3);
        ctx.fillStyle = "#b5794a";
        ctx.fill();
        ctx.shadowColor = "transparent";
        ctx.fillStyle = "#8a5531";
        ctx.fillRect(px + 1, py + h - 5, w - 2, 4);
        ctx.fillStyle = "#37424a";
        ctx.fillRect(px + 6, py + 3, 12, 12);
        ctx.fillStyle = "#ff642e";
        ctx.beginPath();
        ctx.arc(px + 12, py + 9, 2.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#fffaf0";
        for (let i = 0; i < 3; i += 1) {
          ctx.beginPath();
          ctx.arc(px + 32 + i * 12, py + 10, 3.5, 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.fillStyle = "#e8a23a";
        ctx.beginPath();
        ctx.ellipse(px + w - 14, py + 10, 7, 4, 0, 0, Math.PI * 2);
        ctx.fill();
        break;
      }
      case "sofa": {
        roundRect(ctx, px + 1, py + 2, w - 2, h - 3, 7);
        ctx.fillStyle = "#c2603c";
        ctx.fill();
        ctx.shadowColor = "transparent";
        ctx.fillStyle = "#e07f57";
        for (let i = 0; i < item.w; i += 1) {
          roundRect(ctx, px + i * TILE + 3, py + 4, TILE - 6, h - 10, 4);
          ctx.fill();
        }
        break;
      }
      case "shelf": {
        ctx.fillStyle = "#6e4c35";
        ctx.fillRect(px + 1, py + 2, w - 2, h - 3);
        ctx.shadowColor = "transparent";
        const colors = ["#ff642e", "#4d9de0", "#2fb386", "#f2c876", "#845ec2"];
        for (let i = 0; i < item.w * 4; i += 1) {
          ctx.fillStyle = colors[i % colors.length];
          ctx.fillRect(px + 3 + i * 5.6, py + 5, 4, h - 10);
        }
        break;
      }
      case "plant": {
        ctx.fillStyle = "#b4774b";
        ctx.beginPath();
        ctx.ellipse(px + TILE / 2, py + TILE - 6, 6, 4, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowColor = "transparent";
        ctx.fillStyle = "#5f9e6e";
        for (const [ox, oy, r] of [[0, -4, 6], [-5, 0, 4.5], [5, 0, 4.5], [0, 2, 4]]) {
          ctx.beginPath();
          ctx.arc(px + TILE / 2 + ox, py + TILE / 2 + oy - 2, r, 0, Math.PI * 2);
          ctx.fill();
        }
        break;
      }
      default:
        break;
    }
    ctx.restore();
  }

  function drawChairs(ctx, map) {
    for (const seat of map.seats) {
      const cx = (seat.x + 0.5) * TILE;
      const cy = (seat.y + 0.5) * TILE + 4;
      ctx.fillStyle = "rgba(40, 35, 30, .18)";
      ctx.beginPath();
      ctx.ellipse(cx, cy + 6, 8, 3, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#4b5560";
      roundRect(ctx, cx - 7, cy - 4, 14, 10, 4);
      ctx.fill();
      ctx.fillStyle = "#606b77";
      roundRect(ctx, cx - 6, cy + 3, 12, 4, 2);
      ctx.fill();
    }
  }

  function renderStaticLayer(map, scale) {
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(map.width * scale);
    canvas.height = Math.round(map.height * scale);
    const ctx = canvas.getContext("2d");
    ctx.scale(scale, scale);
    drawFloors(ctx, map);
    drawWalls(ctx, map);
    drawDecor(ctx, map);
    drawDoors(ctx, map);
    drawChairs(ctx, map);
    for (const item of map.furniture) drawFurnitureItem(ctx, item);
    return canvas;
  }

  // Character drawing: a small 3/4 top-down figure with animated limbs.
  function drawAgent(ctx, agent, sim) {
    const def = agent.def;
    const cx = (agent.x + 0.5) * TILE;
    const feet = (agent.y + 0.5) * TILE + 9;
    const walking = agent.moving && !sim.paused;
    const working = agent.mode === "working" && !agent.next && !agent.path.length;
    const t = agent.animTime;
    const swing = walking ? Math.sin(agent.walkPhase * Math.PI) : 0;
    const bob = walking ? Math.abs(Math.sin(agent.walkPhase * Math.PI)) * 1.8 : working ? Math.abs(Math.sin(t * 8)) * 0.8 : Math.sin(t * 2.2) * 0.6;
    const side = agent.facing === "left" || agent.facing === "right";
    const back = agent.facing === "up";

    ctx.save();
    ctx.translate(cx, feet);
    ctx.fillStyle = "rgba(25, 20, 15, .28)";
    ctx.beginPath();
    ctx.ellipse(0, 0, walking ? 7 + Math.abs(swing) : 8, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    if (agent.facing === "left") ctx.scale(-1, 1);
    ctx.translate(0, -bob);

    // Legs
    ctx.fillStyle = def.pants;
    if (side) {
      ctx.save();
      ctx.translate(-1, -9);
      ctx.rotate(swing * 0.5);
      ctx.fillRect(-2, 0, 4, 8);
      ctx.fillStyle = def.shoes;
      ctx.fillRect(-2, 7, 6, 2.5);
      ctx.restore();
      ctx.save();
      ctx.fillStyle = def.pants;
      ctx.translate(1, -9);
      ctx.rotate(-swing * 0.5);
      ctx.fillRect(-2, 0, 4, 8);
      ctx.fillStyle = def.shoes;
      ctx.fillRect(-2, 7, 6, 2.5);
      ctx.restore();
    } else {
      const lift = swing * 2;
      ctx.fillRect(-5, -9 - Math.max(lift, 0), 4, 8 + Math.min(lift, 0) * 0);
      ctx.fillRect(1, -9 - Math.max(-lift, 0), 4, 8);
      ctx.fillStyle = def.shoes;
      ctx.fillRect(-5.5, -2 - Math.max(lift, 0), 5, 2.5);
      ctx.fillRect(0.5, -2 - Math.max(-lift, 0), 5, 2.5);
    }

    // Arms behind body when facing side/back
    const armSwing = working ? Math.sin(t * 16) * 0.35 - 0.6 : swing * 0.65;
    const drawArm = (x, angle) => {
      ctx.save();
      ctx.translate(x, -19);
      ctx.rotate(angle);
      ctx.fillStyle = def.shirtDark;
      roundRect(ctx, -1.8, 0, 3.6, 9, 1.6);
      ctx.fill();
      ctx.fillStyle = def.skin;
      ctx.fillRect(-1.8, 8, 3.6, 2.6);
      ctx.restore();
    };
    if (side) drawArm(-2, -armSwing);

    // Torso
    roundRect(ctx, side ? -5 : -7, -21, side ? 10 : 14, 13, 3);
    ctx.fillStyle = def.shirt;
    ctx.fill();
    if (!back) {
      ctx.fillStyle = def.shirtDark;
      if (side) ctx.fillRect(1, -20, 3, 11);
      else ctx.fillRect(-2, -20, 4, 12);
    }
    if (!side) {
      drawArm(-8.5, working ? armSwing * 0.6 : armSwing);
      drawArm(8.5, working ? -armSwing * 0.6 : -armSwing);
    } else {
      drawArm(2, armSwing);
    }

    // Head
    const headY = -27;
    ctx.fillStyle = def.skin;
    ctx.beginPath();
    ctx.arc(0, headY, 6.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = def.hair;
    ctx.beginPath();
    if (back) ctx.arc(0, headY, 6.8, 0, Math.PI * 2);
    else if (side) ctx.arc(-1.5, headY - 1.5, 6.4, Math.PI * 0.8, Math.PI * 2.05);
    else ctx.arc(0, headY - 1.5, 6.6, Math.PI, Math.PI * 2);
    ctx.fill();
    if (def.securityBadge && !back) {
      // Tactical cyber-shield crest on chest for Agent 6 (Security Engineer)
      ctx.fillStyle = "#38bdf8";
      ctx.beginPath();
      ctx.arc(side ? 2.2 : 3.2, -16.5, 1.8, 0, Math.PI * 2);
      ctx.fill();
    }
    if (!back) {
      ctx.fillStyle = "#1f2328";
      if (side) {
        ctx.fillRect(3, headY - 0.5, 1.6, 2);
      } else {
        ctx.fillRect(-3, headY - 0.5, 1.6, 2);
        ctx.fillRect(1.4, headY - 0.5, 1.6, 2);
      }
    }
    // Role gear
    ctx.strokeStyle = def.gearColor;
    ctx.fillStyle = def.gearColor;
    ctx.lineWidth = 1.5;
    if (def.gear === "headphones") {
      ctx.beginPath();
      ctx.arc(0, headY - 1, 7.6, Math.PI * 1.05, Math.PI * 1.95);
      ctx.stroke();
      if (!side) {
        ctx.fillRect(-8.6, headY - 2, 3, 5);
        ctx.fillRect(5.6, headY - 2, 3, 5);
      } else ctx.fillRect(-2, headY - 2, 3.5, 5);
    } else if (!back && (def.gear === "glasses" || def.gear === "spectacles")) {
      if (side) ctx.strokeRect(2, headY - 1.5, 3.4, 3);
      else {
        ctx.strokeRect(-4.4, headY - 1.6, 3.6, 3);
        ctx.strokeRect(0.8, headY - 1.6, 3.6, 3);
      }
    } else if (!back && (def.gear === "goggles" || def.gear === "visor")) {
      roundRect(ctx, side ? 0 : -5.5, headY - (def.gear === "goggles" ? 5.5 : 2), side ? 6 : 11, 3, 1.2);
      ctx.fill();
    }
    ctx.restore();
  }

  function drawActivityIcon(ctx, kind, x, y, color) {
    ctx.save();
    ctx.translate(x, y);
    ctx.beginPath();
    ctx.arc(0, 0, 8, 0, Math.PI * 2);
    ctx.fillStyle = "#fffdf6";
    ctx.fill();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = 1.8;
    ctx.lineCap = "round";
    ctx.beginPath();
    switch (kind) {
      case "completed":
        ctx.moveTo(-3.5, 0);
        ctx.lineTo(-1, 2.8);
        ctx.lineTo(3.8, -2.8);
        ctx.stroke();
        break;
      case "securing":
        ctx.moveTo(0, -4.4);
        ctx.lineTo(4, -2.4);
        ctx.lineTo(3.2, 1.8);
        ctx.lineTo(0, 4.4);
        ctx.lineTo(-3.2, 1.8);
        ctx.lineTo(-4, -2.4);
        ctx.closePath();
        ctx.stroke();
        break;
      case "reviewing":
        ctx.arc(-1, -1, 3, 0, Math.PI * 2);
        ctx.moveTo(1.2, 1.2);
        ctx.lineTo(4, 4);
        ctx.stroke();
        break;
      case "testing":
        ctx.moveTo(-2, -4);
        ctx.lineTo(-2, -0.5);
        ctx.lineTo(-4, 3.5);
        ctx.lineTo(4, 3.5);
        ctx.lineTo(2, -0.5);
        ctx.lineTo(2, -4);
        ctx.stroke();
        break;
      case "debugging":
        ctx.ellipse(0, 0.5, 2.6, 3.6, 0, 0, Math.PI * 2);
        ctx.moveTo(-2.6, -1);
        ctx.lineTo(-5, -2.5);
        ctx.moveTo(2.6, -1);
        ctx.lineTo(5, -2.5);
        ctx.moveTo(-2.6, 2);
        ctx.lineTo(-5, 3.5);
        ctx.moveTo(2.6, 2);
        ctx.lineTo(5, 3.5);
        ctx.stroke();
        break;
      case "blocked":
        ctx.moveTo(0, -4);
        ctx.lineTo(0, 1);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(0, 3.6, 1, 0, Math.PI * 2);
        ctx.fill();
        break;
      case "paused":
        ctx.fillRect(-3, -3.5, 2.2, 7);
        ctx.fillRect(0.8, -3.5, 2.2, 7);
        break;
      default:
        for (let i = -1; i <= 1; i += 1) {
          ctx.beginPath();
          ctx.arc(i * 3, 0, 1.2, 0, Math.PI * 2);
          ctx.fill();
        }
        break;
    }
    ctx.restore();
  }

  // ---------------------------------------------------------------------------
  // Renderer with camera, zoom, pan, minimap
  // ---------------------------------------------------------------------------

  class OfficeRenderer {
    constructor(canvas, sim) {
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d");
      this.sim = sim;
      this.map = sim.map;
      this.staticLayer = renderStaticLayer(this.map, 2);
      this.camera = { x: this.map.width / 2, y: this.map.height / 2, zoom: 1 };
      this.cameraTarget = null;
      this.fitZoom = 1;
      this.viewW = 0;
      this.viewH = 0;
      this.dpr = 1;
      this.initialized = false;
      this.showPaths = true;
      this.selectedId = "";
      this.followId = "";
      this.minimap = { x: 0, y: 0, w: 0, h: 0, visible: false };
    }

    resize() {
      const rect = this.canvas.getBoundingClientRect();
      const w = Math.round(rect.width);
      const h = Math.round(rect.height);
      if (!w || !h) return false;
      this.dpr = Math.min(window.devicePixelRatio || 1, 2);
      if (w !== this.viewW || h !== this.viewH || this.canvas.width !== Math.round(w * this.dpr)) {
        this.viewW = w;
        this.viewH = h;
        this.canvas.width = Math.round(w * this.dpr);
        this.canvas.height = Math.round(h * this.dpr);
      }
      this.fitZoom = Math.min(w / this.map.width, h / this.map.height) * 0.98;
      if (!this.initialized) {
        this.resetView(true);
        this.initialized = true;
      }
      this.clampCamera();
      return true;
    }

    get minZoom() {
      return this.fitZoom * 0.85;
    }

    get maxZoom() {
      return Math.max(this.fitZoom * 4, 2.6);
    }

    resetView(immediate = false) {
      const target = { x: this.map.width / 2, y: this.map.height / 2, zoom: this.fitZoom };
      this.followId = "";
      if (immediate) {
        Object.assign(this.camera, target);
        this.cameraTarget = null;
      } else this.cameraTarget = target;
    }

    focusRoom(roomId) {
      const room = this.map.roomById[roomId];
      if (!room) return;
      this.followId = "";
      const zoom = Math.min(this.viewW / ((room.w + 2) * TILE), this.viewH / ((room.h + 2) * TILE));
      this.cameraTarget = { x: room.cx * TILE, y: room.cy * TILE, zoom: Math.min(Math.max(zoom, this.minZoom), this.maxZoom) };
    }

    focusAgent(id) {
      const agent = this.sim.agentById(id);
      if (!agent) return;
      this.selectedId = id;
      this.followId = id;
      const zoom = Math.max(this.camera.zoom, Math.min(this.fitZoom * 2.2, this.maxZoom));
      this.cameraTarget = { x: (agent.x + 0.5) * TILE, y: (agent.y + 0.5) * TILE, zoom };
    }

    zoomBy(factor, sx = this.viewW / 2, sy = this.viewH / 2) {
      const before = this.screenToWorld(sx, sy);
      this.camera.zoom = Math.min(Math.max(this.camera.zoom * factor, this.minZoom), this.maxZoom);
      const after = this.screenToWorld(sx, sy);
      this.camera.x += before.x - after.x;
      this.camera.y += before.y - after.y;
      this.cameraTarget = null;
      this.clampCamera();
    }

    panBy(dx, dy) {
      this.camera.x -= dx / this.camera.zoom;
      this.camera.y -= dy / this.camera.zoom;
      this.cameraTarget = null;
      this.followId = "";
      this.clampCamera();
    }

    clampCamera() {
      const halfW = this.viewW / 2 / this.camera.zoom;
      const halfH = this.viewH / 2 / this.camera.zoom;
      const clampAxis = (value, half, size) => (half * 2 >= size ? size / 2 : Math.min(Math.max(value, half), size - half));
      this.camera.x = clampAxis(this.camera.x, halfW, this.map.width);
      this.camera.y = clampAxis(this.camera.y, halfH, this.map.height);
    }

    screenToWorld(sx, sy) {
      return {
        x: (sx - this.viewW / 2) / this.camera.zoom + this.camera.x,
        y: (sy - this.viewH / 2) / this.camera.zoom + this.camera.y,
      };
    }

    worldToScreen(wx, wy) {
      return {
        x: (wx - this.camera.x) * this.camera.zoom + this.viewW / 2,
        y: (wy - this.camera.y) * this.camera.zoom + this.viewH / 2,
      };
    }

    agentAt(sx, sy) {
      const point = this.screenToWorld(sx, sy);
      let best = null;
      let bestDistance = Infinity;
      for (const agent of this.sim.agents) {
        const cx = (agent.x + 0.5) * TILE;
        const cy = (agent.y + 0.5) * TILE - 8;
        const distance = Math.hypot(point.x - cx, (point.y - cy) * 0.75);
        if (distance < 18 && distance < bestDistance) {
          best = agent;
          bestDistance = distance;
        }
      }
      return best;
    }

    minimapHit(sx, sy) {
      const m = this.minimap;
      return m.visible && sx >= m.x && sy >= m.y && sx <= m.x + m.w && sy <= m.y + m.h;
    }

    moveToMinimapPoint(sx, sy) {
      const m = this.minimap;
      this.camera.x = ((sx - m.x) / m.w) * this.map.width;
      this.camera.y = ((sy - m.y) / m.h) * this.map.height;
      this.cameraTarget = null;
      this.followId = "";
      this.clampCamera();
    }

    updateCamera(dt) {
      if (this.followId) {
        const agent = this.sim.agentById(this.followId);
        if (agent) {
          const zoom = this.cameraTarget ? this.cameraTarget.zoom : this.camera.zoom;
          this.cameraTarget = { x: (agent.x + 0.5) * TILE, y: (agent.y + 0.5) * TILE, zoom };
        }
      }
      if (!this.cameraTarget) return;
      const ease = 1 - Math.pow(0.0015, dt);
      this.camera.x += (this.cameraTarget.x - this.camera.x) * ease;
      this.camera.y += (this.cameraTarget.y - this.camera.y) * ease;
      this.camera.zoom += (this.cameraTarget.zoom - this.camera.zoom) * ease;
      this.clampCamera();
      const settled = Math.abs(this.cameraTarget.x - this.camera.x) < 0.5 && Math.abs(this.cameraTarget.y - this.camera.y) < 0.5 && Math.abs(this.cameraTarget.zoom - this.camera.zoom) < 0.002;
      if (settled && !this.followId) this.cameraTarget = null;
    }

    render(timeSeconds) {
      const ctx = this.ctx;
      const { zoom } = this.camera;
      ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
      ctx.fillStyle = "#26302b";
      ctx.fillRect(0, 0, this.viewW, this.viewH);

      ctx.save();
      ctx.translate(this.viewW / 2, this.viewH / 2);
      ctx.scale(zoom, zoom);
      ctx.translate(-this.camera.x, -this.camera.y);
      ctx.imageSmoothingEnabled = true;
      ctx.drawImage(this.staticLayer, 0, 0, this.map.width, this.map.height);
      this.drawLiveProps(ctx, timeSeconds);
      if (this.showPaths) this.drawRoutes(ctx, timeSeconds);
      this.drawSelection(ctx, timeSeconds);
      const ordered = [...this.sim.agents].sort((a, b) => a.y - b.y);
      for (const agent of ordered) drawAgent(ctx, agent, this.sim);
      ctx.restore();

      this.drawRoomLabels(ctx);
      this.drawAgentLabels(ctx, ordered);
      this.drawMinimap(ctx);
    }

    drawLiveProps(ctx, t) {
      // Blinking server/test-rack LEDs.
      for (const item of this.map.furniture) {
        if (item.type !== "rack") continue;
        for (let i = 0; i < item.w; i += 1) {
          for (let j = 0; j < 3; j += 1) {
            const on = Math.floor(t * 2.4 + i * 1.7 + j * 0.9) % 3 !== 0;
            ctx.fillStyle = on ? ["#79d5bd", "#ffbd70", "#4d9de0"][j] : "#2b3743";
            ctx.fillRect(item.x * TILE + i * TILE + 5 + j * 5, item.y * TILE + 12, 3, 3);
          }
        }
      }
      // Desk screens glow where an agent is actively working.
      for (const agent of this.sim.agents) {
        if (agent.mode !== "working" || agent.next || agent.path.length) continue;
        const px = (agent.tileX + 0.5) * TILE;
        const py = (agent.tileY - 1) * TILE - 2;
        const pulse = 0.35 + Math.abs(Math.sin(t * 3 + agent.index)) * 0.4;
        ctx.save();
        ctx.globalAlpha = pulse;
        ctx.fillStyle = agent.def.accent;
        ctx.shadowColor = agent.def.accent;
        ctx.shadowBlur = 12;
        ctx.fillRect(px - 9, py, 18, 7);
        ctx.restore();
      }
    }

    drawRoutes(ctx, t) {
      ctx.save();
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);
      ctx.lineDashOffset = -t * 18;
      for (const agent of this.sim.agents) {
        if (!agent.goal || (!agent.next && !agent.path.length)) continue;
        const points = [[agent.x, agent.y]];
        if (agent.next) points.push(agent.next);
        points.push(...agent.path);
        ctx.strokeStyle = agent.def.accent;
        ctx.globalAlpha = 0.75;
        ctx.beginPath();
        points.forEach(([x, y], i) => {
          const px = (x + 0.5) * TILE;
          const py = (y + 0.5) * TILE + 8;
          if (i === 0) ctx.moveTo(px, py);
          else ctx.lineTo(px, py);
        });
        ctx.stroke();
        const gx = (agent.goal.x + 0.5) * TILE;
        const gy = (agent.goal.y + 0.5) * TILE + 8;
        const pulse = 1 + Math.sin(t * 5) * 0.18;
        ctx.setLineDash([]);
        ctx.globalAlpha = 0.9;
        ctx.beginPath();
        ctx.ellipse(gx, gy, 9 * pulse, 4 * pulse, 0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = agent.def.accent;
        ctx.beginPath();
        ctx.arc(gx, gy, 2.4, 0, Math.PI * 2);
        ctx.fill();
        ctx.setLineDash([5, 5]);
      }
      ctx.restore();
    }

    drawSelection(ctx, t) {
      if (!this.selectedId) return;
      const agent = this.sim.agentById(this.selectedId);
      if (!agent) return;
      const cx = (agent.x + 0.5) * TILE;
      const cy = (agent.y + 0.5) * TILE + 9;
      ctx.save();
      ctx.strokeStyle = agent.def.accent;
      ctx.lineWidth = 2.5;
      ctx.globalAlpha = 0.65 + Math.sin(t * 4) * 0.25;
      ctx.beginPath();
      ctx.ellipse(cx, cy, 14, 6, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }

    drawRoomLabels(ctx) {
      const zoom = this.camera.zoom;
      const showSubtitle = zoom >= this.fitZoom * 1.35;
      ctx.save();
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      for (const room of this.map.rooms) {
        const anchorY = room.hallway ? room.y + 2.95 : room.overlay ? room.y + 2.05 : room.y + 1.15;
        const anchorX = room.hallway ? 26 : room.cx;
        const p = this.worldToScreen(anchorX * TILE, anchorY * TILE);
        if (p.x < -80 || p.y < -20 || p.x > this.viewW + 80 || p.y > this.viewH + 20) continue;
        ctx.font = "800 11px Inter, Arial, sans-serif";
        const title = room.name.toUpperCase();
        const titleWidth = ctx.measureText(title).width;
        let width = titleWidth + 22;
        let subtitleWidth = 0;
        if (showSubtitle && room.subtitle) {
          ctx.font = "600 9px Inter, Arial, sans-serif";
          subtitleWidth = ctx.measureText(room.subtitle).width;
          width = Math.max(width, subtitleWidth + 18);
        }
        const height = showSubtitle && room.subtitle ? 31 : 19;
        roundRect(ctx, p.x - width / 2, p.y - 9, width, height, 7);
        ctx.fillStyle = room.overlay || room.hallway ? "rgba(255, 250, 240, .85)" : "rgba(255, 253, 247, .93)";
        ctx.fill();
        ctx.strokeStyle = room.accent;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        ctx.fillStyle = room.accent;
        ctx.beginPath();
        ctx.arc(p.x - titleWidth / 2 - 6, p.y + 0.5, 3, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#2c3a33";
        ctx.font = "800 11px Inter, Arial, sans-serif";
        ctx.fillText(title, p.x + 4, p.y + 0.5);
        if (showSubtitle && room.subtitle) {
          ctx.fillStyle = "#6b7a70";
          ctx.font = "600 9px Inter, Arial, sans-serif";
          ctx.fillText(room.subtitle, p.x, p.y + 13);
        }
      }
      ctx.restore();
    }

    drawAgentLabels(ctx, agents) {
      const placed = [];
      const overlaps = (box) => placed.some((other) => box.x < other.x + other.w && box.x + box.w > other.x && box.y < other.y + other.h && box.y + box.h > other.y);
      const compact = this.camera.zoom < this.fitZoom * 1.15;
      ctx.save();
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      for (const agent of [...agents].reverse()) {
        const head = this.worldToScreen((agent.x + 0.5) * TILE, (agent.y + 0.5) * TILE - 32);
        if (head.x < -120 || head.y < -60 || head.x > this.viewW + 120 || head.y > this.viewH + 60) continue;
        const name = compact ? agent.def.label.split(" · ")[0] : agent.def.label;
        const status = this.sim.statusLabel(agent);
        ctx.font = "800 10.5px Inter, Arial, sans-serif";
        const nameWidth = ctx.measureText(name).width + 14;
        ctx.font = "800 9px Inter, Arial, sans-serif";
        const statusWidth = ctx.measureText(status).width + 12;
        const width = Math.max(nameWidth, statusWidth);
        const height = 33;
        const box = { x: head.x - width / 2, y: head.y - height - 6, w: width, h: height };
        for (let attempt = 0; attempt < 6 && overlaps(box); attempt += 1) box.y -= height * 0.55 + 2;
        placed.push(box);
        const displaced = box.y + height + 6 < head.y - 2;
        if (displaced) {
          ctx.strokeStyle = agent.def.accent;
          ctx.globalAlpha = 0.6;
          ctx.lineWidth = 1;
          ctx.beginPath();
          ctx.moveTo(head.x, box.y + height);
          ctx.lineTo(head.x, head.y - 4);
          ctx.stroke();
          ctx.globalAlpha = 1;
        }
        roundRect(ctx, head.x - nameWidth / 2, box.y, nameWidth, 17, 5);
        ctx.fillStyle = "#fffdf6";
        ctx.fill();
        ctx.lineWidth = 1.6;
        ctx.strokeStyle = agent.def.accent;
        ctx.stroke();
        ctx.fillStyle = "#273d34";
        ctx.font = "800 10.5px Inter, Arial, sans-serif";
        ctx.fillText(name, head.x, box.y + 9);

        const statusTheme = this.statusTheme(agent);
        roundRect(ctx, head.x - statusWidth / 2, box.y + 19, statusWidth, 14, 5);
        ctx.fillStyle = statusTheme.bg;
        ctx.fill();
        ctx.strokeStyle = statusTheme.border;
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.fillStyle = statusTheme.text;
        ctx.font = "800 9px Inter, Arial, sans-serif";
        ctx.fillText(status, head.x, box.y + 26.5);

        const icon = this.activityIcon(agent);
        if (icon) drawActivityIcon(ctx, icon, head.x + nameWidth / 2 + 9, box.y + 8.5, agent.def.accent);
      }
      ctx.restore();
    }

    activityIcon(agent) {
      if (this.sim.paused) return "paused";
      if (agent.next || agent.path.length) return "";
      if (agent.mode === "working") {
        if (agent.status === "blocked") return "blocked";
        if (["securing", "reviewing", "testing", "debugging"].includes(agent.activity)) return agent.activity;
        return "working";
      }
      if (agent.mode === "reporting" || agent.status === "completed") return "completed";
      return "";
    }

    statusTheme(agent) {
      if (this.sim.paused) return { bg: "#eceee9", border: "#8c968e", text: "#4e5850" };
      if (agent.next || agent.path.length) return { bg: "#fff5e5", border: "#f09843", text: "#9b5114" };
      if (agent.mode === "working") {
        if (agent.status === "blocked") return { bg: "#fff0e8", border: "#dc7961", text: "#a44231" };
        if (agent.activity === "securing") return { bg: "#ffe4e6", border: "#e11d48", text: "#9f1239" };
        if (agent.activity === "reviewing") return { bg: "#f2ebff", border: "#845ec2", text: "#4f2d87" };
        if (agent.activity === "testing") return { bg: "#e0faf0", border: "#2fb386", text: "#186449" };
        if (agent.activity === "debugging") return { bg: "#fff1e6", border: "#e95d35", text: "#9b3416" };
        return { bg: "#dff3e4", border: "#4da674", text: "#1f6844" };
      }
      if (agent.status === "completed") return { bg: "#e7f0dc", border: "#89ad66", text: "#4e6d34" };
      if (agent.status === "failed") return { bg: "#fff0e8", border: "#dc7961", text: "#a44231" };
      return { bg: "#eef4e8", border: "#9db4a1", text: "#425a4e" };
    }

    drawMinimap(ctx) {
      const m = this.minimap;
      m.visible = this.viewW >= 460 && this.viewH >= 300;
      if (!m.visible) return;
      m.w = Math.min(176, this.viewW * 0.26);
      m.h = (m.w * this.map.height) / this.map.width;
      m.x = this.viewW - m.w - 12;
      m.y = this.viewH - m.h - 12;
      ctx.save();
      roundRect(ctx, m.x - 4, m.y - 4, m.w + 8, m.h + 8, 8);
      ctx.fillStyle = "rgba(20, 26, 23, .78)";
      ctx.fill();
      ctx.globalAlpha = 0.95;
      ctx.drawImage(this.staticLayer, m.x, m.y, m.w, m.h);
      ctx.globalAlpha = 1;
      const scale = m.w / this.map.width;
      for (const agent of this.sim.agents) {
        ctx.fillStyle = agent.def.accent;
        ctx.strokeStyle = "#fff";
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.arc(m.x + (agent.x + 0.5) * TILE * scale, m.y + (agent.y + 0.5) * TILE * scale, 3.2, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      }
      const topLeft = this.screenToWorld(0, 0);
      const bottomRight = this.screenToWorld(this.viewW, this.viewH);
      const vx = Math.max(topLeft.x, 0);
      const vy = Math.max(topLeft.y, 0);
      const vw = Math.min(bottomRight.x, this.map.width) - vx;
      const vh = Math.min(bottomRight.y, this.map.height) - vy;
      ctx.strokeStyle = "#ffe08a";
      ctx.lineWidth = 1.5;
      ctx.strokeRect(m.x + vx * scale, m.y + vy * scale, vw * scale, vh * scale);
      ctx.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // Browser wiring
  // ---------------------------------------------------------------------------

  const canvas = document.getElementById("office-sim-canvas");
  if (!canvas) return;

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const map = buildOfficeMap();
  const sim = new OfficeSimulation(map, { reducedMotion: reduceMotion.matches });
  const renderer = new OfficeRenderer(canvas, sim);
  let rafHandle = 0;
  let lastFrame = 0;
  let cityVisible = Boolean(document.getElementById("panel-city")?.classList.contains("active"));
  let zoneTimer = 0;

  function publishZones() {
    zoneTimer = 0;
    const zones = {};
    const activities = {};
    for (const agent of sim.agents) {
      const roomLabel = sim.roomName(agent);
      const stateLabel = sim.statusLabel(agent);
      zones[agent.id] = roomLabel;
      activities[agent.id] = stateLabel;
      const mirrorNode = document.getElementById(`pixel-agent-${agent.id}`);
      if (mirrorNode) {
        mirrorNode.dataset.status = agent.status;
        mirrorNode.dataset.activity = agent.activity;
        mirrorNode.dataset.room = agent.roomId;
        mirrorNode.setAttribute("aria-label", `${agent.def.name}, ${stateLabel} in ${roomLabel}`);
      }
      const zoneNode = document.getElementById(`pixel-agent-${agent.index + 1}-zone`);
      if (zoneNode) zoneNode.textContent = roomLabel.toUpperCase();
      const stateNode = document.getElementById(`pixel-agent-${agent.index + 1}-state`);
      if (stateNode) stateNode.textContent = stateLabel;
    }
    document.dispatchEvent(new CustomEvent("monitor:city-zones", { detail: { zones, activities, selected: renderer.selectedId } }));
  }

  function schedulePublish() {
    if (!zoneTimer) zoneTimer = window.setTimeout(publishZones, 350);
  }

  sim.onChange((agent, reason) => {
    if (reason === "room" || reason === "arrive" || reason === "task" || reason === "goal" || reason === "pause") schedulePublish();
  });

  function frame(now) {
    rafHandle = 0;
    if (!cityVisible || document.hidden) return;
    const dt = lastFrame ? Math.min((now - lastFrame) / 1000, 0.1) : 0;
    lastFrame = now;
    if (!renderer.initialized || renderer.viewW === 0) renderer.resize();
    if (renderer.viewW) {
      sim.step(dt);
      renderer.updateCamera(dt || 0.016);
      renderer.render(now / 1000);
    }
    rafHandle = window.requestAnimationFrame(frame);
  }

  function startLoop() {
    if (!rafHandle && cityVisible && !document.hidden) {
      lastFrame = 0;
      rafHandle = window.requestAnimationFrame(frame);
    }
  }

  function stopLoop() {
    if (rafHandle) window.cancelAnimationFrame(rafHandle);
    rafHandle = 0;
    lastFrame = 0;
  }

  const resizeObserver = typeof ResizeObserver === "function" ? new ResizeObserver(() => renderer.resize()) : null;
  resizeObserver?.observe(canvas);
  window.addEventListener("resize", () => renderer.resize());

  // Pointer interaction: drag to pan, wheel/pinch to zoom, click to select.
  const pointers = new Map();
  let dragMoved = 0;
  let pinchDistance = 0;
  let minimapDragging = false;

  const localPoint = (event) => {
    const rect = canvas.getBoundingClientRect();
    return { x: event.clientX - rect.left, y: event.clientY - rect.top };
  };

  canvas.addEventListener("pointerdown", (event) => {
    canvas.focus({ preventScroll: true });
    const point = localPoint(event);
    canvas.setPointerCapture(event.pointerId);
    pointers.set(event.pointerId, point);
    dragMoved = 0;
    minimapDragging = pointers.size === 1 && renderer.minimapHit(point.x, point.y);
    if (minimapDragging) renderer.moveToMinimapPoint(point.x, point.y);
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      pinchDistance = Math.hypot(a.x - b.x, a.y - b.y);
    }
    canvas.classList.add("is-dragging");
  });

  canvas.addEventListener("pointermove", (event) => {
    const point = localPoint(event);
    if (!pointers.has(event.pointerId)) {
      canvas.style.cursor = renderer.agentAt(point.x, point.y) ? "pointer" : renderer.minimapHit(point.x, point.y) ? "crosshair" : "grab";
      return;
    }
    const previous = pointers.get(event.pointerId);
    pointers.set(event.pointerId, point);
    if (minimapDragging) {
      renderer.moveToMinimapPoint(point.x, point.y);
      return;
    }
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      const distance = Math.hypot(a.x - b.x, a.y - b.y);
      if (pinchDistance) renderer.zoomBy(distance / pinchDistance, (a.x + b.x) / 2, (a.y + b.y) / 2);
      pinchDistance = distance;
      dragMoved += 10;
      return;
    }
    const dx = point.x - previous.x;
    const dy = point.y - previous.y;
    dragMoved += Math.abs(dx) + Math.abs(dy);
    if (dragMoved > 3) renderer.panBy(dx, dy);
  });

  const endPointer = (event) => {
    const point = localPoint(event);
    const wasClick = pointers.size === 1 && dragMoved <= 4 && !minimapDragging;
    pointers.delete(event.pointerId);
    if (pointers.size < 2) pinchDistance = 0;
    if (!pointers.size) {
      canvas.classList.remove("is-dragging");
      minimapDragging = false;
    }
    if (wasClick && event.type === "pointerup") {
      const agent = renderer.agentAt(point.x, point.y);
      selectAgent(agent ? agent.id : "", Boolean(agent));
    }
  };
  canvas.addEventListener("pointerup", endPointer);
  canvas.addEventListener("pointercancel", endPointer);

  canvas.addEventListener("wheel", (event) => {
    event.preventDefault();
    const point = localPoint(event);
    renderer.zoomBy(Math.exp(-event.deltaY * 0.0015), point.x, point.y);
  }, { passive: false });

  canvas.addEventListener("keydown", (event) => {
    const step = 60;
    const handled = {
      ArrowLeft: () => renderer.panBy(step, 0),
      ArrowRight: () => renderer.panBy(-step, 0),
      ArrowUp: () => renderer.panBy(0, step),
      ArrowDown: () => renderer.panBy(0, -step),
      "+": () => renderer.zoomBy(1.2),
      "=": () => renderer.zoomBy(1.2),
      "-": () => renderer.zoomBy(1 / 1.2),
      "0": () => renderer.resetView(),
    }[event.key];
    if (handled) {
      event.preventDefault();
      handled();
    }
  });

  function selectAgent(id, follow) {
    renderer.selectedId = id;
    if (id && follow) renderer.focusAgent(id);
    else if (!id) renderer.followId = "";
    if (id) sim.nudgeAgent && null;
    document.dispatchEvent(new CustomEvent("monitor:city-select", { detail: { agentId: id } }));
    publishZones();
  }

  // Toolbar controls.
  const bind = (id, handler) => document.getElementById(id)?.addEventListener("click", handler);
  bind("city-zoom-in", () => renderer.zoomBy(1.25));
  bind("city-zoom-out", () => renderer.zoomBy(1 / 1.25));
  bind("city-zoom-reset", () => renderer.resetView());

  const patrolToggle = document.getElementById("city-patrol-toggle");
  patrolToggle?.addEventListener("click", () => {
    sim.setPaused(!sim.paused);
    patrolToggle.classList.toggle("active", !sim.paused);
    patrolToggle.setAttribute("aria-pressed", String(!sim.paused));
    patrolToggle.textContent = sim.paused ? "Simulation: PAUSED" : "Simulation: RUNNING";
  });
  bind("city-patrol-step", () => sim.skipDwell());

  const pathsToggle = document.getElementById("city-paths-toggle");
  pathsToggle?.addEventListener("click", () => {
    renderer.showPaths = !renderer.showPaths;
    pathsToggle.classList.toggle("active", renderer.showPaths);
    pathsToggle.setAttribute("aria-pressed", String(renderer.showPaths));
    pathsToggle.textContent = renderer.showPaths ? "Paths: ON" : "Paths: OFF";
  });

  document.getElementById("city-speed-select")?.addEventListener("change", (event) => {
    sim.setSpeed(Number.parseFloat(event.target.value));
  });

  const chips = document.getElementById("city-room-chips");
  if (chips) {
    for (const room of map.rooms) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "city-room-chip";
      button.style.setProperty("--chip-accent", room.accent);
      button.textContent = room.name;
      button.addEventListener("click", () => renderer.focusRoom(room.id));
      chips.append(button);
    }
    const all = document.createElement("button");
    all.type = "button";
    all.className = "city-room-chip city-room-chip-all";
    all.textContent = "Whole office";
    all.addEventListener("click", () => renderer.resetView());
    chips.prepend(all);
  }

  // App wiring.
  document.addEventListener("monitor:city-data", (event) => {
    sim.setTasks(event.detail?.latest_by_agent || {});
    schedulePublish();
  });
  document.addEventListener("monitor:city-focus-agent", (event) => {
    const id = event.detail?.agentId;
    if (id) selectAgent(id, true);
  });
  document.addEventListener("monitor:city-visible", () => {
    cityVisible = true;
    window.requestAnimationFrame(() => {
      renderer.resize();
      startLoop();
    });
  });
  document.addEventListener("monitor:city-hidden", () => {
    cityVisible = false;
    stopLoop();
  });
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) stopLoop();
    else startLoop();
  });
  window.addEventListener("pagehide", () => {
    stopLoop();
    resizeObserver?.disconnect();
  });
  reduceMotion.addEventListener?.("change", () => sim.setReducedMotion(reduceMotion.matches));

  publishZones();
  startLoop();

  window.burgerBitesAgentCity = { sim, renderer, map, findPath: (start, goal) => findPath(map, start, goal), focusAgent: (id) => selectAgent(id, true), focusRoom: (id) => renderer.focusRoom(id) };
})();
