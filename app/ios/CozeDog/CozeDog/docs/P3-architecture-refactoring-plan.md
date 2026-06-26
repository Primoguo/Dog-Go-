# P3 架构重构方案 — Dog Go (自律狗)

> **状态**: 待审核 · 待实施
> **编写日期**: 2026-06-26
> **前置条件**: P0-P2 共 112 项任务已全部完成，项目处于稳定状态
> **预估工期**: 3-5 天（分 4 个阶段，每阶段独立可验证）

---

## 一、问题概述

经过 7 轮迭代审计，P0（崩溃/数据丢失）、P1（功能缺陷）、P2（性能/体验）问题已全部清零。剩余的 P3 是**架构层面的可维护性问题**，不影响当前功能，但会显著增加后续开发和维护的成本：

| 问题 | 现状 | 影响 |
|------|------|------|
| **AppStore 上帝对象** | 单文件 1583 行，管理全部业务逻辑 | 修改任何功能都需要理解整个文件；合并冲突概率高；无法独立测试各模块 |
| **巨型 View Body** | 28 个 View 结构体 body > 50 行，最大 227 行 | SwiftUI 编译慢；diff 难读；复用性差 |
| **魔法数字** | SceneViews/SceneProps 中大量 `size * 0.xx` 比例值无命名 | 可读性差；调整布局时难以理解意图 |

---

## 二、重构范围

### 2.1 AppStore 拆分

**当前结构**: `AppStore.swift` — 1583 行，1 个 class，~80 个方法

**目标结构**: 1 个协调器 + 6 个领域管理器

```
AppStore (协调器，~200 行)
├── DogStateManager      — 狗狗状态、属性、收集、进化
├── SessionManager       — 专注计时、行动会话、休息、通知
├── HabitTracker         — 打卡记录、连续天数、成就、月报
├── TaskRecommender      — 任务推荐、自定义任务、任务历史
├── DiaryManager         — 日记生成、日记查询
└── SpeechService        — 品种台词、文案表（纯函数，无状态）
```

#### 各管理器职责详解

**DogStateManager (~250 行)**
```
职责: 狗狗的生命周期状态
@property: dogState, dogCollection, selectedDog, dogAppearance,
           activeCompanionId, availableAdoptions, dogEvolution, totalMainCheckIns
方法:
  - selectDog / randomizeAppearance / collectDog
  - setCompanion / removeCompanion / currentDogAppearance
  - checkEvolution / updateDogMood / applyDailyDecay
  - useItem / interactSceneProp (含冷却逻辑)
  - 属性相关: intimacy, level, fullness, cleanliness, energy, mood, inventory
```

**SessionManager (~200 行)**
```
职责: 专注/行动会话的完整生命周期
@property: actionSession, isFocusMode, focusStartTime, isResting,
           restStartTime, lastEncouragementProgress, focusSessions,
           focusSessionsCount, totalFocusMinutes, longestFocusSession
方法:
  - openDogGo / selectActionPlan / startActionTimer / tickActionTimer
  - cancelActionSession / completeActionSession
  - enterFocusMode / startRest / endRest
  - completeFocusSession / abandonFocusSession
  - scheduleFocusNotifications / cancelFocusNotifications
  - checkAndShowEncouragement / encouragementCopy
  - dogGoGains / completedPlanTitle (纯计算)
```

**HabitTracker (~250 行)**
```
职责: 打卡聚合、连续天数、成就系统、月度报告
@property: checkIns, rhythmState, achievements, monthlyReports
方法:
  - complete(type:message:gains:completedPlanTitle:) — 核心完成流程
  - completeMainGoal / completeRecoveryGoal
  - hasMainCheckInToday / todayCompletedPlanTitles
  - aggregateCheckInRecords / getCheckIns / hasCheckIn
  - calculateCurrentStreak / calculateLongestStreak
  - calculateMonthlyCompletionRate / getMonthlyCheckInCount
  - checkAndUnlockAchievements / hasAchievement
  - generateMonthlyReport / persistMonthlyReport
  - getStreakRecoveryMessage / getRecentCheckInsCount
  - checkStreakOnLaunch / weekCompletion
```

**TaskRecommender (~150 行)**
```
职责: 智能任务推荐、自定义任务管理
@property: taskHistory, customTasks, lastTaskRecommendationDate
方法:
  - recommendTasks / calculateTaskScore
  - acceptTaskSuggestion / completeTaskSuggestion
  - addCustomTask / toggleTaskFavorite / deleteCustomTask
  - getTodayTaskStats / getTaskStreak
```

**DiaryManager (~80 行)**
```
职责: 每日日记生成与查询
@property: diaryEntries, lastDiaryDate
方法:
  - generateDailyDiaryIfNeeded / generateDiaryContent
  - getRecentDiaryEntries
```

**SpeechService (~80 行)**
```
职责: 品种相关的文案生成（纯函数，无 @Published）
@property: speechMode (保留在 AppStore 或移入此处)
方法:
  - speechText / recoveryTitle / copy(for:)
  - static copyTable
```

#### 核心难点: `complete(type:)` 方法的拆分

`complete(type:message:gains:completedPlanTitle:)` (L434-495) 是最大的跨切面方法，它同时修改:
- checkIns (HabitTracker)
- dogState 属性 (DogStateManager)
- rhythmState (HabitTracker)
- evolution (DogStateManager)
- achievements (HabitTracker)
- diary (DiaryManager)
- feedback/navigation (AppStore)

**拆分策略**: 在 AppStore 协调器中保留 `complete()` 作为编排方法，通过调用各管理器的接口完成：

```swift
// AppStore 协调器中
func complete(type: CheckInType, message: String, gains: StatGains, completedPlanTitle: String?) {
    let date = habitTracker.assignedDate(for: Date())

    // 1. 记录打卡
    habitTracker.recordCheckIn(type: type, date: date, title: completedPlanTitle)

    // 2. 更新狗狗属性
    dogStateManager.applyGains(gains)

    // 3. 更新节奏
    habitTracker.updateRhythm(date: date)

    // 4. 检查进化
    dogStateManager.checkEvolution()

    // 5. 检查成就
    habitTracker.checkAndUnlockAchievements()

    // 6. 更新心情
    dogStateManager.updateDogMood()

    // 7. 生成日记
    diaryManager.generateDailyDiaryIfNeeded(...)

    // 8. 反馈 & 导航
    state.lastFeedback = FeedbackEvent(...)
    state.screen = .home
}
```

#### AppState 结构体拆分

与 Store 拆分同步，将 `AppState` 拆分为子结构体：

```swift
struct AppState: Codable {
    var schemaVersion: Int = 2
    var screen: Screen = .onboarding
    var dogProfile: DogProfile          // 狗狗身份 + 属性
    var dogCollection: DogCollection    // 收集 + 伴侣
    var goal: Goal?
    var checkIns: [CheckIn] = []
    var rhythm: RhythmState             // 连续天数 + 节奏
    var actionSession: ActionSession?
    var focus: FocusState               // 专注模式状态
    var scene: SceneSettings
    var evolution: EvolutionState
    var diary: DiaryState
    var tasks: TaskState
    var achievements: [Achievement] = []
    var monthlyReports: [MonthlyReport] = []
    var lastFeedback: FeedbackEvent?
}
```

每个子结构体独立 `Codable`，方便单独测试和未来迁移。

---

### 2.2 大型 View Body 提取

**共 28 个 View 结构体 body > 50 行**，按优先级排序：

#### 第一梯队（> 100 行，必须拆分）

| 结构体 | 文件 | Body 行数 | 总行数 | 提取方案 |
|--------|------|-----------|--------|----------|
| `DogWorldScene` | Components.swift | 227 | ~430 | 拆为 DogSpriteButton + CompanionDogView + SceneOverlayViews；runDogWorldLoop 移入 ViewModel |
| `PixelDogSprite` | Components.swift | 194 | ~670 | 拆为 BreedEarsView + MoodEyesView + MoodMouthView + EvolutionDecorationsView |
| `DogDogView` | AppViews.swift | 145 | 145 | 拆为 AdoptionBanner + CompanionPanel + CollectedDogsGrid |
| `FocusModeView` | AppViews.swift | 139 | 139 | 拆为 FocusHeaderBar + FocusDogSpriteView + FocusCountdownView |
| `DogHomeView` | AppViews.swift | 136 | 136 | 拆为 SceneSelectorPanel + InventoryGrid + ToastOverlay |
| `ProgressScreen` | AppViews.swift | 113 | 113 | 拆为 EvolutionPanel + MoodPanel + StatsPanel + NavigationButtons |
| `TodayActionPanel` | Components.swift | 104 | ~281 | 每个 phase case 提取为独立 View（IdleActionView / ChoosingPlanView / RunningActionView 等） |
| `CreateGoalView` | AppViews.swift | 104 | 104 | 拆为 GreetingHeader + SceneTypeSelector + TemplateList + GoalNameField |

#### 第二梯队（50-99 行，建议拆分）

| 结构体 | 文件 | Body 行数 | 提取方案 |
|--------|------|-----------|----------|
| `AdoptionView` | AppViews.swift | 94 | 拆为 BreedGrid + BreedPreviewPanel |
| `PixelCelebrationPanel` | Components.swift | 92 | 拆为 CelebrationStage + GainsList + MeterRow |
| `DogStatusTray` | Components.swift | 86 | 拆为 StatusHeaderRow + StatBarsRow |
| `AdoptDogView` | AppViews.swift | 84 | 拆为 HeaderBlock + DogPreviewPanel |
| `TaskCardView` | InteractiveViews.swift | 78 | 拆为 GoalTypeBadge + TaskInfoBlock + AcceptButton |
| `SceneSelectorView` | InteractiveViews.swift | 76 | 拆为 SceneList + EnvironmentInfo |
| `YardSceneView` | SceneViews.swift | 76 | 拆为 FenceGroup + HouseTreeCluster + InteractiveProps |
| `FocusStatsView` | AppViews.swift | 76 | 拆为 SummaryStats + RecentSessionsList |
| `RestModeView` | AppViews.swift | 75 | 拆为 RestHeader + CountdownGroup + EndButton |
| `ForestSceneView` | SceneViews.swift | 71 | 拆为 ForestCanopy + MushroomRow + SparklesOverlay |
| `DogChoiceCard` | Components.swift | 68 | 拆为 SpritePreview + TagsRow |
| `PixelDogActivityCue` | Components.swift | 65 | 将 symbol/color 逻辑移入 enum model |
| `PixelProps` | Components.swift | 61 | 每个 goalType case 提取为独立 View |
| `YardHouseView` | SceneViews.swift | 61 | 拆为 HouseWalls + HouseDoorsWindows + HouseRooftop |
| `BeachSceneView` | SceneViews.swift | 56 | 拆为 WaveAnimation + PalmTrees + ShellRow |
| `SceneCardView` | InteractiveViews.swift | 57 | 拆为 IconCircle + InfoBlock + UnlockBadge |
| `CustomTaskSheet` | InteractiveViews.swift | 58 | 拆为 FormSections |
| `TaskSuggestionView` | InteractiveViews.swift | 62 | 4 个 computed property 提升为独立 View struct |
| `SceneThumbnailView` | SceneViews.swift | ~347 总 | 4 个 thumbnail computed property 提升为独立 View struct |

---

### 2.3 魔法数字命名

**范围**: SceneViews.swift + SceneProps.swift 中的比例常量

**现状示例**:
```swift
// SceneProps.swift — 无法理解这些数字代表什么
.frame(width: size * 0.35, height: size * 0.28)
.offset(x: size * 0.02, y: -size * 0.15)
```

**改造方案**: 在 SceneProps.swift 顶部引入命名常量

```swift
// SceneProps.swift
private enum SceneLayout {
    // 庭院
    static let yardHouseWidthRatio: CGFloat = 0.35
    static let yardHouseHeightRatio: CGFloat = 0.28
    static let yardHouseOffsetX: CGFloat = 0.02
    static let yardHouseOffsetY: CGFloat = -0.15
    // ... 其他场景类似
}
```

**注意**: 此项优先级最低，且需要逐个场景对照视觉确认。建议在 Phase 3 完成后逐步进行。

---

## 三、实施计划

### Phase 1: AppState 结构体拆分（低风险，~0.5 天）

> 目标: 将 `AppState` 大结构体拆为子结构体，不改变任何逻辑

| # | 任务 | 文件 | 验证 |
|---|------|------|------|
| 1.1 | 定义子结构体: `DogProfile`, `DogCollection`, `RhythmState`, `FocusState`, `EvolutionState`, `DiaryState`, `TaskState` | Models/AppModels.swift | 编译通过 |
| 1.2 | 更新 `AppState` 使用子结构体，添加兼容的 computed property 访问器 | Models/AppModels.swift | 编译通过 |
| 1.3 | 更新 `migrateIfNeeded()` 处理新旧格式兼容 | Models/AppModels.swift | 旧数据可加载 |
| 1.4 | 更新 schemaVersion 至 3 | Models/AppModels.swift | — |

**风险控制**: 在 `AppState` 上保留旧的 computed property（如 `var dogState: DogProfile`），让 AppStore 中的代码无需一次性全部修改。后续 Phase 逐步切换到新路径。

---

### Phase 2: AppStore 拆分（中风险，~2 天）

> 目标: 将 AppStore 拆为 1 协调器 + 6 管理器

| # | 任务 | 文件 | 验证 |
|---|------|------|------|
| 2.1 | 创建 `Store/SpeechService.swift`，迁移 copy 相关方法 | 新文件 | 编译通过 |
| 2.2 | 创建 `Store/DiaryManager.swift`，迁移日记相关方法 | 新文件 | 编译通过 |
| 2.3 | 创建 `Store/TaskRecommender.swift`，迁移任务推荐方法 | 新文件 | 编译通过 |
| 2.4 | 创建 `Store/HabitTracker.swift`，迁移打卡/连续/成就方法 | 新文件 | 编译通过 |
| 2.5 | 创建 `Store/SessionManager.swift`，迁移专注/行动会话方法 | 新文件 | 编译通过 |
| 2.6 | 创建 `Store/DogStateManager.swift`，迁移狗狗状态方法 | 新文件 | 编译通过 |
| 2.7 | 重构 `AppStore` 为协调器，持有各管理器实例，保留 `complete()` 编排 | Store/AppStore.swift | 全功能回归 |
| 2.8 | 更新所有 View 中的 `@EnvironmentObject var store: AppStore` 引用 | 全部 View 文件 | 编译通过 |
| 2.9 | 删除 `AppStore` 中已迁移的方法，确认无残留 | Store/AppStore.swift | 编译通过 + 功能回归 |

**关键决策**: View 层仍通过 `AppStore` 访问数据（AppStore 暴露各管理器作为 property），避免大规模修改 View 的 `@EnvironmentObject` 引用。

```swift
// AppStore 协调器
class AppStore: ObservableObject {
    let dogState: DogStateManager
    let session: SessionManager
    let habit: HabitTracker
    let tasks: TaskRecommender
    let diary: DiaryManager
    let speech: SpeechService

    // 便捷访问（View 层无需改动）
    var state: AppState { ... }  // 聚合各管理器状态

    func save() { persistence.save(state) }
}
```

---

### Phase 3: 大型 View Body 提取（低风险，~1.5 天）

> 目标: 将 28 个大型 View 拆为可复用子 View

**执行顺序**: 先拆第一梯队（8 个），再拆第二梯队（20 个）

| # | 任务 | 文件 | 验证 |
|---|------|------|------|
| 3.1 | 拆分 `PixelDogSprite`（~670 行 → 5 个子 View） | Components.swift | 编译通过 + 视觉检查 |
| 3.2 | 拆分 `DogWorldScene`（~430 行 → 3 个子 View + ViewModel） | Components.swift | 编译通过 + 功能回归 |
| 3.3 | 拆分 `TodayActionPanel`（~281 行 → 5 个 phase View） | Components.swift | 编译通过 + 功能回归 |
| 3.4 | 拆分 `DogDogView` / `DogHomeView` / `FocusModeView` | AppViews.swift | 编译通过 |
| 3.5 | 拆分 `ProgressScreen` / `CreateGoalView` / `AdoptionView` / `AdoptDogView` | AppViews.swift | 编译通过 |
| 3.6 | 拆分 `SceneThumbnailView`（4 个 thumbnail → 独立 View） | SceneViews.swift | 编译通过 + 视觉检查 |
| 3.7 | 拆分剩余场景 View（Yard/Park/Beach/Forest 各子组件） | SceneViews.swift | 编译通过 |
| 3.8 | 拆分交互 View（TaskSuggestion/TaskCard/SceneSelector 等） | InteractiveViews.swift | 编译通过 |
| 3.9 | 拆分剩余组件（CelebrationPanel/StatusTray/ChoiceCard 等） | Components.swift | 编译通过 |

---

### Phase 4: 魔法数字命名（低风险，~0.5 天）

> 目标: 为场景布局比例值添加语义化命名

| # | 任务 | 文件 | 验证 |
|---|------|------|------|
| 4.1 | SceneProps.swift: 定义 `SceneLayout` enum，命名所有比例常量 | SceneProps.swift | 编译通过 |
| 4.2 | SceneProps.swift: 替换所有 `size * 0.xx` 为常量引用 | SceneProps.swift | 视觉无变化 |
| 4.3 | SceneViews.swift: 替换硬编码比例值为常量 | SceneViews.swift | 视觉无变化 |

---

## 四、风险评估

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| AppState 拆分后旧数据无法加载 | **高** | 在 `migrateIfNeeded()` 中添加 v2→v3 迁移逻辑；保留旧字段的 fallback decoder |
| AppStore 拆分后状态不一致 | **高** | 协调器统一管理 save()；各管理器不独立持久化；拆分后全功能回归测试 |
| View 拆分后布局偏移 | **中** | 每拆一个 View 后立即视觉检查；使用 Xcode Preview 对比 |
| 合并冲突（如有并行开发） | **中** | Phase 1-2 改动集中在 Store/Models，Phase 3 改动集中在 Views，可分批提交 |
| 编译时间增加（文件增多） | **低** | 文件拆分后每个文件更小，Swift 增量编译更高效 |

---

## 五、验收标准

- [ ] `AppStore.swift` 行数 < 250 行
- [ ] 无单个 View body > 100 行
- [ ] `xcodebuild build` 零错误零警告
- [ ] 全功能回归: 领养 → 设定目标 → 打卡 → 专注 → 查看日记/成就/月报 全流程正常
- [ ] 旧版本数据升级后无丢失（schemaVersion 2 → 3 迁移验证）
- [ ] 所有场景视觉无变化（PixelDogSprite 拆分后逐品种检查）

---

## 六、文件变更清单

| 操作 | 文件 | 预估变化 |
|------|------|----------|
| 新建 | `Store/DogStateManager.swift` | ~250 行 |
| 新建 | `Store/SessionManager.swift` | ~200 行 |
| 新建 | `Store/HabitTracker.swift` | ~250 行 |
| 新建 | `Store/TaskRecommender.swift` | ~150 行 |
| 新建 | `Store/DiaryManager.swift` | ~80 行 |
| 新建 | `Store/SpeechService.swift` | ~80 行 |
| 大幅修改 | `Store/AppStore.swift` | 1583 → ~200 行 |
| 大幅修改 | `Models/AppModels.swift` | AppState 拆分子结构体 |
| 修改 | `Components/Components.swift` | 拆分 6 个大 View |
| 修改 | `Views/AppViews.swift` | 拆分 10 个大 View |
| 修改 | `Views/SceneViews.swift` | 拆分 5 个大 View + 命名常量 |
| 修改 | `Views/InteractiveViews.swift` | 拆分 5 个大 View |

**净效果**: 代码总量基本不变（可能略增 ~5%），但单文件最大行数从 1583 降至 ~250，可维护性大幅提升。

---

## 七、备注

- 本方案**不影响任何现有功能**，纯内部重构
- 所有 Phase 可独立提交，每个 Phase 完成后都是一个稳定状态
- 建议在实施前创建一个 git branch (`refactor/p3-architecture`)
- Phase 1 是后续所有 Phase 的基础，必须先行
- Phase 2 完成后，后续新增功能可以直接在对应管理器中开发，无需再修改 AppStore
