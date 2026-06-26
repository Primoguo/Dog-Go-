# Dog Go 视觉风格优化手册

> 版本：v1.2 | 更新日期：2026-06-26
> 定位：像素风 2.5D 等距宠物养成 × 自律工具

---

## 一、设计原则

1. **像素优先**：所有 UI 组件默认使用直角矩形，不使用圆角（除头像/图标等需要柔和感的元素）
2. **硬边阴影**：用偏移矩形模拟阴影，不使用 `.shadow()` 柔和阴影
3. **暖色田园**：以暖米白为底、森林绿为主、琥珀金为点缀，营造温暖自然的氛围
4. **纹理增质**：关键面板使用 `PixelTinyGrid` 网格纹理，增加像素质感
5. **语义清晰**：颜色按功能分档，同一档颜色只有一种色值，避免混淆

---

## 二、色彩体系

### 2.1 品牌色

| 名称 | 色值 | 用途 | 示例 |
|------|------|------|------|
| 森林绿 `brand` | `#356247` | 主按钮、选中态、底部栏选中、品牌标识 | 主按钮背景、BottomBar 选中 |
| 深绿 `brandDark` | `#1E3D2C` | 品牌色的深色变体，用于边框 | 主按钮边框 |

### 2.2 功能色

| 名称 | 色值 | 用途 |
|------|------|------|
| 成功绿 `success` | `#5D8B6A` | 进度条填充、已完成状态、专注强调 |
| 边框绿 `border` | `#7C9B64` | 面板/场景/进度条的标准边框 |
| 浅绿 `borderLight` | `#9BB985` | 未选中态边框、次要分隔线 |

### 2.3 背景色

| 名称 | 色值 | 用途 |
|------|------|------|
| 暖白 `bgPanel` | `#FFF8E8` | 面板/底部栏/行动面板背景 |
| 米白 `bgPage` | `#F2F7EE` | 页面渐变起点 |
| 奶黄 `bgWarm` | `#FFF7EC` | 页面渐变中点 |
| 淡蓝 `bgCool` | `#EDF5FB` | 页面渐变终点 |
| 场景底 `bgScene` | `#DCEBCB` | Dog World 场景底色 |
| 纹理底 `bgTexture` | `#EAF1DA` | 网格纹理底色、按钮/托盘底色 |
| 卡片底 `bgCard` | `#F6E9C8` | 次要按钮、GainRow 背景 |

### 2.4 文本色

| 名称 | 色值 | 用途 |
|------|------|------|
| 主文本 `textPrimary` | `#26382B` | 标题、重要数值、核心文案 |
| 副文本 `textSecondary` | `#356247` | 副标题、选中项文本（与品牌绿同色） |
| 辅助文本 `textTertiary` | `#6B715F` | 说明文案、禁用态文本、次要信息 |
| 弱文本 `textPlaceholder` | `#8B8B8B` | 占位符、最弱层级文本 |
| 次按钮文本 `secondaryButtonText` | `#3E3323` | 次要按钮（SecondaryButton）专用文本色 |
| 深色底文本 `textOnDark` | `#FFF8E8` | 深色背景（品牌绿/遮罩等）上的浅色文本，与 bgPanel 同色但语义不同 |

### 2.5 点缀色

| 名称 | 色值 | 用途 |
|------|------|------|
| 琥珀金 `accent` | `#C69A3E` | 倒计时边框、等级奖励、状态徽章 |
| 暖金 `accentLight` | `#C7A76D` | 次要按钮边框、GainRow 边框 |
| 金黄 `accentBright` | `#FFF1B8` | 倒计时徽章底色、等级奖励底色 |

### 2.6 状态色

| 状态 | 背景 | 文本 | 边框 |
|------|------|------|------|
| 禁用 | `#D5D8C7` | `#6B715F` | `#A4AA96` |
| 错误/健康 | `#C65B44`（红） | — | — |
| 信息/精力 | `#4C7FA6`（蓝） | — | — |
| 危险/放弃 `danger` | `#F5E5E0` (dangerBg) | `#8B6A5D` (danger) | `#8B6A5D` (danger) |

**危险色用途**：放弃按钮（文本/边框用 `dogDanger`，背景用 `dogDangerBg`）、未完成会话指示器。

### 2.7 像素阴影色

| 名称 | 色值 | 用途 |
|------|------|------|
| 像素阴影 `pixelShadow` | `#3E4F38` | 所有像素组件的偏移硬阴影，alpha 0.16 |

### 2.9 遮罩/覆盖层（Overlay & Scrim）

| 名称 | 色值 | 用途 |
|------|------|------|
| 遮罩色 `scrim` | `#26382B` | 模态弹窗/覆盖层的背景遮罩，与 textPrimary 同色但语义不同 |

**用法**：`Color.dogScrim.opacity(N)`，根据场景选择透明度：

| 场景 | 透明度 | 说明 |
|------|--------|------|
| 轻量弹窗 | 0.4 | 习惯日历、休息提醒等半透背景 |
| 标准弹窗 | 0.45 | 场景锁定遮罩 |
| 强调弹窗 | 0.6 | 进化弹窗、场景选择器、任务建议等深背景 |

```
❌ 禁止使用 Color.black.opacity(N) 作为遮罩
✅ 统一使用 Color.dogScrim.opacity(N)
```

### 2.10 色彩使用规则

```
✅ 正确：
- 主按钮背景 → brand (#356247)
- 进度条填充 → success (#5D8B6A)
- 面板边框 → border (#7C9B64)
- 未选中边框 → borderLight (#9BB985)

❌ 错误：
- 用 #5D8B6A 做按钮背景（那是进度条的颜色）
- 用 #E6F0E9 做标签底色（应合并到 bgTexture #EAF1DA）
- 用 #4A4A4A 做副文本（应使用 textTertiary #6B715F）
- 用 #C69A3E 和 #C7A76D 混用（前者用于点缀，后者用于边框）
```

---

## 三、字体规范

### 3.1 字体家族

| 场景 | 字体 | 说明 |
|------|------|------|
| 数据/计时/日历 | `.monospaced` | 等宽字体，像素风核心 |
| 标题/正文 | 系统默认 (`.rounded` 可选) | 保持 iOS 原生可读性 |
| 特殊标题 | `.system(design: .rounded)` | 仅用于庆祝/弹出面板标题 |

### 3.2 字号层级

| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| Display | 56pt | `.heavy` | 专注计时器 |
| Title 1 | 34pt | `.heavy` (rounded) | 庆祝面板标题 |
| Title 2 | 28-32pt | `.bold` | 页面大标题（引导页/欢迎页） |
| Title 3 | 18-20pt | `.bold` | 区块标题（日历头/面板标题） |
| Headline | `.headline` | — | 卡片标题、进化进度标签 |
| Body | 15-16pt | `.medium` | 正文、引导描述 |
| Caption | 12pt | `.bold` | 小标签、月份显示、关闭按钮 |
| Small | 9-10pt | `.medium` | 成就徽章、倒计时小字 |

### 3.3 语义化样式

```swift
//  eyebrow 小标签（已实现）
Text("今日目标").eyebrowStyle()
// → .font(.caption.weight(.bold)).foregroundStyle(Color.dogTextTertiary).textCase(.none)

// 数据展示（推荐用法）
Text("25:00")
    .font(.system(size: 56, weight: .heavy, design: .monospaced))

// 面板标题
Text("习惯日历")
    .font(.system(size: 18, weight: .bold, design: .monospaced))
```

---

## 四、间距系统

### 4.1 基础间距

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4pt | 图标与文字间距、紧凑元素内间距 |
| `sm` | 8pt | 相关元素间距、按钮内间距 |
| `md` | 12pt | 卡片内间距、列表项间距 |
| `lg` | 16pt | 区块内间距、面板内间距 |
| `xl` | 18pt | 页面水平内边距（ScreenScaffold） |
| `2xl` | 20pt | 区块间间距 |

### 4.2 固定尺寸

| 组件 | 尺寸 | 说明 |
|------|------|------|
| 页面最大宽度 | 430pt | ScreenScaffold maxWidth |
| 底部栏按钮 | 44×44pt | 可点击区域最小尺寸 |
| 场景缩略图 | 80×56pt | DogHomeView 场景选择 |
| 场景宽高比 | 0.83 | DogWorldScene |
| 日历面板 | 340×580pt | HabitCalendarView |
| 月报面板 | 320×480pt | MonthlyReportView |

---

## 五、组件规范

### 5.1 像素风卡片（PixelCard）

所有面板/卡片/容器统一使用此规范：

```
┌──────────────────────────┐ ← 2-3px 边框 (border #7C9B64)
│ ▓▓▓▓▓▓ 内容 ▓▓▓▓▓▓▓▓▓│ ← 网格纹理底 (PixelTinyGrid, alpha 0.34)
│                          │
│     实际内容区域           │ ← 内边距 12-18pt
│                          │
└──────────────────────────┘
    ░░░░ 偏移硬阴影 ░░░░░░  ← 阴影色 #3E4F38, alpha 0.16, offset (4, 4)
```

**参数**：
- 圆角：`0`（直角）
- 边框：`#7C9B64`，线宽 2-3px
- 背景：`#FFF8E8`（面板）或 `#EAF1DA`（托盘）
- 纹理：`PixelTinyGrid(colorA: #F4E6C6 opacity 0.34, colorB: clear, tile: 14)`
- 阴影：偏移矩形 `#3E4F38` alpha 0.16，offset (4, 4)

### 5.2 主按钮（PixelPrimaryButton）

```
┌────────────────────┐
│   ▓▓ 按钮文本 ▓▓   │ ← 白色文本, .headline.weight(.heavy)
└────────────────────┘
    ░░░░ 像素阴影 ░░░░
```

| 属性 | 值 |
|------|-----|
| 背景 | `#356247` (brand) |
| 文本 | `#FFF8E8` (textOnDark) |
| 边框 | `#1E3D2C` (brandDark), 3px |
| 圆角 | 8pt |
| 最小高度 | 50pt |
| 阴影 | 偏移矩形, `#3E4F38`, offset (0, 4) |
| 禁用态 | bg `#D5D8C7`, text `#6B715F`, border `#A4AA96` |

### 5.3 次要按钮（PixelSecondaryButton）

| 属性 | 值 |
|------|-----|
| 背景 | `#F6E9C8` (bgCard) |
| 文本 | `#3E3323` |
| 边框 | `#C7A76D` (accentLight), 2px |
| 圆角 | 8pt |
| 最小高度 | 50pt |

### 5.4 进度条（PixelProgressBar）

```
┌──────────────────────────────┐ ← 1px 边框 #7C9B64
│ ████████████░░░░░░░░░░░░░░░░ │ ← 填充 #5D8B6A, 轨道 #E8E0D0
└──────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 轨道 | `#E8E0D0` |
| 填充 | `#5D8B6A` (success) |
| 边框 | `#7C9B64`, 1px |
| 高度 | 12-14pt |

### 5.5 分段计量条（PixelMeter）

```
┌──────────────────────────────┐ ← 外边框 #9BB985, 底 #EAF1DA
│ ████ │ ████ │ ████ │ ░░░░ │ ← 填充 #5D8B6A / 空 #D9CFB9
└──────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 填充块 | `#5D8B6A`, 边框 `#356247` |
| 空白块 | `#D9CFB9`, 边框 `#BCA98B` |
| 容器 | bg `#EAF1DA`, 外边框 `#9BB985` |

### 5.6 底部导航栏（AppBottomBar）

```
╔══════════════════════════════╗ ← 顶边框 #7C9B64, 2px
║ ▓▓ [选中] ▓▓ ▓▓ ▓▓ ▓▓ ▓▓ ║ ← 底纹 PixelTinyGrid
╚══════════════════════════════╝
```

| 属性 | 值 |
|------|-----|
| 背景 | `#FFF8E8` (bgPanel) 纯色 + `#EAF1DA` 网格纹理（无 opacity） |
| 顶边框 | `#7C9B64`, 2px |
| 选中项 | fg `#FFF8E8` (textOnDark), bg `#356247`, border `#1E3D2C` |
| 未选中项 | fg `#41573E`, bg `#EAF1DA`, border `#9BB985` |

### 5.7 状态徽章（PixelStatusBadge）

| 状态 | 背景 | 文本 | 边框 |
|------|------|------|------|
| 待处理 pending | `#FFF1B8` | `#6E4F15` | `#C69A3E` |
| 恢复中 recovery | `#E8D9BC` | `#6D6557` | `#B8A98F` |
| 已完成 done | `#EAF1DA` | `#356247` | `#7C9B64` |

### 5.8 节奏单元格（PixelRhythmCell）

| 状态 | 填充 | 边框 |
|------|------|------|
| 已完成 | `#5D8B6A` | `#356247` |
| 未完成 | `#D9CFB9` | `#BCA98B` |

### 5.9 形状使用规则

**直角矩形（Rectangle / RoundedRectangle(cornerRadius: 0)）**：所有面板、卡片、按钮、容器的默认形状。

**圆角 8pt（RoundedRectangle(cornerRadius: 8)）**：仅用于按钮（PixelPrimaryButton / PixelSecondaryButton）。

**胶囊形（Capsule）**：仅用于以下场景，不得用于面板或卡片：
- 控件轨道：Toggle 开关、Slider 滑轨、ProgressView 进度条轨道
- 心情徽章：MoodDisplayView 的心情胶囊
- 小型状态指示器：如在线状态点、小标签

```
✅ 正确：
- 面板/卡片 → Rectangle (cornerRadius: 0)
- 按钮 → RoundedRectangle(cornerRadius: 8)
- Toggle 轨道 → Capsule()
- 心情徽章 → Capsule()

❌ 错误：
- 面板用 Capsule()（面板必须直角）
- 卡片用 RoundedRectangle(12)（卡片必须直角）
- 按钮用 RoundedRectangle(16)（按钮统一 8pt）
```

---

## 六、场景系统规范

### 6.1 等距盒体（IsometricBox）

三面等距盒体是场景的核心构建单元：

| 面 | 亮度 | 说明 |
|----|------|------|
| 顶面 | +15% | 最亮，模拟顶部光照 |
| 正面 | 基准色 | 主视角面 |
| 侧面 | -25% | 最暗，模拟侧面阴影 |

### 6.2 场景配色

| 场景 | 地面色 | 解锁条件 | 道具 |
|------|--------|----------|------|
| 温馨小院 | `#7CCD7C` | puppy (默认) | 狗窝、沙发 |
| 阳光公园 | `#6BBF6B` | adult (10次) | 跑步机 |
| 海边沙滩 | `#F4D03F` | complete (50次) | 工作台 |
| 神秘森林 | `#3D6B3D` | legendary (100次) | 学习桌 |

### 6.3 天空渐变（按时段）

| 时段 | 起始色 | 终止色 |
|------|--------|--------|
| 早晨 | `#FFB347` | `#87CEEB` |
| 下午 | `#87CEEB` | `#B0E0E6` |
| 傍晚 | `#FF6B6B` → `#FFB347` | `#87CEEB` |
| 夜晚 | `#1A1A2E` | `#16213E` |

### 6.4 场景道具互动效果

| 道具 | 场景 | 效果 | 反馈 |
|------|------|------|------|
| 狗窝 | 小院 | 精力 +15, 亲密度 +3 | 狗狗休息 |
| 沙发 | 小院 | 心情 +3, 精力 +8 | 放松 |
| 跑步机 | 公园 | 心情 +4, 饱腹 -5 | 锻炼 |
| 工作台 | 沙滩 | 心情 +3, 亲密度 +2 | 劳动 |
| 学习桌 | 森林 | 精力 +10, 心情 +2 | 学习 |

---

## 七、动画规范

### 7.1 交互反馈

| 场景 | 参数 | 说明 |
|------|------|------|
| 点击弹跳 | `spring(response: 0.3, damping: 0.5)` | 道具/按钮点击 |
| 按下回弹 | `spring(response: 0.3, damping: 0.7)` | 卡片按压 |
| 拖拽跟随 | `interactiveSpring(response: 0.3, damping: 0.7)` | 狗狗拖拽 |
| 释放回位 | `spring(response: 0.6, damping: 0.5)` | 拖拽释放 |

### 7.2 环境循环

| 场景 | 参数 | 说明 |
|------|------|------|
| 尾巴摇摆 | `easeInOut(0.4-0.8s).repeatForever` | 根据心情调整速度 |
| 海浪起伏 | `easeInOut(3s).repeatForever` | 沙滩场景 |
| 花朵摇曳 | `easeInOut(2s).repeatForever` | 场景装饰 |
| 同伴游荡 | `easeInOut(3s).repeatForever` | 同伴狗狗 |

### 7.3 持续运动

| 场景 | 参数 | 说明 |
|------|------|------|
| 光晕旋转 | `linear(8s).repeatForever` | 进化特效 |
| 云朵漂移 | `linear(30s).repeatForever` | 天空装饰 |
| 雨滴下落 | `linear(1.5s).repeatForever` | 雨天效果 |

### 7.4 过渡动画

| 场景 | 效果 | 说明 |
|------|------|------|
| 面板弹出 | `.move(edge: .bottom) + .opacity` | 状态托盘、日历 |
| 弹窗出现 | `.scale + .opacity` | 鼓励气泡、进化弹窗 |
| Toast 提示 | `.move(edge: .top) + .opacity` | 道具使用反馈 |

---

## 八、改造记录

### ✅ 已完成（v1.0 → v1.1）

以下组件已全部改造完成并提交（commit 52e0905 + aef27b3）：

| 组件 | 原问题 | 改造结果 |
|------|--------|----------|
| `Panel` | 圆角 8 + 柔阴影 radius 22 | ✅ 直角 + 像素硬阴影 + 网格纹理 |
| `HabitCalendarView` | 独立配色 + 圆角 16 | ✅ 统一像素风面板 |
| `MonthlyReportView` | 独立配色 + 圆角 | ✅ 统一像素风面板 |
| `DiaryEntryCard` | 圆角 12 + 柔阴影 | ✅ 直角 + 像素硬阴影 |
| `EvolutionProgressBar` | systemBackground + 柔阴影 | ✅ 像素进度条风格 |
| `PrimaryButton` / `SecondaryButton` | 无像素纹理 | ✅ 像素硬阴影 + 圆角 8pt |
| `FocusModeView` 面板 | 圆角 16 + 柔阴影 | ✅ 直角 + 像素硬阴影 |
| `OnboardingView` | 橙色主色 | ✅ 品牌绿 + 语义色 |
| `DogChoiceCard` | 圆角 12 | ✅ 直角 + 像素边框 |
| `Color(hex: String)` | 与 UInt 版本并存 | ✅ 全部统一为 UInt 版本，String 版已删除 |
| 全局 `.secondary` | 38 处系统色 | ✅ 全部替换为语义色 |
| 全局系统色 | systemBackground/systemGray 等 | ✅ 全部替换为语义色 |

### 📋 待办

| 项目 | 说明 | 优先级 |
|------|------|--------|
| 暗色模式 | 全部硬编码色值，需定义 light/dark 语义色 | 低 |

---

## 九、代码模板

### 9.1 标准像素卡片

```swift
VStack(alignment: .leading, spacing: 12) {
    // 内容
}
.padding(12)
.background {
    ZStack {
        Color(hex: 0xFFF8E8)
        PixelTinyGrid(
            colorA: Color(hex: 0xF4E6C6, alpha: 0.34),
            colorB: .clear,
            tile: 14
        )
    }
}
.overlay {
    Rectangle().stroke(Color(hex: 0x7C9B64), lineWidth: 2)
}
.shadow(
    color: Color(hex: 0x3E4F38, alpha: 0.16),
    radius: 0, x: 4, y: 4
)
```

### 9.2 标准像素按钮

```swift
Button(action: action) {
    Text(title)
        .font(.headline.weight(.heavy))
        .foregroundColor(Color.dogTextOnDark)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 50)
        .background(Color(hex: 0x356247))
        .overlay {
            Rectangle().stroke(Color(hex: 0x1E3D2C), lineWidth: 3)
        }
}
.background {
    // 像素阴影
    Rectangle()
        .fill(Color(hex: 0x3E4F38).opacity(0.16))
        .offset(y: 4)
}
```

### 9.3 语义色常量（已实现于 Style.swift）

```swift
extension Color {
    // 品牌
    static let dogBrand = Color(hex: 0x356247)
    static let dogBrandDark = Color(hex: 0x1E3D2C)

    // 功能
    static let dogSuccess = Color(hex: 0x5D8B6A)
    static let dogBorder = Color(hex: 0x7C9B64)
    static let dogBorderLight = Color(hex: 0x9BB985)

    // 背景
    static let dogBgPanel = Color(hex: 0xFFF8E8)
    static let dogBgTexture = Color(hex: 0xEAF1DA)
    static let dogBgCard = Color(hex: 0xF6E9C8)
    static let dogBgScene = Color(hex: 0xDCEBCB)

    // 文本
    static let dogTextPrimary = Color(hex: 0x26382B)
    static let dogTextSecondary = Color(hex: 0x356247)
    static let dogTextTertiary = Color(hex: 0x6B715F)
    static let dogTextPlaceholder = Color(hex: 0x8B8B8B)
    static let dogSecondaryButtonText = Color(hex: 0x3E3323)
    static let dogTextOnDark = Color(hex: 0xFFF8E8)

    // 危险
    static let dogDanger = Color(hex: 0x8B6A5D)
    static let dogDangerBg = Color(hex: 0xF5E5E0)

    // 遮罩
    static let dogScrim = Color(hex: 0x26382B)

    // 点缀
    static let dogAccent = Color(hex: 0xC69A3E)
    static let dogAccentLight = Color(hex: 0xC7A76D)
    static let dogAccentBright = Color(hex: 0xFFF1B8)

    // 阴影
    static let dogPixelShadow = Color(hex: 0x3E4F38)
}
```

---

## 十、像素画调色板附录

场景、道具、狗狗渲染使用的颜色，供绘制像素精灵时参考。

### 10.1 场景地面色

| 场景 | 色值 | 说明 |
|------|------|------|
| 温馨小院 | `#7CCD7C` | 草地绿 |
| 阳光公园 | `#6BBF6B` | 深草绿 |
| 海边沙滩 | `#F4D03F` | 沙黄 |
| 神秘森林 | `#3D6B3D` | 暗林绿 |

### 10.2 自然元素

| 元素 | 色值 | 说明 |
|------|------|------|
| 树干 | `#8B6A5D` | 棕色 |
| 树冠（浅） | `#4CAF50` | 受光面 |
| 树冠（深） | `#2E7D32` | 背光面 |
| 海水 | `#4C9BEA` | 蓝色 |
| 海浪泡沫 | `#FFFFFF` | 白色 |
| 花朵（红） | `#E85D75` | 红色花瓣 |
| 花朵（黄） | `#F4D03F` | 黄色花瓣 |
| 蘑菇帽 | `#C65B44` | 红色 |
| 蘑菇杆 | `#F5E5E0` | 米白 |
| 石头 | `#8B8B7A` | 灰绿 |

### 10.3 建筑/道具

| 元素 | 色值 | 说明 |
|------|------|------|
| 屋顶 | `#A0522D` | 赭石 |
| 墙壁 | `#D2B48C` | 浅棕 |
| 窗户 | `#87CEEB` | 天蓝 |
| 门 | `#6B4226` | 深棕 |
| 长椅 | `#8B6A5D` | 棕色 |

### 10.4 狗狗基础色（随机系统）

| 部位 | 可选色值 | 说明 |
|------|----------|------|
| 身体 | `#F5DEB3`, `#D2B48C`, `#8B6914`, `#4A4A4A`, `#F5F5DC`, `#C4A882`, `#E8D5B7` | 7 色 |
| 耳朵 | 同身体色 | 与身体同色系 |
| 眼睛 | `#2C1810`, `#4A3728`, `#1A1A1A` | 深色系 |
| 鼻子 | `#1A1A1A`, `#2C1810` | 黑色/深棕 |
| 舌头 | `#E85D75` | 粉红 |

### 10.5 特效色

| 特效 | 色值 | 说明 |
|------|------|------|
| 进化发光 | `#FFF1B8` (accentBright) | 金色光晕 |
| 传奇皇冠 | `#C69A3E` (accent) | 琥珀金 |
| 魔法粒子 | `#B39DDB` | 紫色 |
| 像素硬阴影 | `#3E4F38` (pixelShadow) | alpha 0.16 |

---

## 十一、检查清单

新页面/组件开发时，逐项检查：

- [ ] 是否使用直角矩形（圆角仅用于头像/图标）？
- [ ] 阴影是否使用偏移矩形（而非 `.shadow(radius:)`）？
- [ ] 颜色是否来自本手册定义的色值（而非随意 hex）？
- [ ] 边框是否使用 `Rectangle().stroke()` 而非 `.border()`？
- [ ] 面板是否添加了 `PixelTinyGrid` 网格纹理？
- [ ] 文本颜色是否使用语义色（textPrimary/Secondary/Tertiary）？
- [ ] 间距是否遵循 4/8/12/16/18 的间距系统？
- [ ] 按钮是否使用 PixelPrimaryButton / PixelSecondaryButton？
- [ ] 动画是否使用 spring（交互）或 easeInOut（环境）？
- [ ] 场景道具是否有实际互动效果（不只是装饰）？
