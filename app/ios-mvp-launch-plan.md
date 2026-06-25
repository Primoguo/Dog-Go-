# 自律狗 iOS MVP 上架计划

来源：

- [Web MVP 原型准备](./web-mvp-prototype-plan.md)
- [数据模型 v1](./data-model-v1.md)
- [狗狗小世界 MVP 规格](../design/dog-scene-mvp-spec.md)
- [狗狗反馈文案库](../design/dog-feedback-copy.md)
- [首页视觉线框](../design/home-scene-wireframe.md)

## 目标

先做一个可以提交 TestFlight 和 App Store Review 的 iOS 最小版本。

首版不追求完整习惯管理平台，只验证：

- 用户能领养一只自律狗。
- 用户能创建一个自律目标。
- 用户每天打开能看到狗狗小世界。
- 用户完成打卡后能收到狗狗反馈。
- 用户中断后能看到温和恢复任务。

## 上架策略

推荐路径：

1. SwiftUI 本地 MVP。
2. 真机测试。
3. TestFlight 内测。
4. 修复崩溃和审核风险。
5. App Store 首次提交。

首版不做：

- 登录注册。
- 后端同步。
- 推送提醒。
- 内购订阅。
- 社交小队。
- AI 长对话。
- 复杂装扮商城。
- 第三方健康数据接入。

原因：

- 上架第一版越小，审核和调试越稳。
- 自律狗当前最需要验证的是“狗狗陪伴 + 打卡闭环”。
- 登录、推送、内购都会显著增加审核和实现复杂度。

## iOS 首版范围

P0 必须做：

| 功能 | 说明 |
| --- | --- |
| 首次领养 | 选择柴犬、金毛、边牧、中华田园犬 |
| 创建目标 | 健身、学习、作息模板，默认健身 |
| 首页 | 狗狗小世界 + 今日目标 + 打卡按钮 |
| 完成打卡 | 更新亲密度和状态 |
| 狗狗反馈 | 根据品种语气展示反馈 |
| 进度页 | 亲密度、等级、近 7 天、本周节奏 |
| 节奏恢复 | 漏 1 天后展示小恢复任务 |
| 本地保存 | 使用本地存储保存狗狗、目标、状态、打卡 |

P1 可以延后：

| 功能 | 说明 |
| --- | --- |
| 目标编辑 | 修改目标名称、频率、提醒 |
| 暂停目标 | 暂停期间不计断签 |
| 打卡备注 | 心情和备注 |
| 通知提醒 | 本地通知 |
| 多目标 | MVP 后再考虑 |

## 技术方案

建议技术栈：

- SwiftUI。
- Swift。
- 本地存储：`UserDefaults` 或轻量 JSON 文件。
- 图片资源放在 Asset Catalog。
- 不接网络。
- 不请求敏感权限。

推荐最低版本：

- iOS 17 或 iOS 18，视本机 Xcode 支持确定。

如果希望覆盖更多设备：

- 可考虑 iOS 16+。

## SwiftUI 页面结构

```text
ZilvgouApp
└── AppRootView
    ├── AdoptDogView
    ├── CreateGoalView
    ├── HomeView
    │   ├── DogWorldSceneView
    │   ├── TodayGoalCardView
    │   └── WeekRhythmView
    ├── FeedbackView
    └── ProgressView
```

页面说明：

| View | 目的 |
| --- | --- |
| `AdoptDogView` | 领养狗狗 |
| `CreateGoalView` | 创建第一个目标 |
| `HomeView` | 核心首页 |
| `DogWorldSceneView` | 狗狗小世界 |
| `FeedbackView` | 打卡反馈 |
| `ProgressView` | 进度 |

## 数据模型

Swift 模型对应 [data-model-v1.md](./data-model-v1.md)。

建议类型：

```swift
enum DogBreed: String, Codable {
    case shiba
    case golden
    case borderCollie
    case native
}

enum GoalType: String, Codable {
    case fitness
    case study
    case sleep
}

enum RhythmStatus: String, Codable {
    case stable
    case missed
    case recovering
    case longBreak
    case paused
}
```

核心对象：

- `DogProfile`
- `Goal`
- `CheckIn`
- `DogState`
- `RhythmState`
- `AppState`

状态管理：

- `AppStore: ObservableObject`
- `@Published var state: AppState`
- 每次状态变化后保存到本地。

## 本地存储

首版建议：

- 使用 `UserDefaults` 存储编码后的 `AppState` JSON。

Key：

```text
zilvgou.appState.v1
```

要求：

- 首次启动进入领养页。
- 已领养但无目标，进入目标创建页。
- 已领养且有目标，进入首页。
- App 重启后状态保留。
- 数据解析失败时重置为初始状态。

## 狗狗小世界资产

首版最小资产：

| 资产 | 数量 | 说明 |
| --- | --- | --- |
| 小院子背景 | 1 | 首页上半屏 |
| 狗狗品种图 | 4 | 柴犬、金毛、边牧、中华田园犬 |
| 狗狗姿态 | 3/只 | idle、happy、waiting |
| 任务道具 | 3 组 | 健身、学习、作息 |
| 恢复道具 | 1 组 | 小门、脚印、小垫子 |
| App Icon | 1 套 | App Store 必需 |

如果资产来不及：

- 首版可以用同一张小院子插画 + 品种卡片 + 文案先跑通。
- 但 App Store 截图必须看起来像完成品，不能像开发占位。

## App Store 物料清单

必须准备：

| 物料 | 状态 |
| --- | --- |
| App 名称 | 自律狗 |
| Subtitle | 待定 |
| App 描述 | 待写 |
| 关键词 | 待写 |
| App 图标 | 待设计 |
| iPhone 截图 | 待制作 |
| 隐私政策 URL | 待创建 |
| App 隐私标签 | 待填写 |
| 年龄分级 | 待填写 |
| 支持 URL | 可先用简单说明页 |
| Bundle ID | 待定 |
| SKU | 待定 |

建议首版分类：

- Health & Fitness 或 Productivity，二选一。

建议优先考虑：

- Productivity：强调自律陪伴、习惯养成。
- Health & Fitness：如果首发主要展示健身模板。

## 隐私策略

首版不接后端、不登录、不上传数据。

隐私声明可以非常简洁：

- 打卡数据仅保存在用户设备本地。
- 不收集账号信息。
- 不上传个人数据。
- 不接第三方分析 SDK。
- 不接广告 SDK。

注意：

- 如果后续加入埋点、登录、推送、AI、云同步，需要重新更新隐私政策和 App Privacy。

## TestFlight 计划

第一轮 TestFlight 测试：

- 5-10 名熟人测试。
- 测试周期：3-7 天。
- 目标：验证核心闭环和崩溃风险。

测试任务：

1. 第一天完成领养、目标创建、首次打卡。
2. 第二天打开 App，看首页状态是否保留。
3. 第三天故意不打卡或通过测试入口模拟漏一天。
4. 第四天完成恢复任务。
5. 测试结束后反馈：狗狗是否有陪伴感？

需要记录：

- 是否出现崩溃。
- 本地数据是否丢失。
- 首页是否有狗狗陪伴感。
- 打卡反馈是否有成就感。
- 恢复任务是否温和。

## App Review 风险点

需要避免：

- App 像未完成 Demo。
- 使用明显占位图、开发按钮、调试入口。
- 截图与实际 App 不一致。
- 隐私政策缺失。
- App 功能太少，像网页壳或空壳。
- 文案暗示医疗、心理治疗或健康疗效。
- 使用惩罚性、羞辱性文案。

首版处理：

- 移除“模拟漏一天”和“重置体验”等开发按钮，或放入隐藏调试模式，不提交审核。
- 保证无网络权限也可完整使用。
- App Store 描述中定位为“自律陪伴和习惯打卡”，不宣称治疗焦虑、改善疾病等。

## 第一周开发任务

### Day 1：工程和基础架构

- 创建 SwiftUI 工程。
- 建立数据模型。
- 建立 `AppStore`。
- 实现本地保存和读取。

完成标准：

- App 可运行。
- 首次进入领养页。
- 重启后状态保留。

### Day 2：领养和目标创建

- `AdoptDogView`。
- `CreateGoalView`。
- 狗狗数据和目标模板。

完成标准：

- 能选择 4 只狗。
- 能创建目标。
- 进入首页。

### Day 3：首页

- `HomeView`。
- `DogWorldSceneView`。
- 今日目标卡片。
- 本周节奏摘要。

完成标准：

- 首页第一眼是狗狗小世界。
- 打卡按钮可见。

### Day 4：打卡和反馈

- 完成主目标。
- 更新状态。
- `FeedbackView`。
- 反馈文案选择。

完成标准：

- 同一天不重复奖励。
- 完成后亲密度和状态更新。

### Day 5：进度和恢复

- `ProgressView`。
- 近 7 天节奏。
- 漏 1 天恢复任务。

完成标准：

- 进度页数据准确。
- 恢复状态不惩罚用户。

### Day 6：打磨和真机测试

- 适配不同 iPhone 尺寸。
- 修复布局问题。
- 移除开发入口。
- 检查文案。

完成标准：

- 真机跑通完整闭环。
- 无明显 UI 溢出。

### Day 7：TestFlight 准备

- 配置 Bundle ID。
- 配置签名。
- Archive。
- 上传 TestFlight。
- 准备测试说明。

完成标准：

- TestFlight 可安装。
- 至少 1 台真机完整跑通。

## 下一步

下一步需要做两件事：

1. 确认本机 Xcode 和 Apple Developer 账号状态。
2. 创建 SwiftUI 工程目录：

```text
app/ios/Zilvgou/
```

如果暂时没有 Apple Developer 账号，也可以先创建本地 SwiftUI 工程并真机或模拟器测试，等账号准备好后再上传 TestFlight。
