import SwiftUI

// MARK: - 互动元素视图

struct InteractiveItemView: View {
    let item: PlacedItem
    let onTap: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }
            onTap()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isAnimating = false
                }
            }
        }) {
            itemIcon
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .rotationEffect(isAnimating ? .degrees(15) : .degrees(0))
        }
    }

    @ViewBuilder
    private var itemIcon: some View {
        switch item.itemType {
        case .ball:
            BallView()
        case .foodBowl:
            FoodBowlView()
        case .toy:
            ToyView()
        case .cushion:
            CushionView()
        case .flower:
            FlowerView()
        }
    }
}

struct BallView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#FF6B6B"))
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            // 高光
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 8, height: 8)
                .offset(x: -6, y: -6)

            // 条纹
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 24, height: 3)
                .rotationEffect(.degrees(45))
        }
    }
}

struct FoodBowlView: View {
    var body: some View {
        ZStack {
            // 碗
            Ellipse()
                .fill(Color(hex: "#FFA500"))
                .frame(width: 30, height: 20)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            // 食物
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 6, height: 6)
                .offset(x: -8, y: -5)
            Circle()
                .fill(Color(hex: "#A0522D"))
                .frame(width: 6, height: 6)
                .offset(x: 0, y: -7)
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 6, height: 6)
                .offset(x: 8, y: -5)
        }
    }
}

struct ToyView: View {
    var body: some View {
        ZStack {
            // 星星
            StarShape()
                .fill(Color(hex: "#FFD700"))
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            // 高光
            StarShape()
                .fill(Color.white.opacity(0.4))
                .frame(width: 14, height: 14)
                .offset(x: -4, y: -4)
        }
    }
}

struct CushionView: View {
    var body: some View {
        ZStack {
            // 垫子
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#9370DB"))
                .frame(width: 32, height: 24)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            // 纹理
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: 28, height: 20)
        }
    }
}

struct FlowerView: View {
    @State private var isSwaying = false

    var body: some View {
        ZStack {
            // 茎
            PixelRect(color: Color(hex: "#228B22"))
                .frame(width: 3, height: 20)
                .offset(y: 10)

            // 花朵
            ZStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color(hex: "#FF69B4"))
                        .frame(width: 10, height: 10)
                        .offset(y: -8)
                        .rotationEffect(.degrees(Double(index) * 72))
                }

                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
            }
            .offset(y: -5)
            .rotationEffect(.degrees(isSwaying ? 5 : -5))
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isSwaying = true
                }
            }
        }
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = rect.width / 2
        let innerRadius = outerRadius / 2.5
        let points = 5

        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle) * radius),
                y: center.y + CGFloat(sin(angle) * radius)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - 场景选择器

struct SceneSelectorView: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            VStack(spacing: 20) {
                // 标题
                Text("选择场景")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                // 场景列表
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(SceneType.allCases, id: \.self) { scene in
                            SceneCardView(
                                scene: scene,
                                isUnlocked: isSceneUnlocked(scene),
                                isSelected: store.state.sceneSettings.currentScene == scene,
                                onSelect: {
                                    if isSceneUnlocked(scene) {
                                        store.setScene(scene)
                                        withAnimation {
                                            isPresented = false
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // 当前环境信息
                EnvironmentInfoView()
                    .padding(.horizontal)

                // 关闭按钮
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("关闭")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.9), .yellow.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    private func isSceneUnlocked(_ scene: SceneType) -> Bool {
        let currentEvolution = store.state.dogEvolution
        return currentEvolution.rawValue >= scene.requiredEvolution.rawValue
    }
}

struct SceneCardView: View {
    let scene: SceneType
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)

                    Image(systemName: scene.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isUnlocked ? .white : .gray)
                }

                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scene.displayName)
                            .font(.headline)
                            .foregroundColor(isUnlocked ? .white : .gray)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    Text(scene.description)
                        .font(.caption)
                        .foregroundColor(isUnlocked ? .white.opacity(0.8) : .gray)

                    if !isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text("需要 \(scene.requiredEvolution.displayName)")
                                .font(.caption2)
                        }
                        .foregroundColor(.yellow)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isUnlocked)
    }
}

struct EnvironmentInfoView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // 时间
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.white)
                    Text(TimeOfDay.current.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                }

                // 天气
                HStack(spacing: 4) {
                    Image(systemName: Weather.current.icon)
                        .foregroundColor(.white)
                    Text(Weather.current.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                }

                // 季节
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.white)
                    Text(Season.current.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
}

// MARK: - 场景切换按钮

struct SceneSwitchButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPresented = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - 每日任务建议系统

/// 任务建议入口按钮
struct TaskSuggestionButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPresented = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Image(systemName: "checklist")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
    }
}

/// 任务建议主视图
struct TaskSuggestionView: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool
    @State private var showCustomTaskSheet = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                // 标题栏
                headerView

                // 今日统计
                todayStatsView

                // 推荐任务列表
                ScrollView {
                    VStack(spacing: 12) {
                        let recommendedTasks = store.recommendTasks(limit: 8)
                        if recommendedTasks.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(recommendedTasks) { task in
                                TaskCardView(
                                    task: task,
                                    onAccept: {
                                        store.acceptTaskSuggestion(task)
                                        withAnimation {
                                            isPresented = false
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // 底部操作栏
                bottomBar
            }
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF2F7EE), Color(hex: 0xFFF7EC)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .sheet(isPresented: $showCustomTaskSheet) {
            CustomTaskSheet(isPresented: $showCustomTaskSheet)
                .environmentObject(store)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: TaskTimeSlot.current.emoji == "🌅" ? "sunrise.fill" :
                                    TaskTimeSlot.current.emoji == "☀️" ? "sun.max.fill" :
                                    TaskTimeSlot.current.emoji == "🌆" ? "sunset.fill" : "moon.fill")
                        .foregroundColor(.orange)
                    Text("\(TaskTimeSlot.current.label)推荐")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Text("根据你的习惯，为你精选的任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 连续打卡天数
            let streak = store.getTaskStreak()
            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak)天")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
        .padding()
    }

    private var todayStatsView: some View {
        let stats = store.getTodayTaskStats()
        return HStack(spacing: 16) {
            StatItem(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                value: "\(stats.completed)",
                label: "已完成"
            )

            Divider()
                .frame(height: 30)

            StatItem(
                icon: "list.bullet",
                iconColor: .blue,
                value: "\(stats.total)",
                label: "今日任务"
            )

            Divider()
                .frame(height: 30)

            StatItem(
                icon: "target",
                iconColor: .purple,
                value: stats.total > 0 ? "\(Int(Double(stats.completed) / Double(stats.total) * 100))%" : "0%",
                label: "完成率"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
        )
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(.green.opacity(0.6))

            Text("今日任务已全部完成！")
                .font(.headline)
                .foregroundColor(.primary)

            Text("太棒了，休息一下吧～")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // 自定义任务按钮
            Button(action: {
                showCustomTaskSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("自定义")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }

            Spacer()

            // 关闭按钮
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("关闭")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

/// 统计项视图
struct StatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 任务卡片视图
struct TaskCardView: View {
    let task: TaskTemplate
    let onAccept: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            onAccept()
        }) {
            HStack(spacing: 12) {
                // 目标类型图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(goalTypeColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: goalTypeIcon)
                        .font(.system(size: 20))
                        .foregroundColor(goalTypeColor)
                }

                // 任务信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // 预估时间
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(task.estimatedMinutes)分钟")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)

                        // 标签
                        if !task.tags.isEmpty {
                            Text(task.tags.first ?? "")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(goalTypeColor.opacity(0.15))
                                )
                                .foregroundColor(goalTypeColor)
                        }
                    }
                }

                Spacer()

                // 接受按钮
                ZStack {
                    Circle()
                        .fill(goalTypeColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var goalTypeColor: Color {
        switch task.goalType {
        case .fitness: return .orange
        case .study: return .blue
        case .work: return .green
        case .sleep: return .purple
        }
    }

    private var goalTypeIcon: String {
        switch task.goalType {
        case .fitness: return "figure.run"
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .sleep: return "moon.fill"
        }
    }
}

/// 自定义任务表单
struct CustomTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var selectedGoalType: GoalType = .fitness
    @State private var estimatedMinutes = 15

    var body: some View {
        NavigationView {
            Form {
                Section("任务信息") {
                    TextField("任务名称", text: $title)

                    Picker("目标类型", selection: $selectedGoalType) {
                        ForEach(GoalType.allCases) { goal in
                            Text(goal.label).tag(goal)
                        }
                    }

                    HStack {
                        Text("预估时间")
                        Spacer()
                        Stepper("\(estimatedMinutes) 分钟", value: $estimatedMinutes, in: 5...120, step: 5)
                    }
                }

                Section {
                    Button(action: {
                        store.addCustomTask(
                            title: title,
                            goalType: selectedGoalType,
                            estimatedMinutes: estimatedMinutes
                        )
                        isPresented = false
                    }) {
                        HStack {
                            Spacer()
                            Text("添加任务")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("自定义任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
