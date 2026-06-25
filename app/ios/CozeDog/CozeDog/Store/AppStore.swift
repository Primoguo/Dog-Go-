import SwiftUI
import UserNotifications

final class AppStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var goalDraftType: GoalType = .fitness
    @Published var goalDraftTitle: String = GoalType.fitness.templates[0].title
    @Published var speechMode: String = "pending"

    private let key = "zilvgou.appState.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            state = decoded
            if state.goal == nil, state.screen != .adopt {
                state.screen = .createGoal
            }
            if state.dogAppearance == nil {
                state.dogAppearance = DogAppearance.generated(for: state.selectedDog)
                save()
            }
        } else {
            state = .initial
        }
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
        state.dogState.mood = "focused"
        state.dogState.pose = "idle"
        save()
    }

    func startActionTimer(minutes: Int) {
        let plan = state.actionSession.plan ?? .study
        let seconds = max(60, minutes * 60)
        state.actionSession = ActionSession(phase: .running, plan: plan, durationSeconds: seconds, remainingSeconds: seconds)
        state.dogState.mood = "focused"
        state.dogState.pose = "focused"  // 专注姿态
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
            state.dogState.mood = "happy"
            state.dogState.pose = "happy"
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
        state.dogState.mood = "expecting"
        state.dogState.pose = "idle"
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

        complete(type: .main, message: copy(for: "done"), gains: dogGoGains(), completedPlanTitle: completedPlanTitle(for: session))
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
        state.dogState.mood = "waiting"
        state.dogState.pose = "waiting"
        speechMode = "pending"
        save()
    }

    func useSmallGoal() {
        guard var goal = state.goal else { return }
        goal.title = recoveryTitle()
        goal.updatedAt = Date()
        state.goal = goal
        state.rhythmState = .initial
        state.dogState.mood = "expecting"
        state.dogState.pose = "idle"
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

        // Track main goal completions for adoption triggers
        if type == .main {
            state.totalMainCheckIns += 1
            if state.totalMainCheckIns % 10 == 0 {
                state.availableAdoptions += 1
            }
        }

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

        state.dogState.mood = type == .recovery ? "recovering" : "happy"
        state.dogState.pose = "happy"
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

    private func dogGoGains() -> [StateGain] {
        [
            StateGain(label: "亲密度", amount: 1),
            StateGain(label: "心情", amount: 1)
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

    private func randomCelebrationPose() -> String {
        switch state.selectedDog {
        case .shiba:
            return ["jump", "spin", "dash"].randomElement() ?? "jump"
        case .golden:
            return ["jump", "heart", "roll"].randomElement() ?? "heart"
        case .borderCollie:
            return ["spin", "dash", "spark"].randomElement() ?? "spin"
        case .native:
            return ["jump", "heart", "spark"].randomElement() ?? "jump"
        case .bulldog:
            return ["jump", "roll", "heart"].randomElement() ?? "jump"
        case .teddy:
            return ["spin", "jump", "dash"].randomElement() ?? "spin"
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
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
