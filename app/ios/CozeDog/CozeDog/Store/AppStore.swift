import SwiftUI
import UserNotifications

final class AppStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var goalDraftType: GoalType = .fitness
    @Published var goalDraftTitle: String = GoalType.fitness.templates[0].title
    @Published var speechMode: String = "pending"

    private let key = "zilvgou.appState.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoded = try JSONDecoder().decode(AppState.self, from: data)
                state = decoded
                if state.goal == nil, state.screen != .adopt {
                    state.screen = .createGoal
                }
                if state.dogAppearance == nil {
                    state.dogAppearance = DogAppearance.generated(for: state.selectedDog)
                    save()
                }
            } catch {
                print("⚠️ 解码 AppState 失败: \(error)")
                state = .initial
            }
        } else {
            state = .initial
        }
        // 每日属性衰减
        applyDailyDecay()
    }

    func selectDog(_ dog: DogBreed) {
        state.selectedDog = dog
        state.dogAppearance = DogAppearance.generated(for: dog)
        save()
    }

    func randomizeAppearance() {
        state.dogAppearance = DogAppearance.generated(for: state.selectedDog)
        save()
    }

    func go(_ screen: AppScreen) {
        state.screen = screen
        save()
    }

    func prepareGoalCreation() {
        // Add the adopted dog to the collection if not already there
        if let appearance = state.dogAppearance, !state.dogCollection.hasCollected(state.selectedDog) {
            let collectedDog = CollectedDog(
                breed: state.selectedDog,
                appearance: appearance,
                nickname: state.selectedDog.name
            )
            state.dogCollection.dogs.append(collectedDog)
        }

        goalDraftType = .fitness
        goalDraftTitle = GoalType.fitness.templates[0].title
        state.screen = .createGoal
        save()
    }

    func collectDog(breed: DogBreed, appearance: DogAppearance) {
        if !state.dogCollection.hasCollected(breed) {
            let collectedDog = CollectedDog(
                breed: breed,
                appearance: appearance,
                nickname: breed.name
            )
            state.dogCollection.dogs.append(collectedDog)
            state.availableAdoptions = max(0, state.availableAdoptions - 1)
            save()
        }
    }

    func goToAdoption() {
        guard state.availableAdoptions > 0 else { return }
        state.screen = .adoption
        save()
    }

    func setCompanion(id: UUID) {
        guard state.dogCollection.dog(with: id) != nil else { return }
        state.activeCompanionId = id
        save()
    }

    func removeCompanion() {
        state.activeCompanionId = nil
        save()
    }

    func selectGoalType(_ type: GoalType) {
        goalDraftType = type
        goalDraftTitle = type.templates[0].title
    }

    func createGoal() {
        let goal = Goal(id: UUID(), type: goalDraftType, title: goalDraftTitle, createdAt: Date(), updatedAt: Date())
        state.goal = goal
        state.screen = .home
        speechMode = "pending"
        save()
    }

    func hasMainCheckInToday() -> Bool {
        guard let goal = state.goal else { return false }
        let today = assignedDate()
        return state.checkIns.contains { $0.goalId == goal.id && $0.assignedDate == today && $0.type == .main }
    }

    func todayCompletedPlanTitles() -> [String] {
        let today = assignedDate()
        return state.checkIns
            .filter { $0.assignedDate == today && $0.type == .main }
            .sorted { $0.completedAt < $1.completedAt }
            .compactMap { $0.completedPlanTitle }
    }

    func completeMainGoal() {
        guard let goal = state.goal else { return }
        let gains = gainsForGoal(goal.type)
        complete(type: .main, message: copy(for: "done"), gains: gains)
    }

    func openDogGo() {
        state.actionSession = ActionSession(phase: .choosingPlan, plan: nil, durationSeconds: 0, remainingSeconds: 0)
        speechMode = "pending"
        save()
    }

    func selectActionPlan(_ plan: ActionPlan) {
        state.actionSession = ActionSession(phase: .choosingTime, plan: plan, durationSeconds: 0, remainingSeconds: 0)
        state.dogState.mood = .neutral
        state.dogState.pose = .idle
        save()
    }

    func startActionTimer(minutes: Int) {
        let plan = state.actionSession.plan ?? .study
        let seconds = max(60, minutes * 60)
        state.actionSession = ActionSession(phase: .running, plan: plan, durationSeconds: seconds, remainingSeconds: seconds)
        state.dogState.mood = .neutral
        state.dogState.pose = .focused  // 专注姿态
        speechMode = "pending"

        // 启动专注模式
        startFocusMode(plan: plan, durationSeconds: seconds)

        save()
    }

    func tickActionTimer() {
        guard state.actionSession.phase == .running else { return }
        let remaining = max(0, state.actionSession.remainingSeconds - 1)
        state.actionSession.remainingSeconds = remaining

        // 专注模式逻辑
        if state.isFocusMode {
            // 计算进度
            let elapsed = state.actionSession.durationSeconds - remaining
            let progress = Int((Double(elapsed) / Double(state.actionSession.durationSeconds)) * 100)

            // 检查鼓励时机
            checkAndShowEncouragement(progress: progress)

            // 检查休息提醒（番茄时间：25分钟专注 + 5分钟休息）
            checkRestReminder(elapsedSeconds: elapsed)
        }

        if remaining == 0 {
            state.actionSession.phase = .finished
            state.dogState.mood = .happy
            state.dogState.pose = .happy
            speechMode = "done"

            // 完成专注会话
            if state.isFocusMode {
                completeFocusSession()
            }
        }
        save()
    }

    func cancelActionSession() {
        // 如果正在专注模式，记录放弃
        if state.isFocusMode {
            abandonFocusSession()
        }

        state.actionSession = .idle
        state.dogState.mood = .neutral
        state.dogState.pose = .idle
        speechMode = "pending"
        save()
    }

    func completeActionSession() {
        let session = state.actionSession
        let plan = session.plan
        state.actionSession = .idle

        if let plan, state.goal == nil {
            state.goal = Goal(id: UUID(), type: plan.rewardGoalType, title: "\(plan.label) \(max(1, session.durationSeconds / 60)) 分钟", createdAt: Date(), updatedAt: Date())
        }

        if state.goal == nil {
            state.goal = Goal(id: UUID(), type: plan?.rewardGoalType ?? .study, title: "\(plan?.label ?? "学习")行动", createdAt: Date(), updatedAt: Date())
        }

        guard state.goal != nil else {
            state.screen = .feedback
            save()
            return
        }

        complete(type: .main, message: copy(for: "done"), gains: dogGoGains(durationSeconds: session.durationSeconds), completedPlanTitle: completedPlanTitle(for: session))
    }

    func completeRecoveryGoal() {
        let gains = [
            StateGain(label: "亲密度", amount: 2),
            StateGain(label: "饱腹", amount: 10),
            StateGain(label: "清洁", amount: 10),
            StateGain(label: "精力", amount: 10)
        ]
        complete(type: .recovery, message: copy(for: "recoveryDone"), gains: gains)
    }

    func simulateMissedDay() {
        state.rhythmState.status = .missed
        state.rhythmState.missedDays = 1
        // 设置 lastActiveDate 为昨天，触发衰减
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        state.dogState.lastActiveDate = formatter.string(from: yesterday)
        state.dogState.pose = .waiting
        speechMode = "pending"
        save()
        // 重新触发衰减
        applyDailyDecay()
    }

    func useSmallGoal() {
        guard var goal = state.goal else { return }
        goal.title = recoveryTitle()
        goal.updatedAt = Date()
        state.goal = goal
        state.rhythmState = .initial
        state.dogState.mood = .happy
        state.dogState.pose = .idle
        save()
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        state = .initial
        goalDraftType = .fitness
        goalDraftTitle = GoalType.fitness.templates[0].title
        speechMode = "pending"
    }

    func currentDogAppearance() -> DogAppearance {
        state.dogAppearance ?? DogAppearance.generated(for: state.selectedDog, seed: "fallback-\(state.selectedDog.rawValue)")
    }

    func speechText() -> String {
        if state.rhythmState.status == .longBreak { return copy(for: "longBreak") }
        if state.rhythmState.status == .missed { return copy(for: speechMode == "done" ? "recoveryDone" : "recovery") }
        if speechMode == "tap" { return copy(for: "tap") }
        if speechMode == "done" || hasMainCheckInToday() { return copy(for: "done") }
        return copy(for: "pending")
    }

    func recoveryTitle() -> String {
        guard let goal = state.goal else { return "做个小恢复" }
        return goal.type.templates.first(where: { $0.title == goal.title })?.recoveryTitle ?? "做个小恢复"
    }

    func weekCompletion() -> [Bool] {
        let dates = (0..<7).map { offset -> String in
            let date = Calendar.current.date(byAdding: .day, value: offset - 6, to: Date()) ?? Date()
            return assignedDate(for: date)
        }
        return dates.map { date in
            state.checkIns.contains { $0.assignedDate == date }
        }
    }

    func nextLevelNeed() -> Int {
        10
    }

    private func complete(type: CheckInType, message: String, gains: [StateGain], completedPlanTitle: String? = nil) {
        guard let goal = state.goal else { return }
        let checkIn = CheckIn(id: UUID(), goalId: goal.id, type: type, completedAt: Date(), assignedDate: assignedDate(), completedPlanTitle: completedPlanTitle)
        state.checkIns.append(checkIn)

        // Track main goal completions for adoption triggers and evolution
        if type == .main {
            state.totalMainCheckIns += 1
            if state.totalMainCheckIns % 10 == 0 {
                state.availableAdoptions += 1
            }
            // 检测进化
            checkEvolution()
            // 检测成就解锁
            checkAndUnlockAchievements()
        }

        // 生成日记（如果今天还没有）
        generateDailyDiaryIfNeeded()

        var leveledUp = false
        var rewardItem: PixelRewardItem?

        for gain in gains {
            switch gain.label {
            case "亲密度":
                state.dogState.intimacy += gain.amount
                while state.dogState.intimacy >= nextLevelNeed() {
                    state.dogState.intimacy -= nextLevelNeed()
                    state.dogState.level += 1
                    leveledUp = true
                    let item = randomRewardItem()
                    state.dogState.inventory.append(item)
                    rewardItem = item
                }
            case "心情": state.dogState.moodScore = clampToTen(state.dogState.moodScore + gain.amount)
            case "饱腹": state.dogState.fullness = clamp(state.dogState.fullness + gain.amount)
            case "清洁": state.dogState.cleanliness = clamp(state.dogState.cleanliness + gain.amount)
            case "精力": state.dogState.energy = clamp(state.dogState.energy + gain.amount)
            default: break
            }
        }

        // 更新活跃日期，用于下次启动时的衰减计算
        state.dogState.lastActiveDate = assignedDate()

        // 属性变化后重新派生心情
        updateDogMood()
        state.dogState.pose = .happy
        state.rhythmState.status = type == .recovery ? .recovering : .stable
        state.rhythmState.currentStreak += 1
        state.rhythmState.missedDays = 0
        state.rhythmState.lastCompletedDate = assignedDate()
        state.lastFeedback = FeedbackState(message: message, gains: gains, leveledUp: leveledUp, rewardItem: rewardItem, celebrationPose: randomCelebrationPose(), completedPlanTitle: completedPlanTitle)
        state.screen = .feedback
        speechMode = "done"
        save()
    }

    private func completedPlanTitle(for session: ActionSession) -> String? {
        guard let plan = session.plan else { return nil }
        return "\(plan.label) \(max(1, session.durationSeconds / 60))m"
    }

    private func dogGoGains(durationSeconds: Int) -> [StateGain] {
        let minutes = durationSeconds / 60
        // 亲密度随时长阶梯增长
        let intimacyGain: Int
        let statGain: Int
        switch minutes {
        case ..<15:
            intimacyGain = 1; statGain = 1
        case ..<30:
            intimacyGain = 2; statGain = 3
        case ..<60:
            intimacyGain = 3; statGain = 6
        default:
            intimacyGain = 5; statGain = 10
        }
        return [
            StateGain(label: "亲密度", amount: intimacyGain),
            StateGain(label: "饱腹", amount: statGain),
            StateGain(label: "清洁", amount: statGain),
            StateGain(label: "精力", amount: statGain)
        ]
    }

    private func gainsForGoal(_ type: GoalType) -> [StateGain] {
        switch type {
        case .fitness:
            return [
                StateGain(label: "亲密度", amount: 3),
                StateGain(label: "饱腹", amount: 15),
                StateGain(label: "精力", amount: 20)
            ]
        case .study:
            return [
                StateGain(label: "亲密度", amount: 3),
                StateGain(label: "饱腹", amount: 10),
                StateGain(label: "精力", amount: 10)
            ]
        case .sleep:
            return [
                StateGain(label: "亲密度", amount: 3),
                StateGain(label: "清洁", amount: 20),
                StateGain(label: "精力", amount: 15)
            ]
        }
    }

    private func copy(for event: String) -> String {
        switch state.selectedDog {
        case .shiba:
            return [
                "pending": "来吧，先动一下。",
                "tap": "看见你了，准备好没？",
                "done": "好，今天拿下。",
                "recovery": "断一下不算输。",
                "recoveryDone": "好，回来了。",
                "longBreak": "目标太重就拆小。"
            ][event] ?? "来吧，先动一下。"
        case .golden:
            return [
                "pending": "今天先做一点点就好。",
                "tap": "你来了，我很开心。",
                "done": "你做到了，我看见了。",
                "recovery": "昨天没关系，今天还在。",
                "recoveryDone": "欢迎回来。",
                "longBreak": "我们把目标调轻一点吧。"
            ][event] ?? "今天先做一点点就好。"
        case .borderCollie:
            return [
                "pending": "今天只看下一步。",
                "tap": "我在，目标还清楚。",
                "done": "完成，记录有效。",
                "recovery": "昨天偏离，今天恢复。",
                "recoveryDone": "恢复动作完成。",
                "longBreak": "当前目标阻力偏高。"
            ][event] ?? "今天只看下一步。"
        case .native:
            return [
                "pending": "今天咱先做一点。",
                "tap": "来啦，我看见你了。",
                "done": "好，今天接住了。",
                "recovery": "没事，我还在这儿。",
                "recoveryDone": "门又打开了。",
                "longBreak": "目标大了，咱就改小。"
            ][event] ?? "今天咱先做一点。"
        case .bulldog:
            return [
                "pending": "慢慢来，不着急。",
                "tap": "我在，稳住。",
                "done": "好，又完成一个。",
                "recovery": "没事，继续走。",
                "recoveryDone": "回来了，很好。",
                "longBreak": "目标太重就拆小步。"
            ][event] ?? "慢慢来，不着急。"
        case .teddy:
            return [
                "pending": "来玩个游戏吧！",
                "tap": "你来了！好开心！",
                "done": "太棒了！你做到了！",
                "recovery": "没关系，我还在等你。",
                "recoveryDone": "欢迎回来！继续加油！",
                "longBreak": "累了就休息一下下。"
            ][event] ?? "来玩个游戏吧！"
        }
    }

    private func assignedDate(for date: Date = Date()) -> String {
        var target = date
        if Calendar.current.component(.hour, from: target) < 4 {
            target = Calendar.current.date(byAdding: .day, value: -1, to: target) ?? target
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: target)
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    private func clampToTen(_ value: Int) -> Int {
        max(0, min(10, value))
    }

    private func randomRewardItem() -> PixelRewardItem {
        PixelRewardItem.allCases.randomElement() ?? .redBall
    }

    private func randomCelebrationPose() -> DogPose {
        switch state.selectedDog {
        case .shiba:
            return [.jump, .spin, .dash].randomElement() ?? .jump
        case .golden:
            return [.jump, .heart, .roll].randomElement() ?? .heart
        case .borderCollie:
            return [.spin, .dash, .spark].randomElement() ?? .spin
        case .native:
            return [.jump, .heart, .spark].randomElement() ?? .jump
        case .bulldog:
            return [.jump, .roll, .heart].randomElement() ?? .jump
        case .teddy:
            return [.spin, .jump, .dash].randomElement() ?? .spin
        }
    }

    // MARK: - 专注模式功能

    func startFocusMode(plan: ActionPlan, durationSeconds: Int) {
        state.isFocusMode = true
        state.focusStartTime = Date()
        state.lastEncouragementProgress = 0

        // 安排专注完成通知
        scheduleFocusNotifications(durationSeconds: durationSeconds)
    }

    func checkAndShowEncouragement(progress: Int) {
        let milestones = [25, 50, 75, 90]

        for milestone in milestones {
            if progress >= milestone && state.lastEncouragementProgress < milestone {
                state.lastEncouragementProgress = milestone
                // 鼓励消息会在 UI 层通过观察 lastEncouragementProgress 变化来显示
                break
            }
        }
    }

    func checkRestReminder(elapsedSeconds: Int) {
        // 番茄时间：25分钟（1500秒）后提醒休息
        let pomodoroDuration = 25 * 60
        if elapsedSeconds == pomodoroDuration {
            // 休息提醒会在 UI 层通过观察 elapsedSeconds 来显示
            // 这里可以添加通知或其他逻辑
        }
    }

    func startRest() {
        state.isResting = true
        state.restStartTime = Date()
        save()
    }

    func endRest() {
        state.isResting = false
        state.restStartTime = nil
        // 重置鼓励进度，因为休息后继续专注
        state.lastEncouragementProgress = 0
        save()
    }

    func completeFocusSession() {
        guard let startTime = state.focusStartTime else { return }

        let session = FocusSession(
            id: UUID(),
            plan: state.actionSession.plan ?? .study,
            durationSeconds: state.actionSession.durationSeconds,
            startedAt: startTime,
            completedAt: Date(),
            completed: true
        )

        // 更新统计
        state.focusSessions.append(session)
        state.focusSessionsCount += 1
        state.totalFocusMinutes += state.actionSession.durationSeconds / 60
        state.longestFocusSession = max(state.longestFocusSession, state.actionSession.durationSeconds / 60)

        // 重置专注模式状态
        state.isFocusMode = false
        state.focusStartTime = nil
        state.lastEncouragementProgress = 0

        // 取消通知
        cancelFocusNotifications()
    }

    func abandonFocusSession() {
        guard let startTime = state.focusStartTime else { return }

        let elapsedSeconds = state.actionSession.durationSeconds - state.actionSession.remainingSeconds

        // 只记录超过 1 分钟的专注
        if elapsedSeconds >= 60 {
            let session = FocusSession(
                id: UUID(),
                plan: state.actionSession.plan ?? .study,
                durationSeconds: elapsedSeconds,
                startedAt: startTime,
                completedAt: Date(),
                completed: false
            )
            state.focusSessions.append(session)
        }

        // 重置专注模式状态
        state.isFocusMode = false
        state.focusStartTime = nil
        state.lastEncouragementProgress = 0

        // 取消通知
        cancelFocusNotifications()
    }

    func scheduleFocusNotifications(durationSeconds: Int) {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else { return }

            // 安排专注完成通知
            let content = UNMutableNotificationContent()
            content.title = "专注完成！"
            content.body = "太棒了！你完成了一次专注。"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(durationSeconds), repeats: false)
            let request = UNNotificationRequest(identifier: "focusComplete", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    func cancelFocusNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focusComplete"])
    }

    func encouragementCopy(progress: Int) -> String {
        switch state.selectedDog {
        case .shiba:
            switch progress {
            case 25: return "开始了，加油！"
            case 50: return "已经一半了，继续！"
            case 75: return "快完成了，坚持！"
            case 90: return "最后一点，冲刺！"
            default: return ""
            }
        case .golden:
            switch progress {
            case 25: return "你做得很好，继续保持！"
            case 50: return "我在这里陪你，不着急。"
            case 75: return "慢慢来，你已经在进步了。"
            case 90: return "快要到了，我相信你！"
            default: return ""
            }
        case .borderCollie:
            switch progress {
            case 25: return "进度正常，保持节奏。"
            case 50: return "中点达成，效率良好。"
            case 75: return "接近目标，维持专注。"
            case 90: return "即将完成，最后冲刺。"
            default: return ""
            }
        case .native:
            switch progress {
            case 25: return "开始啦，咱慢慢来。"
            case 50: return "一半了，不着急。"
            case 75: return "快啦，再坚持一下。"
            case 90: return "就差一点了，加油！"
            default: return ""
            }
        case .bulldog:
            switch progress {
            case 25: return "稳住了，继续。"
            case 50: return "一半了，节奏很好。"
            case 75: return "快到了，保持住。"
            case 90: return "最后一点，稳住。"
            default: return ""
            }
        case .teddy:
            switch progress {
            case 25: return "开始啦！好棒！"
            case 50: return "一半了！继续继续！"
            case 75: return "快完成啦！加油！"
            case 90: return "就差一点点！冲呀！"
            default: return ""
            }
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("⚠️ 编码 AppState 失败: \(error)")
        }
    }

    // MARK: - 狗狗成长进化系统

    /// 检测并触发进化
    func checkEvolution() {
        let newEvolution = DogEvolution.from(totalCheckIns: state.totalMainCheckIns)
        let oldEvolution = state.dogEvolution

        if newEvolution != oldEvolution {
            state.dogEvolution = newEvolution
            // 进化提示会在 UI 层通过观察 dogEvolution 变化来显示
            print("🎉 狗狗进化了！\(oldEvolution.displayName) → \(newEvolution.displayName)")
        }
    }

    // MARK: - 场景系统

    /// 设置当前场景
    func setScene(_ scene: SceneType) {
        state.sceneSettings.currentScene = scene
        save()
    }

    /// 放置互动元素
    func placeItem(_ itemType: ItemType, at position: CGPoint) {
        let item = PlacedItem(itemType: itemType, position: position)
        state.sceneSettings.placedItems.append(item)
        save()
    }

    /// 移除互动元素
    func removeItem(_ itemId: UUID) {
        state.sceneSettings.placedItems.removeAll { $0.id == itemId }
        save()
    }

    /// 发现彩蛋
    func discoverEasterEgg(_ eggId: String) {
        state.sceneSettings.discoveredEasterEggs.insert(eggId)
        save()
    }

    /// 每日属性衰减（方案 B）：饱腹/清洁/精力各 -8/天，下限 10
    private func applyDailyDecay() {
        guard let lastActive = state.dogState.lastActiveDate else {
            // 首次使用，记录今天但不衰减
            state.dogState.lastActiveDate = assignedDate()
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = formatter.date(from: lastActive) else { return }

        let today = Date()
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
        guard days > 0 else { return }

        let decay = min(days * 8, 90)  // 每天 -8，最多衰减 90（保留下限 10）
        state.dogState.fullness = max(10, state.dogState.fullness - decay)
        state.dogState.cleanliness = max(10, state.dogState.cleanliness - decay)
        state.dogState.energy = max(10, state.dogState.energy - decay)

        // 衰减后重新派生心情
        updateDogMood()
        save()
    }

    /// 更新狗狗心情（基于三项属性均值派生）
    func updateDogMood() {
        state.dogMood = DogMood.from(
            fullness: state.dogState.fullness,
            cleanliness: state.dogState.cleanliness,
            energy: state.dogState.energy
        )
        state.dogState.mood = state.dogMood.rawValue
    }

    /// 获取最近 N 天的完成次数
    func getRecentCheckInsCount(days: Int) -> Int {
        let calendar = Calendar.current
        let today = Date()

        var count = 0
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dateStr = assignedDate(for: date)
            if state.checkIns.contains(where: { $0.assignedDate == dateStr && $0.type == .main }) {
                count += 1
            }
        }
        return count
    }

    /// 生成每日日记（如果今天还没有）
    func generateDailyDiaryIfNeeded() {
        let today = assignedDate()

        // 检查今天是否已经生成过日记
        if let lastDate = state.lastDiaryDate, assignedDate(for: lastDate) == today {
            return
        }

        // 获取今天的数据
        let todayCheckIns = state.checkIns.filter { $0.assignedDate == today && $0.type == .main }
        let completions = todayCheckIns.count
        let focusMinutes = state.focusSessions
            .filter { assignedDate(for: $0.startedAt) == today && $0.completed }
            .reduce(0) { $0 + $1.durationSeconds / 60 }
        let streak = state.rhythmState.currentStreak
        let mood = state.dogMood

        // 生成日记内容
        let content = generateDiaryContent(
            breed: state.selectedDog,
            completions: completions,
            focusMinutes: focusMinutes,
            streak: streak,
            mood: mood
        )

        // 创建日记条目
        let entry = DogDiaryEntry(
            date: Date(),
            content: content,
            mood: mood,
            completions: completions,
            focusMinutes: focusMinutes,
            streakDays: streak
        )

        state.diaryEntries.append(entry)
        state.lastDiaryDate = Date()
    }

    /// 生成日记内容（模板 + 品种性格）
    private func generateDiaryContent(breed: DogBreed, completions: Int, focusMinutes: Int, streak: Int, mood: DogMood) -> String {
        let templates: [String]

        switch breed {
        case .shiba:
            // 傲娇毒舌
            templates = [
                "今天主人完成了 \(completions) 个计划，勉强及格吧...才不是为你高兴呢！",
                "专注了 \(focusMinutes) 分钟，哼，算你努力。",
                "连续打卡 \(streak) 天了，本汪才不会夸你。",
                "今天什么都没做？本汪都快忘了你长什么样了。",
                "又来找我玩了？好吧，陪你一下。"
            ]
        case .golden:
            // 暖心鼓励
            templates = [
                "今天完成了 \(completions) 个计划！主人好棒！尾巴都摇累了！",
                "专注了 \(focusMinutes) 分钟呢，主人认真的样子最帅了！",
                "连续 \(streak) 天了！我们是最好的搭档！",
                "今天也要开开心心的哦！",
                "无论怎样，我都在这里陪你。"
            ]
        case .borderCollie:
            // 理性分析
            templates = [
                "今日完成度：\(completions) 个计划。效率评估：\(mood == .ecstatic ? "优秀" : "良好")。",
                "专注时长 \(focusMinutes) 分钟，建议保持当前节奏。",
                "连续打卡 \(streak) 天，习惯养成进度正常。",
                "数据分析完成，明日目标已准备。",
                "建议：保持当前强度，避免过度疲劳。"
            ]
        case .native:
            // 朴实真诚
            templates = [
                "今天完成了 \(completions) 个计划，踏实的一天。",
                "专注了 \(focusMinutes) 分钟，辛苦了。",
                "连续 \(streak) 天了，慢慢来，不着急。",
                "没事，我还在这儿陪你。",
                "门又打开了，欢迎回来。"
            ]
        case .bulldog:
            // 憨厚可爱
            templates = [
                "呼...今天做了 \(completions) 个计划，好累但是好开心。",
                "专注了 \(focusMinutes) 分钟，我都在旁边陪你哦。",
                "连续 \(streak) 天了，慢慢来，不着急。",
                "没事，继续走。",
                "回来了，很好。"
            ]
        case .teddy:
            // 活泼话痨
            templates = [
                "哇！今天完成了 \(completions) 个计划！太棒了太棒了！",
                "专注了 \(focusMinutes) 分钟！你好厉害！我好开心！",
                "连续 \(streak) 天了！继续继续！冲冲冲！",
                "快来快来！今天也要开开心心！",
                "你来了！好开心好开心！"
            ]
        }

        return templates.randomElement() ?? "今天也是平凡的一天。"
    }

    /// 获取最近的日记条目
    func getRecentDiaryEntries(limit: Int = 7) -> [DogDiaryEntry] {
        Array(state.diaryEntries.suffix(limit)).reversed()
    }

    // MARK: - 每日任务建议系统

    /// 获取智能推荐任务（综合评分算法）
    func recommendTasks(limit: Int = 5) -> [TaskTemplate] {
        let currentTimeSlot = TaskTimeSlot.current
        let allPresetTasks = PresetTaskLibrary.allTasks
        let customTasksAsTemplates = state.customTasks.map { customTask in
            TaskTemplate(
                id: customTask.id.uuidString,
                title: customTask.title,
                goalType: customTask.goalType,
                estimatedMinutes: customTask.estimatedMinutes,
                timeSlots: TaskTimeSlot.allCases,
                tags: ["自定义"]
            )
        }
        let allTasks = allPresetTasks + customTasksAsTemplates

        // 过滤掉今天已完成的任务
        let todayCompletedTitles = Set(
            state.taskHistory
                .filter { isSameDay($0.acceptedDate, Date()) && $0.completed }
                .map(\.title)
        )
        let availableTasks = allTasks.filter { !todayCompletedTitles.contains($0.title) }

        // 计算每个任务的综合评分
        let scoredTasks = availableTasks.map { task -> (task: TaskTemplate, score: Double) in
            let score = calculateTaskScore(task: task, currentTimeSlot: currentTimeSlot)
            return (task, score)
        }

        // 按评分排序，取前 N 个
        let sorted = scoredTasks.sorted { $0.score > $1.score }
        return Array(sorted.prefix(limit)).map(\.task)
    }

    /// 计算任务综合评分
    private func calculateTaskScore(task: TaskTemplate, currentTimeSlot: TaskTimeSlot) -> Double {
        var score = 0.0

        // 1. 时间段匹配度 (30%)
        if task.timeSlots.contains(currentTimeSlot) {
            score += 0.30
        }

        // 2. 历史频率 (25%) - 最近做过的任务降低优先级
        let recentHistory = state.taskHistory.suffix(20)
        let taskHistoryCount = recentHistory.filter { $0.title == task.title }.count
        let maxHistoryCount = Double(max(recentHistory.count, 1))
        let frequencyScore = 1.0 - (Double(taskHistoryCount) / maxHistoryCount)
        score += 0.25 * frequencyScore

        // 3. 新鲜度 (25%) - 最近没做过的任务得分更高
        let lastDoneDate = state.taskHistory
            .filter { $0.title == task.title }
            .last?.acceptedDate
        let freshnessScore: Double
        if let lastDate = lastDoneDate {
            let daysSinceLastDone = Date().timeIntervalSince(lastDate) / 86400
            freshnessScore = min(1.0, daysSinceLastDone / 7.0) // 7天内线性增长
        } else {
            freshnessScore = 1.0 // 从未做过，最高分
        }
        score += 0.25 * freshnessScore

        // 4. 多样性 (20%) - 优先推荐不同类型的任务
        let recentGoalTypes = state.taskHistory.suffix(5).map(\.goalType)
        let diversityScore = recentGoalTypes.contains(task.goalType) ? 0.5 : 1.0
        score += 0.20 * diversityScore

        // 5. 收藏任务加权
        if let customTask = state.customTasks.first(where: { $0.title == task.title }),
           customTask.isFavorite {
            score += 0.15
        }

        return score
    }

    /// 接受任务建议
    func acceptTaskSuggestion(_ task: TaskTemplate) {
        // 记录到历史
        let historyEntry = TaskHistoryEntry(
            title: task.title,
            goalType: task.goalType,
            acceptedDate: Date()
        )
        state.taskHistory.append(historyEntry)
        state.lastTaskRecommendationDate = Date()

        // 自动填充 Dog Go 表单
        goalDraftType = task.goalType
        goalDraftTitle = task.title

        // 打开 Dog Go
        openDogGo()
        save()
    }

    /// 标记任务完成
    func completeTaskSuggestion(_ taskTitle: String) {
        if let index = state.taskHistory.lastIndex(where: { $0.title == taskTitle && !$0.completed }) {
            state.taskHistory[index].completed = true
            state.taskHistory[index].completedDate = Date()
            save()
        }
    }

    /// 添加自定义任务
    func addCustomTask(title: String, goalType: GoalType, estimatedMinutes: Int) {
        let newTask = CustomTask(
            title: title,
            goalType: goalType,
            estimatedMinutes: estimatedMinutes
        )
        state.customTasks.append(newTask)
        save()
    }

    /// 切换任务收藏状态
    func toggleTaskFavorite(_ customTaskId: UUID) {
        if let index = state.customTasks.firstIndex(where: { $0.id == customTaskId }) {
            state.customTasks[index].isFavorite.toggle()
            save()
        }
    }

    /// 删除自定义任务
    func deleteCustomTask(_ customTaskId: UUID) {
        state.customTasks.removeAll { $0.id == customTaskId }
        save()
    }

    /// 获取今日任务统计
    func getTodayTaskStats() -> (completed: Int, total: Int) {
        let todayTasks = state.taskHistory.filter { isSameDay($0.acceptedDate, Date()) }
        let completed = todayTasks.filter(\.completed).count
        return (completed, todayTasks.count)
    }

    /// 判断两个日期是否同一天
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    /// 获取连续完成任务天数
    func getTaskStreak() -> Int {
        let calendar = Calendar.current
        let sortedHistory = state.taskHistory
            .filter(\.completed)
            .sorted { $0.completedDate ?? $0.acceptedDate < $1.completedDate ?? $1.acceptedDate }

        guard let lastDate = sortedHistory.last?.completedDate ?? sortedHistory.last?.acceptedDate else {
            return 0
        }

        // 如果今天没有完成任何任务，检查昨天
        if !calendar.isDateInToday(lastDate) {
            if calendar.isDateInYesterday(lastDate) {
                // 昨天完成了，继续计算
            } else {
                return 0 // 超过一天没完成
            }
        }

        var streak = 0
        var currentDate = Date()

        for _ in 0..<365 { // 最多回溯一年
            let hasCompletedOnDate = sortedHistory.contains { entry in
                let date = entry.completedDate ?? entry.acceptedDate
                return calendar.isDate(date, inSameDayAs: currentDate)
            }

            if hasCompletedOnDate {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - 习惯追踪日历系统

    /// 聚合所有打卡记录（从现有数据源）
    func aggregateCheckInRecords() -> [CheckInRecord] {
        var records: [CheckInRecord] = []

        // 1. 聚合主打卡记录（从 checkIns 数组）
        for checkIn in state.checkIns {
            records.append(CheckInRecord(
                date: checkIn.completedAt,
                type: .mainCheckIn,
                goalType: state.goal?.type
            ))
        }

        // 2. 聚合专注记录
        for session in state.focusSessions {
            records.append(CheckInRecord(
                date: session.startedAt,
                type: .focusSession,
                goalType: session.plan.rewardGoalType,
                duration: session.durationSeconds
            ))
        }

        // 3. 聚合任务完成记录
        for entry in state.taskHistory where entry.completed {
            if let completedDate = entry.completedDate {
                records.append(CheckInRecord(
                    date: completedDate,
                    type: .taskCompletion,
                    goalType: entry.goalType
                ))
            }
        }

        // 按日期排序（最新在前）
        return records.sorted { $0.date > $1.date }
    }

    /// 获取指定日期的打卡记录
    func getCheckIns(for date: Date) -> [CheckInRecord] {
        let records = aggregateCheckInRecords()
        return records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// 检查指定日期是否有打卡
    func hasCheckIn(on date: Date) -> Bool {
        return !getCheckIns(for: date).isEmpty
    }

    /// 计算当前连续打卡天数
    func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        // 如果今天没有打卡，从昨天开始计算
        if !hasCheckIn(on: currentDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return 0
            }
            if !hasCheckIn(on: yesterday) {
                return 0 // 昨天也没打卡
            }
            currentDate = yesterday
        }

        // 向前回溯计算连续天数
        for _ in 0..<365 { // 最多回溯一年
            if hasCheckIn(on: currentDate) {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDate
            } else {
                break
            }
        }

        return streak
    }

    /// 计算历史最长连续打卡天数
    func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let records = aggregateCheckInRecords()

        // 获取所有有打卡的日期（去重）
        var uniqueDates: Set<Date> = []
        for record in records {
            let startOfDay = calendar.startOfDay(for: record.date)
            uniqueDates.insert(startOfDay)
        }

        let sortedDates = uniqueDates.sorted()
        guard !sortedDates.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i - 1]
            let currentDate = sortedDates[i]

            // 检查是否连续（相差1天）
            if let expectedDate = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(expectedDate, inSameDayAs: currentDate) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    /// 计算指定月份的完成率
    func calculateMonthlyCompletionRate(for month: Date = Date()) -> Double {
        let calendar = Calendar.current

        // 获取月份的起止日期
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        let startDate = monthInterval.start
        let endDate = monthInterval.end

        // 计算月份的天数
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count else {
            return 0
        }

        // 如果是当前月份，只计算到今天
        let lastDay = calendar.isDateInToday(month) || month > Date()
            ? calendar.component(.day, from: Date())
            : daysInMonth

        // 统计有打卡的天数
        var checkInDays: Set<Date> = []
        let records = aggregateCheckInRecords()

        for record in records {
            let recordDate = record.date
            if recordDate >= startDate && recordDate < endDate {
                let startOfDay = calendar.startOfDay(for: recordDate)
                checkInDays.insert(startOfDay)
            }
        }

        let checkInCount = checkInDays.count
        return Double(checkInCount) / Double(lastDay)
    }

    /// 获取指定月份的打卡天数
    func getMonthlyCheckInCount(for month: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return 0
        }

        let records = aggregateCheckInRecords()
        var checkInDays: Set<Date> = []

        for record in records {
            if record.date >= monthInterval.start && record.date < monthInterval.end {
                let startOfDay = calendar.startOfDay(for: record.date)
                checkInDays.insert(startOfDay)
            }
        }

        return checkInDays.count
    }

    /// 检查并解锁成就
    func checkAndUnlockAchievements() {
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        let monthlyRate = calculateMonthlyCompletionRate()
        let totalFocusMinutes = state.totalFocusMinutes
        let completedTasks = state.taskHistory.filter { $0.completed }.count

        // 检查连续打卡成就
        let streakAchievements: [(Int, AchievementType)] = [
            (7, .streak7),
            (30, .streak30),
            (100, .streak100),
            (365, .streak365)
        ]

        for (threshold, type) in streakAchievements {
            if (currentStreak >= threshold || longestStreak >= threshold) && !hasAchievement(type) {
                unlockAchievement(type)
            }
        }

        // 检查完美月份
        if monthlyRate >= 1.0 && !hasAchievement(.monthlyPerfect) {
            unlockAchievement(.monthlyPerfect)
        }

        // 检查专注成就
        if state.focusSessionsCount > 0 && !hasAchievement(.firstFocus) {
            unlockAchievement(.firstFocus)
        }

        if totalFocusMinutes >= 6000 && !hasAchievement(.focusMaster) {
            unlockAchievement(.focusMaster)
        }

        // 检查任务成就
        if completedTasks >= 50 && !hasAchievement(.taskChampion) {
            unlockAchievement(.taskChampion)
        }

        save()
    }

    /// 检查是否已获得某成就
    func hasAchievement(_ type: AchievementType) -> Bool {
        return state.achievements.contains { $0.type == type }
    }

    /// 解锁成就
    private func unlockAchievement(_ type: AchievementType) {
        let achievement = Achievement(type: type)
        state.achievements.append(achievement)
    }

    /// 生成月度报告
    func generateMonthlyReport(for month: Date = Date()) -> MonthlyReport {
        let calendar = Calendar.current
        let checkInCount = getMonthlyCheckInCount(for: month)
        let completionRate = calculateMonthlyCompletionRate(for: month)
        let longestStreak = calculateLongestStreak()

        // 统计该月专注时长
        let monthInterval = calendar.dateInterval(of: .month, for: month)
        let focusMinutes = state.focusSessions
            .filter { session in
                if let interval = monthInterval {
                    return session.startedAt >= interval.start && session.startedAt < interval.end
                }
                return false
            }
            .reduce(0) { $0 + $1.durationSeconds }

        // 统计最多的目标类型
        let records = aggregateCheckInRecords()
        let monthRecords = records.filter { record in
            if let interval = monthInterval {
                return record.date >= interval.start && record.date < interval.end
            }
            return false
        }

        let goalTypeCounts = Dictionary(grouping: monthRecords.filter { $0.goalType != nil }, by: { $0.goalType! })
        let topGoalType = goalTypeCounts.max(by: { $0.value.count < $1.value.count })?.key

        return MonthlyReport(
            month: month,
            totalCheckIns: checkInCount,
            completionRate: completionRate,
            longestStreak: longestStreak,
            totalFocusMinutes: focusMinutes,
            topGoalType: topGoalType
        )
    }

    /// 获取断签恢复激励文案
    func getStreakRecoveryMessage() -> String {
        let calendar = Calendar.current
        let lastCheckInDate = aggregateCheckInRecords().first?.date

        guard let lastDate = lastCheckInDate else {
            return "开始你的第一天吧！每一步都很重要 💪"
        }

        let daysSinceLastCheckIn = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        switch daysSinceLastCheckIn {
        case 0:
            return "今天已经打卡了，继续保持！🔥"
        case 1:
            return "坚持就是胜利，继续加油！💪"
        case 2...3:
            return "重新开始，继续前进！每段旅程都有暂停 ✨"
        case 4...7:
            return "欢迎回来！今天的你比昨天更强 🌟"
        default:
            return "每段旅程都有暂停，重要的是重新出发 🌈"
        }
    }
}
