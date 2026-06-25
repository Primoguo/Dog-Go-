import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF2F7EE), Color(hex: 0xFFF7EC), Color(hex: 0xEDF5FB)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            switch store.state.screen {
            case .adopt:
                AdoptDogView()
            case .adoption:
                AdoptionView()
            case .createGoal:
                CreateGoalView()
            case .home:
                HomeView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        AppBottomBar()
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
            }
        }
    }
}

struct AdoptDogView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "自律狗 iOS MVP", title: "选一只陪你自律的小狗", subtitle: "先选喜欢的品种，随机生成它的外貌。不满意可以换一个，直到遇到你的那只。")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DogBreed.allCases) { dog in
                        Button {
                            store.selectDog(dog)
                        } label: {
                            DogChoiceCard(dog: dog, isSelected: store.state.selectedDog == dog)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let appearance = store.state.dogAppearance {
                    Panel {
                        VStack(spacing: 12) {
                            HStack {
                                Text("你的\(store.state.selectedDog.breedName)")
                                    .eyebrowStyle()
                                Spacer()
                                Text(store.state.selectedDog.name)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color(hex: 0x356247))
                            }

                            PixelDogSprite(breed: store.state.selectedDog, appearance: appearance, size: 140, pose: "idle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)

                            Text(store.state.selectedDog.preview)
                                .font(.title3.weight(.bold))
                                .multilineTextAlignment(.center)

                            Text("\(store.state.selectedDog.breedName)只影响语气和形象，所有目标都能陪你完成。")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)

                            Button {
                                store.randomizeAppearance()
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

                Spacer()

                PrimaryButton(title: "确认领养") {
                    store.prepareGoalCreation()
                }
            }
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

                                PixelDogSprite(breed: breed, appearance: appearance, size: 140, pose: "idle")
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
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "\(store.state.selectedDog.breedName)已经住进小院子", title: "先定一个今天能开始的目标", subtitle: "首版默认推荐健身，也可以切到学习或作息。")

                Panel {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("场景")
                                .eyebrowStyle()
                            Picker("场景", selection: $store.goalDraftType) {
                                ForEach(GoalType.allCases) { type in
                                    Text(type.label).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: store.goalDraftType) { _, newValue in
                                store.selectGoalType(newValue)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("推荐模板")
                                .eyebrowStyle()
                            ForEach(store.goalDraftType.templates) { template in
                                Button {
                                    store.goalDraftTitle = template.title
                                } label: {
                                    TemplateRow(template: template, selected: store.goalDraftTitle == template.title)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("目标名称")
                                .eyebrowStyle()
                            TextField("目标名称", text: $store.goalDraftTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Spacer()

                PrimaryButton(title: "开始今天的节奏") {
                    store.createGoal()
                }

                SecondaryButton(title: "返回选狗") {
                    store.go(.adopt)
                }
            }
        }
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
                    moodScore: store.state.dogState.moodScore,
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

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "我和\(store.state.selectedDog.breedName)的进度", title: "这段节奏正在累积", subtitle: nil)

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
                            MetricCard(label: "心情", value: "\(store.state.dogState.moodScore)/10")
                            MetricCard(label: "饱腹", value: "\(store.state.dogState.fullness)")
                            MetricCard(label: "清洁", value: "\(store.state.dogState.cleanliness)")
                            MetricCard(label: "精力", value: "\(store.state.dogState.energy)")
                        }
                    }
                }

                Spacer()

                PrimaryButton(title: "回首页") {
                    store.go(.home)
                }
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
                                    PixelDogSprite(breed: companion.breed, appearance: companion.appearance, size: 60, pose: "idle")

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
                                                PixelDogSprite(breed: dog.breed, appearance: dog.appearance, size: 60, pose: "idle")

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
    @State private var selectedScene = "小院子"

    let scenes = ["小院子", "海边", "森林", "城市阳台"]

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "道具仓库", title: "狗狗世界", subtitle: "收集道具，布置你的狗狗世界场景。")

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("当前场景")
                            .eyebrowStyle()

                        Text(selectedScene)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(hex: 0x356247))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(scenes, id: \.self) { scene in
                                    Button {
                                        selectedScene = scene
                                    } label: {
                                        Text(scene)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedScene == scene ? Color(hex: 0x356247) : Color(hex: 0xEAF1DA))
                                            .foregroundStyle(selectedScene == scene ? .white : Color(hex: 0x356247))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
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
