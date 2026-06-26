import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showEvolutionPopup = false
    @State private var previousEvolution: DogEvolution = .puppy

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF2F7EE), Color(hex: 0xFFF7EC), Color(hex: 0xEDF5FB)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if !hasSeenOnboarding {
                // 首次启动：显示引导页
                OnboardingView()
            } else {
                // 已看过引导：正常流程
                mainContent
            }

            // 进化弹窗
            if showEvolutionPopup {
                EvolutionPopupView(
                    oldEvolution: previousEvolution,
                    newEvolution: store.state.dogEvolution,
                    onDismiss: {
                        showEvolutionPopup = false
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onChange(of: store.state.dogEvolution) { _, newEvolution in
            if newEvolution != previousEvolution {
                showEvolutionPopup = true
            }
        }
        .onAppear {
            previousEvolution = store.state.dogEvolution
        }
    }

    private var mainContent: some View {
        Group {
            switch store.state.screen {
            case .adopt:
                AdoptDogView()
            case .adoption:
                AdoptionView()
            case .createGoal:
                CreateGoalView()
            case .home:
                // 如果正在专注模式，显示专注模式视图
                if store.state.isFocusMode && store.state.actionSession.phase == .running {
                    FocusModeView()
                } else {
                    HomeView()
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            AppBottomBar()
                        }
                }
            case .feedback:
                FeedbackView()
            case .progress:
                ProgressScreen()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AppBottomBar()
                    }
            case .dogDog:
                DogDogView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AppBottomBar()
                    }
            case .dogHome:
                DogHomeView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AppBottomBar()
                    }
            case .focusStats:
                FocusStatsView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AppBottomBar()
                    }
            }
        }
    }
}

struct AdoptDogView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                // 顶部标题区（固定）
                VStack(alignment: .leading, spacing: 6) {
                    Text("选一只陪你自律的小狗")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(hex: 0x2C2C2C))
                    Text("先选品种，随机生成外貌。不满意可以换，直到遇到你的那只。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

                // 可滚动内容区
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 品种选择网格
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(DogBreed.allCases) { dog in
                                Button {
                                    store.selectDog(dog)
                                } label: {
                                    DogChoiceCard(dog: dog, isSelected: store.state.selectedDog == dog)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 选中狗狗的预览面板
                        if let appearance = store.state.dogAppearance {
                            Panel {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("你的\(store.state.selectedDog.breedName)")
                                            .eyebrowStyle()
                                        Spacer()
                                        Text(store.state.selectedDog.name)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(Color(hex: 0x356247))
                                    }

                                    PixelDogSprite(breed: store.state.selectedDog, appearance: appearance, size: 100, pose: .idle)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)

                                    Text(store.state.selectedDog.preview)
                                        .font(.subheadline.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(Color(hex: 0x4A4A4A))

                                    Button {
                                        store.randomizeAppearance()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("🎲")
                                            Text("换一个").fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: 0xF2E8D9))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.bottom, 16)
                }

                // 底部按钮（固定）
                PrimaryButton(title: "确认领养") {
                    store.prepareGoalCreation()
                }
                .padding(.top, 8)
            }
            .animation(.easeInOut(duration: 0.2), value: store.state.dogAppearance)
        }
    }
}

struct AdoptionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedBreed: DogBreed?
    @State private var previewAppearance: DogAppearance?

    var uncollectedBreeds: [DogBreed] {
        DogBreed.allCases.filter { !store.state.dogCollection.hasCollected($0) }
    }

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "领养新狗狗", title: "选择一个新的伙伴", subtitle: "完成 10 次计划，获得 1 次领养机会。选择一个还没收集到的品种。")

                if uncollectedBreeds.isEmpty {
                    Panel {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: 0x356247))
                            Text("已收集所有品种！")
                                .font(.headline)
                                .foregroundStyle(Color(hex: 0x356247))
                            Text("你已经收集了所有品种的狗狗")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(uncollectedBreeds) { breed in
                            Button {
                                selectedBreed = breed
                                previewAppearance = DogAppearance.generated(for: breed)
                            } label: {
                                DogChoiceCard(dog: breed, isSelected: selectedBreed == breed)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let breed = selectedBreed, let appearance = previewAppearance {
                        Panel {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("你的\(breed.breedName)")
                                        .eyebrowStyle()
                                    Spacer()
                                    Text(breed.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color(hex: 0x356247))
                                }

                                PixelDogSprite(breed: breed, appearance: appearance, size: 140, pose: .idle)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)

                                Text(breed.preview)
                                    .font(.title3.weight(.bold))
                                    .multilineTextAlignment(.center)

                                Button {
                                    previewAppearance = DogAppearance.generated(for: breed)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("🎲")
                                        Text("换一个")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: 0xF2E8D9))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()

                if !uncollectedBreeds.isEmpty {
                    PrimaryButton(title: "确认领养") {
                        if let breed = selectedBreed, let appearance = previewAppearance {
                            store.collectDog(breed: breed, appearance: appearance)
                            store.go(.dogDog)
                        }
                    }
                    .disabled(selectedBreed == nil)
                    .opacity(selectedBreed == nil ? 0.5 : 1.0)
                } else {
                    PrimaryButton(title: "返回") {
                        store.go(.dogDog)
                    }
                }
            }
        }
    }
}

struct CreateGoalView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                // 顶部：狗狗问候 + 标题
                VStack(spacing: 8) {
                    // 小像素狗
                    if let appearance = store.state.dogAppearance {
                        PixelDogSprite(breed: store.state.selectedDog, appearance: appearance, size: 56, pose: .happy)
                            .padding(.top, 4)
                    }

                    Text("\(store.state.selectedDog.name)说")
                        .font(.caption)
                        .foregroundStyle(Color(hex: 0x8B8B8B))

                    Text(store.state.selectedDog.preview)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: 0x4A4A4A))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

                // 可滚动内容区
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // 场景选择（自定义按钮替代 segmented picker）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今天想做什么？")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(hex: 0x2C2C2C))

                            HStack(spacing: 8) {
                                ForEach(GoalType.allCases) { type in
                                    GoalTypeButton(
                                        type: type,
                                        isSelected: store.goalDraftType == type
                                    ) {
                                        store.selectGoalType(type)
                                    }
                                }
                            }
                        }

                        // 推荐模板
                        VStack(alignment: .leading, spacing: 8) {
                            Text("推荐模板")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(hex: 0x2C2C2C))

                            VStack(spacing: 8) {
                                ForEach(store.goalDraftType.templates) { template in
                                    Button {
                                        store.goalDraftTitle = template.title
                                    } label: {
                                        TemplateCard(template: template, selected: store.goalDraftTitle == template.title)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // 目标名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("目标名称")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(hex: 0x2C2C2C))

                            TextField("给目标起个名字", text: $store.goalDraftTitle)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color(hex: 0xECE0D0), lineWidth: 1)
                                }
                        }
                    }
                    .padding(.bottom, 16)
                }

                // 底部按钮（固定）
                VStack(spacing: 8) {
                    PrimaryButton(title: "开始今天的节奏") {
                        store.createGoal()
                    }

                    Button {
                        store.go(.adopt)
                    } label: {
                        Text("返回选狗")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: 0x8B8B8B))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - 场景类型按钮

struct GoalTypeButton: View {
    let type: GoalType
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch type {
        case .fitness: return ""
        case .study: return ""
        case .work: return ""
        case .sleep: return ""
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.title2)
                Text(type.label)
                    .font(.caption.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: 0x356247) : Color.white.opacity(0.7))
            .foregroundStyle(isSelected ? .white : Color(hex: 0x4A4A4A))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color(hex: 0x356247) : Color(hex: 0xECE0D0), lineWidth: isSelected ? 0 : 1)
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 模板卡片

struct TemplateCard: View {
    let template: GoalTemplate
    let selected: Bool

    private var icon: String {
        if template.title.contains("运动") || template.title.contains("拉伸") || template.title.contains("跑步") {
            return "🏃"
        } else if template.title.contains("阅读") || template.title.contains("学习") || template.title.contains("背单词") {
            return "📖"
        } else if template.title.contains("冥想") || template.title.contains("呼吸") {
            return "🧘"
        } else if template.title.contains("早睡") || template.title.contains("作息") {
            return "🌙"
        } else {
            return "✨"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Text(icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(selected ? Color(hex: 0xE6F0E9) : Color(hex: 0xF8F4EE))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // 文字
            VStack(alignment: .leading, spacing: 3) {
                Text(template.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x2C2C2C))
                Text("恢复：\(template.recoveryTitle)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x8B8B8B))
            }

            Spacer()

            // 选中标记
            if selected {
                Circle()
                    .fill(Color(hex: 0x356247))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .padding(12)
        .background(selected ? Color(hex: 0xE6F0E9).opacity(0.5) : Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? Color(hex: 0x356247) : Color(hex: 0xECE0D0), lineWidth: selected ? 1.5 : 1)
        }
        .animation(.easeInOut(duration: 0.2), value: selected)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore

    private var isDone: Bool { store.hasMainCheckInToday() }
    private var isIdleDone: Bool { isDone && store.state.actionSession.phase == .idle }
    private var isRecovery: Bool { store.state.rhythmState.status == .missed || store.state.rhythmState.status == .longBreak }

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 14) {
                DogWorldScene()
                    .padding(.top, 2)

                TodayActionPanel(
                    eyebrow: isIdleDone ? "Dog Done!" : isRecovery ? "节奏有点乱，没关系" : greeting(),
                    headline: isIdleDone ? (store.state.lastFeedback?.completedPlanTitle ?? "刚刚完成了一次 Dog Go") : isRecovery ? "今天做小一点" : "今天也慢慢来",
                    title: goalTitle,
                    status: statusText,
                    completedPlans: store.todayCompletedPlanTitles(),
                    actionSession: store.state.actionSession,
                    isRecovery: isRecovery,
                    isDone: isDone,
                    isLongBreak: store.state.rhythmState.status == .longBreak,
                    dogLevel: store.state.dogState.level,
                    intimacy: store.state.dogState.intimacy,
                    nextLevelNeed: store.nextLevelNeed(),
                    openDogGoAction: {
                        store.openDogGo()
                    },
                    selectPlanAction: { plan in
                        store.selectActionPlan(plan)
                    },
                    startTimerAction: { minutes in
                        store.startActionTimer(minutes: minutes)
                    },
                    tickTimerAction: {
                        store.tickActionTimer()
                    },
                    cancelSessionAction: {
                        store.cancelActionSession()
                    },
                    completeAction: {
                        if store.state.actionSession.phase == .finished {
                            store.completeActionSession()
                        } else {
                            isRecovery ? store.completeRecoveryGoal() : store.completeMainGoal()
                        }
                    },
                    enterFocusModeAction: {
                        store.enterFocusMode()
                    },
                    smallGoalAction: {
                        store.useSmallGoal()
                    },
                    debugMissAction: {
                        store.simulateMissedDay()
                    },
                    debugResetAction: {
                        store.reset()
                    }
                )
            }
        }
    }

    private var goalTitle: String {
        if isRecovery { return store.recoveryTitle() }
        return store.state.goal?.title ?? "创建一个目标"
    }

    private var statusText: String {
        switch store.state.actionSession.phase {
        case .choosingPlan, .choosingTime: return "选择中"
        case .running: return "进行中"
        case .finished: return "待结算"
        case .idle: break
        }
        if store.state.rhythmState.status == .longBreak { return "建议调小" }
        if isRecovery { return "恢复任务" }
        if isDone { return "可继续" }
        return "今天未完成"
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 { return "早上好" }
        if hour < 18 { return "下午好" }
        return "晚上好"
    }
}

struct FeedbackView: View {
    @EnvironmentObject private var store: AppStore
    @State private var celebrates = false

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 18) {
                PixelCelebrationPanel(
                    breed: store.state.selectedDog,
                    appearance: store.currentDogAppearance(),
                    feedback: store.state.lastFeedback,
                    dogLevel: store.state.dogState.level,
                    intimacy: store.state.dogState.intimacy,
                    moodScore: (store.state.dogState.fullness + store.state.dogState.cleanliness + store.state.dogState.energy) / 30,
                    isAnimating: celebrates
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                        celebrates = true
                    }
                }

                Spacer()

                PixelPrimaryButton(title: "Dog Go!") {
                    store.go(.home)
                }
            }
        }
    }
}

struct ProgressScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var showDiary = false

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "我和\(store.state.selectedDog.breedName)的进度", title: "这段节奏正在累积", subtitle: nil)

                // 进化进度条
                Panel {
                    EvolutionProgressBar(
                        currentEvolution: store.state.dogEvolution,
                        totalCheckIns: store.state.totalMainCheckIns
                    )
                }

                // 心情显示
                Panel {
                    HStack {
                        Text("当前心情")
                            .font(.headline)
                        Spacer()
                        MoodDisplayView(mood: store.state.dogMood)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Lv.\(store.state.dogState.level)")
                                    .font(.title2.weight(.heavy))
                                Spacer()
                                Text("亲密度 \(store.state.dogState.intimacy)/\(store.nextLevelNeed())")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            SwiftUI.ProgressView(value: Double(store.state.dogState.intimacy), total: Double(store.nextLevelNeed()))
                                .tint(Color(hex: 0x5D8B6A))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("近 7 天")
                                .eyebrowStyle()
                            WeekRhythmView()
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricCard(label: "饱腹", value: "\(store.state.dogState.fullness)")
                            MetricCard(label: "清洁", value: "\(store.state.dogState.cleanliness)")
                            MetricCard(label: "精力", value: "\(store.state.dogState.energy)")
                            MetricCard(label: "连续打卡", value: "\(store.state.rhythmState.currentStreak)天")
                        }

                        // Focus stats button
                        Button {
                            store.go(.focusStats)
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                    .font(.caption.weight(.heavy))
                                Text("专注统计")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(Color(hex: 0x356247))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0xE8F0E0))
                            .overlay {
                                Rectangle()
                                    .stroke(Color(hex: 0x9BB985), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        // Diary button
                        Button {
                            showDiary = true
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.caption.weight(.heavy))
                                Text("狗狗日记")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(Color(hex: 0x356247))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0xE8F0E0))
                            .overlay {
                                Rectangle()
                                    .stroke(Color(hex: 0x9BB985), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                PrimaryButton(title: "回首页") {
                    store.go(.home)
                }
            }
            .sheet(isPresented: $showDiary) {
                DiaryViewerView()
                    .environmentObject(store)
            }
        }
    }

}

struct DogDogView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "狗狗收集", title: "我的狗狗们", subtitle: "完成计划，收集不同品种、颜色和装饰的狗狗。")

                // Adoption banner
                if store.state.availableAdoptions > 0 {
                    Panel {
                        HStack(spacing: 12) {
                            Image(systemName: "pawprint.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: 0xC65B44))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("可以领养新狗狗！")
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: 0x356247))
                                Text("完成 10 次计划，获得 1 次领养机会")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                store.goToAdoption()
                            } label: {
                                Text("去领养")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: 0x356247))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Companion selection
                if !store.state.dogCollection.dogs.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("陪伴狗狗")
                                .eyebrowStyle()

                            if let companionId = store.state.activeCompanionId,
                               let companion = store.state.dogCollection.dog(with: companionId) {
                                HStack(spacing: 12) {
                                    PixelDogSprite(breed: companion.breed, appearance: companion.appearance, size: 60, pose: .idle)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(companion.nickname)
                                            .font(.headline)
                                        Text("正在陪伴你")
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: 0x356247))
                                    }

                                    Spacer()

                                    Button {
                                        store.removeCompanion()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(Color(hex: 0x9AA3A0))
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Text("选择一只狗狗陪伴你完成计划")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Collected dogs grid
                if store.state.dogCollection.dogs.isEmpty {
                    Panel {
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: 0x9AA3A0))
                            Text("还没有收集到狗狗")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("完成 10 次计划后可以获得领养机会")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                } else {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("已收集 \(store.state.dogCollection.totalCollected) 只")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(store.state.dogCollection.dogs) { dog in
                                    Button {
                                        store.setCompanion(id: dog.id)
                                    } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                PixelDogSprite(breed: dog.breed, appearance: dog.appearance, size: 60, pose: .idle)

                                                if store.state.activeCompanionId == dog.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                        .background(Color(hex: 0x356247))
                                                        .clipShape(Circle())
                                                        .offset(x: 20, y: -20)
                                                }
                                            }

                                            Text(dog.nickname)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color(hex: 0x356247))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(store.state.activeCompanionId == dog.id ? Color(hex: 0xEAF1DA) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

struct DogHomeView: View {
    @EnvironmentObject private var store: AppStore

    private var currentScene: SceneType {
        store.state.sceneSettings.currentScene
    }

    private var isSceneUnlocked: (SceneType) -> Bool {
        { scene in
            store.state.dogEvolution.rawValue >= scene.requiredEvolution.rawValue
        }
    }

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "道具仓库", title: "狗狗世界", subtitle: "收集道具，布置你的狗狗世界场景。")

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("当前场景")
                            .eyebrowStyle()

                        Text(currentScene.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(hex: 0x356247))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SceneType.allCases, id: \.self) { scene in
                                    SceneThumbnailView(
                                        scene: scene,
                                        isSelected: currentScene == scene,
                                        isLocked: !isSceneUnlocked(scene)
                                    )
                                    .onTapGesture {
                                        if isSceneUnlocked(scene) {
                                            store.setScene(scene)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("道具仓库")
                                .eyebrowStyle()
                            Spacer()
                            Text("\(store.state.dogState.inventory.count) 件")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        if store.state.dogState.inventory.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "gift")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(hex: 0x9AA3A0))
                                Text("还没有道具")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("完成计划可以获得道具奖励")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(store.state.dogState.inventory) { item in
                                    VStack(spacing: 6) {
                                        Image(systemName: item.symbolName)
                                            .font(.title)
                                            .foregroundStyle(Color(hex: item.colorHex))
                                            .frame(width: 44, height: 44)
                                            .background(Color(hex: 0xF5EFE0))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))

                                        Text(item.label)
                                            .font(.caption2.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - 专注模式视图

struct FocusModeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showEncouragement = false
    @State private var encouragementText = ""
    @State private var showRestReminder = false
    @State private var showAbandonConfirm = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF2F7EE), Color(hex: 0xE8F0E0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 顶部标识
                HStack {
                    Image(systemName: "target")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(hex: 0x5D8B6A))
                    Text("专注模式")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color(hex: 0x26382B))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // 狗狗专注姿态
                ZStack {
                    PixelDogSprite(
                        breed: store.state.selectedDog,
                        appearance: store.currentDogAppearance(),
                        size: 180,
                        pose: .focused
                    )

                    // 鼓励气泡
                    if showEncouragement {
                        EncouragementBubble(text: encouragementText)
                            .offset(y: -120)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // 鼓励文字
                Text("你和\(store.state.selectedDog.name)一起专注中...")
                    .font(.headline)
                    .foregroundStyle(Color(hex: 0x356247))

                // 倒计时
                VStack(spacing: 8) {
                    Text(formattedTime(store.state.actionSession.remainingSeconds))
                        .font(.system(size: 56, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x26382B))

                    // 进度条
                    ProgressView(value: Double(store.state.actionSession.durationSeconds - store.state.actionSession.remainingSeconds), total: Double(store.state.actionSession.durationSeconds))
                        .tint(Color(hex: 0x5D8B6A))
                        .frame(width: 200)
                }

                Spacer()

                // 放弃按钮
                Button {
                    showAbandonConfirm = true
                } label: {
                    Text("放弃")
                        .font(.headline)
                        .foregroundStyle(Color(hex: 0x8B6A5D))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0xF5E5E0))
                        .overlay {
                            Rectangle()
                                .stroke(Color(hex: 0x8B6A5D), lineWidth: 2)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.bottom, 30)
            }

            // 休息提醒弹窗
            if showRestReminder {
                RestReminderView(
                    onContinue: {
                        showRestReminder = false
                    },
                    onRest: {
                        showRestReminder = false
                        store.startRest()
                    }
                )
            }

            // 放弃确认弹窗
            if showAbandonConfirm {
                AbandonConfirmView(
                    onConfirm: {
                        store.cancelActionSession()
                    },
                    onCancel: {
                        showAbandonConfirm = false
                    }
                )
            }

            // 休息模式覆盖层
            if store.state.isResting {
                RestModeView(
                    onEndRest: {
                        store.endRest()
                    }
                )
            }
        }
        .onReceive(timer) { _ in
            if store.state.actionSession.phase == .running && !store.state.isResting {
                store.tickActionTimer()
                // 休息提醒（番茄时间：25分钟）
                let elapsed = store.state.actionSession.durationSeconds - store.state.actionSession.remainingSeconds
                if elapsed == 25 * 60 && store.state.actionSession.durationSeconds > 25 * 60 {
                    showRestReminder = true
                }
            }
        }
        .onChange(of: store.state.lastEncouragementProgress) { _, newProgress in
            if newProgress > 0 {
                encouragementText = store.encouragementCopy(progress: newProgress)
                showEncouragementMessage()
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func showEncouragementMessage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showEncouragement = true
        }

        // 3秒后自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showEncouragement = false
            }
        }
    }
}

// MARK: - 鼓励气泡组件

struct EncouragementBubble: View {
    let text: String

    var body: some View {
        VStack {
            Text(text)
                .font(.headline)
                .foregroundStyle(Color(hex: 0x26382B))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay {
                    Rectangle()
                        .stroke(Color(hex: 0x5D8B6A), lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // 气泡尾巴
            BubbleTailShape()
                .fill(Color.white)
                .frame(width: 16, height: 12)
                .overlay {
                    BubbleTailShape()
                        .stroke(Color(hex: 0x5D8B6A), lineWidth: 2)
                        .frame(width: 16, height: 12)
                        .offset(y: 1)
                }
                .offset(y: -6)
        }
    }
}

struct BubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 休息提醒视图

struct RestReminderView: View {
    let onContinue: () -> Void
    let onRest: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: 0x5D8B6A))

                Text("休息一下？")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(hex: 0x26382B))

                Text("你已经专注了 25 分钟，站起来活动活动吧！")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Button {
                        onContinue()
                    } label: {
                        Text("继续专注")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0x5D8B6A))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        onRest()
                    } label: {
                        Text("休息 5 分钟")
                            .font(.headline)
                            .foregroundStyle(Color(hex: 0x5D8B6A))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0xE8F0E0))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - 休息模式视图

struct RestModeView: View {
    let onEndRest: () -> Void
    @EnvironmentObject private var store: AppStore

    private let restDuration = 5 * 60 // 5分钟
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: 0xF2F7EE).ignoresSafeArea()

            VStack(spacing: 24) {
                // 顶部标识
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(hex: 0x5D8B6A))
                    Text("休息时间")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color(hex: 0x26382B))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // 狗狗休息姿态
                PixelDogSprite(
                    breed: store.state.selectedDog,
                    appearance: store.currentDogAppearance(),
                    size: 180,
                    pose: .resting
                )

                // 休息提示
                Text("站起来活动活动，喝口水吧！")
                    .font(.headline)
                    .foregroundStyle(Color(hex: 0x356247))

                // 休息倒计时
                VStack(spacing: 8) {
                    Text(formattedTime(restRemainingTime))
                        .font(.system(size: 56, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x26382B))

                    // 进度条
                    ProgressView(value: Double(restDuration - restRemainingTime), total: Double(restDuration))
                        .tint(Color(hex: 0x5D8B6A))
                        .frame(width: 200)
                }

                Spacer()

                // 结束休息按钮
                Button {
                    onEndRest()
                } label: {
                    Text("结束休息，继续专注")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0x5D8B6A))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.bottom, 30)
            }
        }
        .onReceive(timer) { _ in
            // 检查是否已经休息了5分钟
            if let restStart = store.state.restStartTime {
                let elapsed = Int(Date().timeIntervalSince(restStart))
                if elapsed >= restDuration {
                    onEndRest()
                }
            }
        }
    }

    private var restRemainingTime: Int {
        guard let restStart = store.state.restStartTime else { return restDuration }
        let elapsed = Int(Date().timeIntervalSince(restStart))
        return max(0, restDuration - elapsed)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - 放弃确认视图

struct AbandonConfirmView: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: 0xC69A3E))

                Text("确定要放弃吗？")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(hex: 0x26382B))

                Text("放弃后不会记录这次专注")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button {
                        onConfirm()
                    } label: {
                        Text("确定放弃")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0x8B6A5D))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        onCancel()
                    } label: {
                        Text("继续专注")
                            .font(.headline)
                            .foregroundStyle(Color(hex: 0x5D8B6A))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0xE8F0E0))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Focus Stats View

struct FocusStatsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(
                    eyebrow: "专注统计",
                    title: "你的专注历程",
                    subtitle: "每一次专注都是成长"
                )

                // Summary stats
                Panel {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            FocusStatCard(
                                icon: "clock.fill",
                                value: formatMinutes(store.state.totalFocusMinutes),
                                label: "总专注时长"
                            )

                            FocusStatCard(
                                icon: "timer",
                                value: formatMinutes(store.state.longestFocusSession),
                                label: "最长单次"
                            )
                        }

                        FocusStatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(store.state.focusSessionsCount)",
                            label: "专注次数"
                        )
                    }
                }

                // Recent sessions
                if !store.state.focusSessions.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("最近专注记录")
                                .eyebrowStyle()

                            ForEach(store.state.focusSessions.prefix(5)) { session in
                                FocusSessionRow(session: session)
                            }
                        }
                    }
                } else {
                    Panel {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)

                            Text("还没有专注记录")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("开始你的第一次专注吧！")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }

                Spacer()

                PrimaryButton(title: "返回首页") {
                    store.go(.home)
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(mins)分钟"
            }
        }
    }
}

struct FocusStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: 0x5D8B6A))

            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color(hex: 0x26382B))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: 0xEAF1DA))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FocusSessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(session.completed ? Color(hex: 0x5D8B6A) : Color(hex: 0x8B6A5D))

            VStack(alignment: .leading, spacing: 2) {
                Text(session.plan.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x26382B))

                Text(formatDate(session.startedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatDuration(session.durationSeconds))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: 0x5D8B6A))
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(mins)分钟"
            }
        }
    }
}
