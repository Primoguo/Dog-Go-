const STORAGE_KEY = "zilvgou.appState.v1";

const DOGS = [
  {
    id: "shiba",
    name: "小柴",
    breedName: "柴犬",
    tags: ["热血", "直接", "有劲"],
    preview: "今天动起来就赢了，我准备好了。",
    initial: "柴",
  },
  {
    id: "golden",
    name: "阿金",
    breedName: "金毛",
    tags: ["温暖", "稳定", "鼓励"],
    preview: "不用一下子很厉害，我们先稳稳开始。",
    initial: "金",
  },
  {
    id: "border_collie",
    name: "边边",
    breedName: "边牧",
    tags: ["聪明", "敏锐", "督促"],
    preview: "目标要小，动作要真。先完成今天这一项。",
    initial: "边",
  },
  {
    id: "native",
    name: "阿土",
    breedName: "中华田园犬",
    tags: ["踏实", "亲近", "韧性"],
    preview: "慢一点也没事，我陪你把今天接回来。",
    initial: "田",
  },
];

const GOAL_TEMPLATES = {
  fitness: [
    { title: "运动 20 分钟", recovery: "拉伸 3 分钟" },
    { title: "拉伸 10 分钟", recovery: "原地活动 2 分钟" },
  ],
  study: [
    { title: "学习 30 分钟", recovery: "看 1 页" },
    { title: "背单词 20 个", recovery: "背 5 个单词" },
  ],
  sleep: [
    { title: "23:30 前睡觉", recovery: "睡前放下手机 5 分钟" },
    { title: "睡前少刷手机", recovery: "整理明天计划" },
  ],
};

const GOAL_LABELS = {
  fitness: "健身",
  study: "学习",
  sleep: "作息",
};

const COPY = {
  shiba: {
    pending: "来吧，先动一下。",
    tap: "看见你了，准备好没？",
    done: "好，今天拿下。",
    recovery: "断一下不算输。",
    recoveryDone: "好，回来了。",
    longBreak: "目标太重就拆小。",
  },
  golden: {
    pending: "今天先做一点点就好。",
    tap: "你来了，我很开心。",
    done: "你做到了，我看见了。",
    recovery: "昨天没关系，今天还在。",
    recoveryDone: "欢迎回来。",
    longBreak: "我们把目标调轻一点吧。",
  },
  border_collie: {
    pending: "今天只看下一步。",
    tap: "我在，目标还清楚。",
    done: "完成，记录有效。",
    recovery: "昨天偏离，今天恢复。",
    recoveryDone: "恢复动作完成。",
    longBreak: "当前目标阻力偏高。",
  },
  native: {
    pending: "今天咱先做一点。",
    tap: "来啦，我看见你了。",
    done: "好，今天接住了。",
    recovery: "没事，我还在这儿。",
    recoveryDone: "门又打开了。",
    longBreak: "目标大了，咱就改小。",
  },
};

const initialState = {
  version: 1,
  view: "adopt",
  selectedDogId: "native",
  goal: null,
  dogState: {
    intimacy: 0,
    level: 1,
    mood: "expecting",
    fullness: 60,
    cleanliness: 60,
    energy: 60,
    pose: "idle",
  },
  rhythmState: {
    status: "stable",
    currentStreak: 0,
    missedDays: 0,
  },
  checkIns: [],
  lastFeedback: null,
  speechMode: "pending",
};

let state = loadState();
const app = document.querySelector("#app");

function loadState() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return structuredClone(initialState);
    const parsed = JSON.parse(stored);
    if (parsed.version !== 1) return structuredClone(initialState);
    return { ...structuredClone(initialState), ...parsed };
  } catch {
    return structuredClone(initialState);
  }
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function setState(next) {
  state = typeof next === "function" ? next(state) : next;
  saveState();
  render();
}

function dog() {
  return DOGS.find((item) => item.id === state.selectedDogId) || DOGS[0];
}

function todayKey(date = new Date()) {
  const d = new Date(date);
  if (d.getHours() < 4) d.setDate(d.getDate() - 1);
  return d.toISOString().slice(0, 10);
}

function hasMainCheckinToday() {
  const key = todayKey();
  return state.checkIns.some((item) => item.assignedDate === key && item.type === "main");
}

function clamp(value) {
  return Math.max(0, Math.min(100, value));
}

function levelFor(intimacy) {
  if (intimacy >= 140) return 5;
  if (intimacy >= 90) return 4;
  if (intimacy >= 50) return 3;
  if (intimacy >= 20) return 2;
  return 1;
}

function goalRecoveryTitle() {
  if (!state.goal) return "做个小恢复";
  const match = GOAL_TEMPLATES[state.goal.type].find((item) => item.title === state.goal.title);
  return match?.recovery || "做个小恢复";
}

function goalPropLabel() {
  if (state.rhythmState.status === "missed" || state.rhythmState.status === "long_break") return "小门 / 脚印";
  if (!state.goal) return "小院子";
  if (state.goal.type === "fitness") return "运动垫 / 水碗";
  if (state.goal.type === "study") return "书本 / 台灯";
  return "毯子 / 月亮灯";
}

function speechText(mode = state.speechMode) {
  const copy = COPY[dog().id] || COPY.native;
  if (state.rhythmState.status === "long_break") return copy.longBreak;
  if (state.rhythmState.status === "missed") return mode === "done" ? copy.recoveryDone : copy.recovery;
  if (mode === "tap") return copy.tap;
  if (mode === "done") return copy.done;
  if (hasMainCheckinToday()) return copy.done;
  return copy.pending;
}

function button(label, className, onClick, disabled = false) {
  return `<button class="button ${className || ""}" ${disabled ? "disabled" : ""} data-action="${onClick}">${label}</button>`;
}

function render() {
  const views = {
    adopt: renderAdopt,
    "create-goal": renderCreateGoal,
    home: renderHome,
    feedback: renderFeedback,
    progress: renderProgress,
  };
  app.innerHTML = (views[state.view] || renderAdopt)();
  bindActions();
}

function renderAdopt() {
  const selected = state.selectedDogId;
  return `
    <section class="screen">
      <div>
        <p class="eyebrow">自律狗 Web MVP</p>
        <h1>选一只陪你自律的小狗</h1>
        <p class="lede">先选喜欢的，不用管目标类型。它会住进你的小院子，陪你把每天接住。</p>
      </div>
      <div class="dog-grid">
        ${DOGS.map((item) => `
          <button class="dog-card ${selected === item.id ? "is-selected" : ""}" data-action="select-dog" data-dog="${item.id}">
            <div class="dog-face">${item.initial}</div>
            <strong>${item.breedName}</strong>
            <div class="tags">${item.tags.map((tag) => `<span class="tag">${tag}</span>`).join("")}</div>
          </button>
        `).join("")}
      </div>
      <div class="panel">
        <p class="eyebrow">预览</p>
        <h2>${dog().preview}</h2>
        <p class="lede">${dog().breedName}只影响语气和形象，所有目标都能陪你完成。</p>
      </div>
      <div class="footer-actions">
        ${button("领养它", "", "go-create-goal")}
        <p class="small">游客可先体验，登录保存先不做。</p>
      </div>
    </section>
  `;
}

function renderCreateGoal() {
  const goalType = state.goalDraft?.type || "fitness";
  const selectedTitle = state.goalDraft?.title || GOAL_TEMPLATES[goalType][0].title;
  return `
    <section class="screen">
      <div class="topbar">
        <div>
          <p class="eyebrow">${dog().breedName}已经住进小院子</p>
          <h1>先定一个今天能开始的目标</h1>
          <p class="lede">首版默认推荐健身，也可以切到学习或作息。</p>
        </div>
      </div>
      <div class="panel stack">
        <div>
          <p class="eyebrow">场景</p>
          <div class="segmented">
            ${Object.entries(GOAL_LABELS).map(([type, label]) => `
              <button class="segment ${goalType === type ? "is-selected" : ""}" data-action="select-goal-type" data-type="${type}">${label}</button>
            `).join("")}
          </div>
        </div>
        <div>
          <p class="eyebrow">推荐模板</p>
          <div class="template-list">
            ${GOAL_TEMPLATES[goalType].map((template) => `
              <button class="template-card ${selectedTitle === template.title ? "is-selected" : ""}" data-action="select-template" data-title="${template.title}">${template.title}<br><span class="small">恢复任务：${template.recovery}</span></button>
            `).join("")}
          </div>
        </div>
        <div class="field">
          <label for="goal-title">目标名称</label>
          <input id="goal-title" class="input" value="${selectedTitle}" data-role="goal-title" />
        </div>
      </div>
      <div class="footer-actions">
        ${button("开始今天的节奏", "", "create-goal")}
        ${button("返回选狗", "secondary", "go-adopt")}
      </div>
    </section>
  `;
}

function renderHome() {
  if (!state.goal) return renderCreateGoal();
  const done = hasMainCheckinToday();
  const rhythm = state.rhythmState.status;
  const isRecovery = rhythm === "missed" || rhythm === "long_break";
  const goalTitle = isRecovery ? goalRecoveryTitle() : state.goal.title;
  const statusText = rhythm === "long_break" ? "建议调小" : isRecovery ? "恢复任务" : done ? "已完成" : "今天未完成";
  const sceneClass = done ? "is-done" : isRecovery ? "is-recovery" : "";
  return `
    <section class="screen home-screen">
      <div class="topbar">
        <div>
          <p class="eyebrow">${done ? "今天完成了" : isRecovery ? "节奏有点乱，没关系" : greeting()}</p>
          <h2>${done ? "明天我们继续" : isRecovery ? "今天做小一点" : "今天也慢慢来"}</h2>
        </div>
        ${button("进度", "ghost", "go-progress")}
      </div>
      <section class="scene ${sceneClass}" data-action="tap-dog">
        <img src="./assets/dog-world-yard.png" alt="温暖的小院子里，一只狗狗在等你" />
        <div class="speech">${speechText()}</div>
        <div class="scene-chip">${dog().breedName} · ${goalPropLabel()}</div>
      </section>
      <section class="panel goal-panel">
        <div class="goal-title-row">
          <div>
            <p class="eyebrow">${isRecovery ? "今日恢复任务" : "今日目标"}</p>
            <div class="goal-name">${goalTitle}</div>
          </div>
          <span class="status-pill">${statusText}</span>
        </div>
        ${rhythm === "long_break" ? `<p class="lede">最近目标可能有点重，先从更容易的一步回来。</p>` : ""}
        ${button(done ? "今天已完成" : isRecovery ? "做个小恢复" : "完成今天", "", isRecovery ? "complete-recovery" : "complete-main", done)}
        ${rhythm === "long_break" ? button("使用小目标", "secondary", "use-small-goal") : ""}
        <div>
          <p class="eyebrow">本周节奏</p>
          ${renderWeekDots()}
        </div>
        <div class="summary-row">
          <span>亲密度 Lv.${state.dogState.level} · ${state.dogState.intimacy}/${nextLevelNeed()}</span>
          <button class="button ghost" data-action="simulate-missed">模拟漏一天</button>
        </div>
      </section>
      <div class="debug-row">
        <button class="button ghost" data-action="reset">重置体验</button>
      </div>
    </section>
  `;
}

function renderFeedback() {
  const feedback = state.lastFeedback || {
    message: speechText("done"),
    gains: [{ label: "亲密度", amount: 3 }],
  };
  return `
    <section class="screen">
      <div class="feedback-hero panel">
        <div class="big-badge">${dog().initial}</div>
        <div>
          <p class="eyebrow">${dog().breedName}回应了你</p>
          <h1>${feedback.message}</h1>
          <p class="lede">这一步会留在你们的小院子里。</p>
        </div>
        <div class="gain-list">
          ${feedback.gains.map((gain) => `<div class="gain"><span>${gain.label}</span><span>+${gain.amount}</span></div>`).join("")}
        </div>
      </div>
      <div class="footer-actions">
        ${button("看今天的进度", "", "go-progress")}
        ${button("回首页", "secondary", "go-home")}
      </div>
    </section>
  `;
}

function renderProgress() {
  const { dogState } = state;
  return `
    <section class="screen">
      <div class="topbar">
        <div>
          <p class="eyebrow">我和${dog().breedName}的进度</p>
          <h1>这段节奏正在累积</h1>
        </div>
      </div>
      <div class="panel stack">
        <div>
          <div class="summary-row"><strong>Lv.${dogState.level}</strong><span>亲密度 ${dogState.intimacy}/${nextLevelNeed()}</span></div>
          <div class="bar"><span style="width:${Math.min(100, (dogState.intimacy / nextLevelNeed()) * 100)}%"></span></div>
        </div>
        <div>
          <p class="eyebrow">近 7 天</p>
          ${renderWeekDots()}
        </div>
        <div class="progress-grid">
          ${metric("心情", moodLabel())}
          ${metric("饱腹", dogState.fullness)}
          ${metric("清洁", dogState.cleanliness)}
          ${metric("精力", dogState.energy)}
        </div>
      </div>
      <div class="footer-actions">
        ${button("回首页", "", "go-home")}
      </div>
    </section>
  `;
}

function metric(label, value) {
  return `<div class="metric"><span class="small">${label}</span><strong>${value}</strong></div>`;
}

function renderWeekDots() {
  const days = Array.from({ length: 7 }, (_, index) => {
    const key = new Date();
    key.setDate(key.getDate() - (6 - index));
    const assigned = todayKey(key);
    return state.checkIns.some((item) => item.assignedDate === assigned)
      ? `<span class="dot is-done"></span>`
      : `<span class="dot"></span>`;
  });
  return `<div class="week-dots">${days.join("")}</div>`;
}

function greeting() {
  const hour = new Date().getHours();
  if (hour < 11) return "早上好";
  if (hour < 18) return "下午好";
  return "晚上好";
}

function nextLevelNeed() {
  const level = state.dogState.level;
  if (level === 1) return 20;
  if (level === 2) return 50;
  if (level === 3) return 90;
  return 140;
}

function moodLabel() {
  const labels = {
    expecting: "期待",
    happy: "开心",
    focused: "专注",
    calm: "平静",
    waiting: "等待",
    recovering: "恢复中",
  };
  return labels[state.dogState.mood] || "期待";
}

function bindActions() {
  app.querySelectorAll("[data-action]").forEach((node) => {
    node.addEventListener("click", () => handleAction(node.dataset.action, node));
  });
}

function handleAction(action, node) {
  if (action === "select-dog") {
    setState((prev) => ({ ...prev, selectedDogId: node.dataset.dog }));
  }
  if (action === "go-create-goal") {
    setState((prev) => ({ ...prev, view: "create-goal", goalDraft: { type: "fitness", title: GOAL_TEMPLATES.fitness[0].title } }));
  }
  if (action === "go-adopt") {
    setState((prev) => ({ ...prev, view: "adopt" }));
  }
  if (action === "select-goal-type") {
    const type = node.dataset.type;
    setState((prev) => ({ ...prev, goalDraft: { type, title: GOAL_TEMPLATES[type][0].title } }));
  }
  if (action === "select-template") {
    setState((prev) => ({ ...prev, goalDraft: { ...(prev.goalDraft || { type: "fitness" }), title: node.dataset.title } }));
  }
  if (action === "create-goal") {
    const input = app.querySelector("[data-role='goal-title']");
    const draft = state.goalDraft || { type: "fitness", title: GOAL_TEMPLATES.fitness[0].title };
    const title = input?.value?.trim() || draft.title;
    setState((prev) => ({
      ...prev,
      view: "home",
      goal: {
        id: `goal-${Date.now()}`,
        type: draft.type,
        title,
        frequency: "daily",
        isPaused: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      speechMode: "pending",
    }));
  }
  if (action === "tap-dog") {
    setState((prev) => ({ ...prev, speechMode: "tap" }));
  }
  if (action === "complete-main") {
    completeMain();
  }
  if (action === "complete-recovery") {
    completeRecovery();
  }
  if (action === "go-progress") {
    setState((prev) => ({ ...prev, view: "progress" }));
  }
  if (action === "go-home") {
    setState((prev) => ({ ...prev, view: "home", speechMode: "pending" }));
  }
  if (action === "simulate-missed") {
    setState((prev) => ({
      ...prev,
      rhythmState: { ...prev.rhythmState, status: "missed", missedDays: 1 },
      dogState: { ...prev.dogState, mood: "waiting", pose: "waiting" },
      speechMode: "pending",
    }));
  }
  if (action === "use-small-goal") {
    setState((prev) => ({
      ...prev,
      goal: { ...prev.goal, title: goalRecoveryTitle(), updatedAt: new Date().toISOString() },
      rhythmState: { ...prev.rhythmState, status: "stable", missedDays: 0 },
      dogState: { ...prev.dogState, mood: "expecting", pose: "idle" },
    }));
  }
  if (action === "reset") {
    localStorage.removeItem(STORAGE_KEY);
    state = structuredClone(initialState);
    render();
  }
}

function completeMain() {
  if (!state.goal || hasMainCheckinToday()) return;
  const gains = gainsForGoal(state.goal.type);
  updateAfterCompletion("main", COPY[dog().id].done, gains);
}

function completeRecovery() {
  const gains = [
    { label: "亲密度", amount: 2 },
    { label: "饱腹", amount: 10 },
    { label: "清洁", amount: 10 },
    { label: "精力", amount: 10 },
  ];
  updateAfterCompletion("recovery", COPY[dog().id].recoveryDone, gains);
}

function updateAfterCompletion(type, message, gains) {
  const checkIn = {
    id: `checkin-${Date.now()}`,
    goalId: state.goal.id,
    type,
    status: "completed",
    completedAt: new Date().toISOString(),
    assignedDate: todayKey(),
  };
  const nextDogState = { ...state.dogState };
  gains.forEach((gain) => {
    if (gain.label === "亲密度") nextDogState.intimacy += gain.amount;
    if (gain.label === "饱腹") nextDogState.fullness = clamp(nextDogState.fullness + gain.amount);
    if (gain.label === "清洁") nextDogState.cleanliness = clamp(nextDogState.cleanliness + gain.amount);
    if (gain.label === "精力") nextDogState.energy = clamp(nextDogState.energy + gain.amount);
  });
  nextDogState.level = levelFor(nextDogState.intimacy);
  nextDogState.mood = type === "recovery" ? "recovering" : "happy";
  nextDogState.pose = "happy";
  setState((prev) => ({
    ...prev,
    view: "feedback",
    checkIns: [...prev.checkIns, checkIn],
    dogState: nextDogState,
    rhythmState: {
      ...prev.rhythmState,
      status: type === "recovery" ? "recovering" : "stable",
      currentStreak: prev.rhythmState.currentStreak + 1,
      missedDays: 0,
      lastCompletedDate: todayKey(),
    },
    lastFeedback: { eventType: type === "recovery" ? "recovery_done" : "checkin_done", message, gains },
    speechMode: "done",
  }));
}

function gainsForGoal(type) {
  if (type === "fitness") {
    return [
      { label: "亲密度", amount: 3 },
      { label: "饱腹", amount: 15 },
      { label: "精力", amount: 20 },
    ];
  }
  if (type === "study") {
    return [
      { label: "亲密度", amount: 3 },
      { label: "饱腹", amount: 10 },
      { label: "精力", amount: 10 },
    ];
  }
  return [
    { label: "亲密度", amount: 3 },
    { label: "清洁", amount: 20 },
    { label: "精力", amount: 15 },
  ];
}

render();
