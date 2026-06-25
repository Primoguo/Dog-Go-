# 自律狗数据模型 v1

来源：[Web MVP 原型准备](./web-mvp-prototype-plan.md)

## 目标

定义 Web MVP 原型所需的最小数据结构。首版只支持本地存储，不接后端。

## AppState

```ts
type AppState = {
  version: 1;
  currentView: "adopt" | "create-goal" | "home" | "feedback" | "progress";
  userMode: "guest" | "authenticated";
  selectedDog?: DogProfile;
  goal?: Goal;
  dogState: DogState;
  rhythmState: RhythmState;
  checkIns: CheckIn[];
  lastFeedback?: FeedbackState;
};
```

## DogProfile

```ts
type DogProfile = {
  id: "shiba" | "golden" | "border_collie" | "native";
  name: string;
  breedName: string;
  personalityTags: string[];
  tone: string;
  appearanceSeed: string;
  palette: DogPalette;
};

type DogPalette = {
  primaryFur: string;
  secondaryFur: string;
  marking: "none" | "forehead" | "ears" | "tail_tip" | "paws" | "back_patch";
  collar: string;
};
```

首发数据：

| id | breedName | personalityTags |
| --- | --- | --- |
| `shiba` | 柴犬 | 热血、直接、有劲 |
| `golden` | 金毛 | 温暖、稳定、鼓励 |
| `border_collie` | 边牧 | 聪明、敏锐、督促 |
| `native` | 中华田园犬 | 踏实、亲近、韧性 |

外观规则：

- 用户选择的是品种，系统为每条狗生成稳定随机的 `appearanceSeed`。
- `appearanceSeed` 决定配色组合，保证同一条狗每次打开外观一致。
- 同品种狗狗也可以有不同主毛色、次毛色、斑纹和项圈色。
- 随机外观不能破坏品种识别。
- MVP 可先实现主毛色、次毛色、项圈色三项。

## Goal

```ts
type Goal = {
  id: string;
  type: "fitness" | "study" | "sleep";
  title: string;
  frequency: "daily" | "weekdays" | "custom";
  reminderTime?: string;
  isPaused: boolean;
  createdAt: string;
  updatedAt: string;
};
```

模板：

| type | title | recoveryTitle |
| --- | --- | --- |
| `fitness` | 运动 20 分钟 | 拉伸 3 分钟 |
| `fitness` | 拉伸 10 分钟 | 原地活动 2 分钟 |
| `study` | 学习 30 分钟 | 看 1 页 |
| `study` | 背单词 20 个 | 背 5 个单词 |
| `sleep` | 23:30 前睡觉 | 睡前放下手机 5 分钟 |
| `sleep` | 睡前少刷手机 | 整理明天计划 |

## CheckIn

```ts
type CheckIn = {
  id: string;
  goalId: string;
  type: "main" | "recovery";
  status: "completed";
  note?: string;
  mood?: "easy" | "ok" | "tired";
  completedAt: string;
  assignedDate: string;
};
```

规则：

- 同一 `goalId` + `assignedDate` + `type` 不重复加奖励。
- `completedAt` 保存真实时间。
- `assignedDate` 保存归属日期。
- 日期结算建议使用本地时区，凌晨 4:00 前归属前一天。

## DogState

```ts
type DogState = {
  intimacy: number;
  level: number;
  mood: "expecting" | "happy" | "focused" | "calm" | "waiting" | "recovering";
  fullness: number;
  cleanliness: number;
  energy: number;
  pose: "idle" | "happy" | "waiting" | "focused";
};
```

初始值：

```ts
const initialDogState = {
  intimacy: 0,
  level: 1,
  mood: "expecting",
  fullness: 60,
  cleanliness: 60,
  energy: 60,
  pose: "idle",
};
```

约束：

- `intimacy` 不下降。
- `level` 不下降。
- `fullness`、`cleanliness`、`energy` 限制在 0-100。

等级规则：

| level | intimacy |
| --- | --- |
| 1 | 0 |
| 2 | 20 |
| 3 | 50 |
| 4 | 90 |
| 5 | 140 |

## RhythmState

```ts
type RhythmState = {
  status: "stable" | "missed" | "recovering" | "long_break" | "paused";
  currentStreak: number;
  weekCompletionRate: number;
  lastCompletedDate?: string;
  missedDays: number;
};
```

状态规则：

| status | 条件 |
| --- | --- |
| `stable` | 正常完成或无中断 |
| `missed` | 昨天未完成 |
| `recovering` | 已完成恢复任务，等待回到稳定 |
| `long_break` | 连续 3 天以上未完成 |
| `paused` | 用户暂停目标 |

## FeedbackState

```ts
type FeedbackState = {
  eventType: "checkin_done" | "recovery_done" | "streak_3" | "streak_7";
  message: string;
  gains: StateGain[];
};

type StateGain = {
  label: "亲密度" | "饱腹" | "清洁" | "精力";
  amount: number;
};
```

## 状态更新函数

建议实现这些纯函数：

```ts
getAssignedDate(now: Date): string
clampStat(value: number): number
calculateLevel(intimacy: number): number
getRecoveryGoal(goal: Goal): string
getRhythmState(checkIns: CheckIn[], goal: Goal, now: Date): RhythmState
completeMainGoal(state: AppState, now: Date): AppState
completeRecoveryGoal(state: AppState, now: Date): AppState
selectFeedbackMessage(state: AppState, eventType: string): string
```

## localStorage

Key：

```text
zilvgou.appState.v1
```

读取失败策略：

- 如果没有数据，使用初始状态。
- 如果 JSON 解析失败，重置为初始状态。
- 如果版本不匹配，后续可做迁移；MVP 先重置。

## 初始状态

```ts
const initialAppState: AppState = {
  version: 1,
  currentView: "adopt",
  userMode: "guest",
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
    weekCompletionRate: 0,
    missedDays: 0,
  },
  checkIns: [],
};
```
