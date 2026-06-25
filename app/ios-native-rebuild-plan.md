# 自律狗 iOS 原生重建计划

来源：

- [iOS MVP 上架计划](./ios-mvp-launch-plan.md)
- [首页视觉线框](../design/home-scene-wireframe.md)
- [狗狗小世界 MVP 规格](../design/dog-scene-mvp-spec.md)
- [狗狗反馈文案库](../design/dog-feedback-copy.md)
- [Web MVP 原型](./web-mvp/README.md)

## 核心判断

Web MVP 已经完成了创意验证的第一步，但 iOS 上架版不能继续按 Web 结构移植。

iOS 版本要重新按 SwiftUI 原生体验设计和开发：

- 以 iPhone 屏幕适配为第一约束。
- 以 SwiftUI 组件和状态流为基础。
- 以 App Store 可审核为目标。
- Web 原型只作为流程和文案参考，不作为布局来源。

## 保留什么

继续保留并使用：

- 产品定位和 PRD。
- 狗狗小世界概念。
- 狗狗反馈文案库。
- 首发 4 只狗狗设定。
- 目标模板和恢复任务规则。
- 本地数据模型。
- Web MVP 的核心流程验证。

## 重做什么

iOS 原生重做：

- 首页布局。
- 狗狗小世界组件。
- 领养页。
- 目标创建页。
- 打卡反馈页。
- 进度页。
- iPhone 小屏适配。
- SwiftUI 文件结构。
- 上架前调试入口清理。

## 不再照搬 Web 的部分

| Web 原型做法 | iOS 原生做法 |
| --- | --- |
| 用单页状态切换模拟路由 | 用 SwiftUI root state 切换页面 |
| 用 CSS 控制移动端宽度 | 用 SwiftUI 自适应布局和安全区 |
| 用一张场景图撑满上半屏 | 用容器宽度控制、裁切和安全区 |
| 把调试按钮放在首页主区域 | 调试入口隐藏或只在 Debug 显示 |
| 用 Web 卡片布局迁移 | 重新按 iPhone 单手操作设计 |

## iOS 首版信息架构

```text
ZilvgouApp
└── AppRootView
    ├── Onboarding
    │   ├── AdoptDogView
    │   └── CreateGoalView
    ├── Home
    │   ├── HomeView
    │   ├── DogWorldSceneView
    │   ├── TodayGoalCardView
    │   └── WeekRhythmView
    ├── Feedback
    │   └── FeedbackView
    └── Progress
        └── ProgressView
```

## 推荐文件结构

```text
app/ios/Zilvgou/Zilvgou/
  ZilvgouApp.swift
  AppRootView.swift
  AppStore.swift
  Models/
    AppState.swift
    DogProfile.swift
    Goal.swift
    CheckIn.swift
  Data/
    DogCatalog.swift
    GoalTemplates.swift
    FeedbackCopy.swift
  Views/
    AdoptDogView.swift
    CreateGoalView.swift
    HomeView.swift
    FeedbackView.swift
    ProgressView.swift
  Components/
    DogWorldSceneView.swift
    TodayGoalCardView.swift
    WeekRhythmView.swift
    PrimaryButton.swift
    Panel.swift
  Assets.xcassets/
```

## 首页原生布局原则

### 第一屏目标

用户打开 App 后：

1. 第一眼看到狗狗小世界。
2. 第二眼看到今日目标。
3. 拇指自然能点到打卡按钮。

### 布局约束

- 不使用固定大宽度。
- 不让图片按高度反推宽度。
- 狗狗小世界用屏幕宽度决定高度。
- 所有卡片宽度等于可用内容宽度。
- 小屏上按钮和信息换行，不硬塞一行。
- 文案最多 1-2 行，超长时换行。

### 首页比例

| 区域 | 建议 |
| --- | --- |
| 顶部问候 | 轻量，不超过 2 行 |
| 狗狗小世界 | 宽度自适应，高度约为宽度 0.78-0.88 |
| 今日目标区 | 卡片 + 主按钮 + 轻量进度 |
| 调试入口 | Debug-only，不进入上架版本 |

## 第一轮重建任务

### Task 1：拆文件（已完成）

目标：从单一 `ZilvgouApp.swift` 拆成可维护结构。

范围：

- Models
- Data
- Store
- Views
- Components

验收：

- 已编译通过。
- 功能不回退。
- 代码结构清晰。

### Task 2：首页专项适配（进行中）

目标：解决小屏宽度、图片裁切、按钮挤压问题。

范围：

- `HomeView`
- `DogWorldSceneView`
- `TodayGoalCardView`
- `WeekRhythmView`

验收：

- iPhone SE 宽度不横向溢出。
- iPhone 15/16 系列首屏布局自然。
- 狗狗小世界不会撑出屏幕。
- 主按钮首屏可见或接近首屏。

当前进展：

- 已移除首页狗狗小世界对插画背景图的依赖。
- 已实现鸟瞰平面像素小院基座。
- 已实现点击狗狗后在小世界底部展开狗狗状态栏。
- 已接入品种基础上的稳定随机外观数据。
- 已通过 Xcode Debug 编译。

### Task 3：领养和目标创建原生化

目标：让 onboarding 不像 Web 卡片搬运。

范围：

- 领养页单列或自适应网格。
- 目标模板使用原生选择样式。
- 输入区适配键盘。

验收：

- 小屏不挤压。
- 选择状态清晰。
- 创建目标路径顺畅。

### Task 4：反馈和进度页打磨

目标：反馈页更像 iOS App，不像 Web 结算页。

范围：

- 打卡反馈页。
- 状态变化展示。
- 进度页指标。

验收：

- 文案和数据不溢出。
- 反馈有成就感。
- 进度页不复杂。

### Task 5：上架清理

目标：移除审核风险。

范围：

- 隐藏模拟漏一天。
- 隐藏重置体验。
- 补 App Icon。
- 检查文案。
- 准备隐私政策和截图。

验收：

- App 不像开发 Demo。
- 无明显调试入口。
- 可提交 TestFlight。

## 当前立即处理

已经先做了一个临时修复：

- 狗狗小世界图片改为按容器宽度自适应。
- 调试按钮从主横向信息行中移出，减少小屏横向挤压。

但这只是止血，不是最终结构。下一步应该执行 Task 1：拆文件。

## 下一步

开始重构 `app/ios/Zilvgou/Zilvgou/`：

1. 新建 `Models/`、`Data/`、`Views/`、`Components/`。
2. 从 `ZilvgouApp.swift` 拆出模型和视图。
3. 保持编译通过。
4. 再进入首页专项适配。
