# 自律狗 iOS MVP

SwiftUI 本地 MVP，用于把 Web 原型迁移到可上 TestFlight 的 iOS App。

## 打开方式

用 Xcode 打开：

```text
app/ios/Zilvgou/Zilvgou.xcodeproj
```

## 当前已实现

- 领养狗狗。
- 创建目标。
- 首页狗狗小世界。
- 完成今日打卡。
- 狗狗反馈页。
- 进度页。
- 本地 `UserDefaults` 保存状态。
- 模拟漏一天和重置体验，供开发验证。

## 上架前必须处理

- 替换或完善 App Icon。
- 移除或隐藏开发验证入口：模拟漏一天、重置体验。
- 设置真实 Bundle ID 和 Team。
- 准备隐私政策 URL。
- 准备 App Store 截图和描述。
