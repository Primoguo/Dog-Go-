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
            }
        }
    }
}

struct AdoptDogView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 18) {
                Header(eyebrow: "自律狗 iOS MVP", title: "选一只陪你自律的小狗", subtitle: "先选喜欢的，不用管目标类型。它会住进你的小院子，陪你把每天接住。")

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

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预览")
                            .eyebrowStyle()
                        Text(store.state.selectedDog.preview)
                            .font(.title3.weight(.bold))
                        Text("\(store.state.selectedDog.breedName)只影响语气和形象，所有目标都能陪你完成。")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                Spacer()

                PrimaryButton(title: "领养它") {
                    store.prepareGoalCreation()
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
