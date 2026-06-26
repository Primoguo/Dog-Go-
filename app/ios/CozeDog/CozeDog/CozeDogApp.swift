import SwiftUI

@main
struct CozeDogApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // 进入后台时保存状态
                store.saveState()
            case .active:
                // 回到前台时重新检测断签
                store.checkStreakOnLaunch()
            default:
                break
            }
        }
    }
}
