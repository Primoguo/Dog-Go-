import Foundation

enum AppScreen: String, Codable {
    case adopt
    case adoption
    case createGoal
    case home
    case feedback
    case progress
    case dogDog
    case dogHome
    case focusStats
}

enum DogBreed: String, Codable, CaseIterable, Identifiable {
    case shiba
    case golden
    case borderCollie
    case native
    case bulldog
    case teddy

    var id: String { rawValue }

    var breedName: String {
        switch self {
        case .shiba: return "柴犬"
        case .golden: return "金毛"
        case .borderCollie: return "边牧"
        case .native: return "中华田园犬"
        case .bulldog: return "斗牛犬"
        case .teddy: return "泰迪犬"
        }
    }

    var name: String {
        switch self {
        case .shiba: return "小柴"
        case .golden: return "阿金"
        case .borderCollie: return "边边"
        case .native: return "阿土"
        case .bulldog: return "小牛"
        case .teddy: return "泰迪"
        }
    }

    var tags: [String] {
        switch self {
        case .shiba: return ["热血", "直接", "有劲"]
        case .golden: return ["温暖", "稳定", "鼓励"]
        case .borderCollie: return ["聪明", "敏锐", "督促"]
        case .native: return ["踏实", "亲近", "韧性"]
        case .bulldog: return ["倔强", "憨厚", "坚持"]
        case .teddy: return ["机灵", "粘人", "活泼"]
        }
    }

    var initial: String {
        switch self {
        case .shiba: return "柴"
        case .golden: return "金"
        case .borderCollie: return "边"
        case .native: return "田"
        case .bulldog: return "牛"
        case .teddy: return "泰"
        }
    }

    var preview: String {
        switch self {
        case .shiba: return "今天动起来就赢了，我准备好了。"
        case .golden: return "不用一下子很厉害，我们先稳稳开始。"
        case .borderCollie: return "目标要小，动作要真。先完成今天这一项。"
        case .native: return "慢一点也没事，我陪你把今天接回来。"
        case .bulldog: return "别看我慢，我从不后退。一步一步来。"
        case .teddy: return "快来快来！今天也要开开心心完成计划！"
        }
    }
}

enum DogMarking: String, Codable, CaseIterable {
    case none
    case forehead
    case ears
    case tailTip
    case paws
    case backPatch
}

struct DogAppearance: Codable, Equatable {
    var seed: String
    var primaryFurHex: UInt
    var secondaryFurHex: UInt
    var marking: DogMarking
    var collarHex: UInt
    var bodyColorHex: UInt
    var headColorHex: UInt
    var earColorHex: UInt
    var legColorHex: UInt
    var tailColorHex: UInt

    static func generated(for breed: DogBreed, seed: String = UUID().uuidString) -> DogAppearance {
        let hash = stableHash(seed + breed.rawValue)
        let palettes = breed.paletteOptions
        let selected = palettes[safeIndex(hash, count: palettes.count)]
        let markings = breed.markingOptions
        let collars: [UInt] = [0x356247, 0xC65B44, 0x4C7FA6, 0xC69A3E, 0x6A5D9E]
        let colorPool = breed.bodyColorPool

        return DogAppearance(
            seed: seed,
            primaryFurHex: selected.primary,
            secondaryFurHex: selected.secondary,
            marking: markings[safeIndex(hash / 7, count: markings.count)],
            collarHex: collars[safeIndex(hash / 13, count: collars.count)],
            bodyColorHex: colorPool[safeIndex(hash / 17, count: colorPool.count)],
            headColorHex: colorPool[safeIndex(hash / 19, count: colorPool.count)],
            earColorHex: colorPool[safeIndex(hash / 23, count: colorPool.count)],
            legColorHex: colorPool[safeIndex(hash / 29, count: colorPool.count)],
            tailColorHex: colorPool[safeIndex(hash / 31, count: colorPool.count)]
        )
    }

    private static func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(5381)) { partial, byte in
            ((partial << 5) &+ partial) &+ UInt64(byte)
        }
    }

    private static func safeIndex(_ hash: UInt64, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(hash % UInt64(count))
    }

    // MARK: - Backward Compatibility

    enum CodingKeys: String, CodingKey {
        case seed, primaryFurHex, secondaryFurHex, marking, collarHex
        case bodyColorHex, headColorHex, earColorHex, legColorHex, tailColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seed = try container.decode(String.self, forKey: .seed)
        primaryFurHex = try container.decode(UInt.self, forKey: .primaryFurHex)
        secondaryFurHex = try container.decode(UInt.self, forKey: .secondaryFurHex)
        marking = try container.decode(DogMarking.self, forKey: .marking)
        collarHex = try container.decode(UInt.self, forKey: .collarHex)
        // New part-specific colors: fallback to primary/secondary for old saved data
        bodyColorHex = try container.decodeIfPresent(UInt.self, forKey: .bodyColorHex) ?? primaryFurHex
        headColorHex = try container.decodeIfPresent(UInt.self, forKey: .headColorHex) ?? primaryFurHex
        earColorHex = try container.decodeIfPresent(UInt.self, forKey: .earColorHex) ?? primaryFurHex
        legColorHex = try container.decodeIfPresent(UInt.self, forKey: .legColorHex) ?? primaryFurHex
        tailColorHex = try container.decodeIfPresent(UInt.self, forKey: .tailColorHex) ?? primaryFurHex
    }
}

private extension DogBreed {
    var paletteOptions: [(primary: UInt, secondary: UInt)] {
        switch self {
        case .shiba:
            return [(0xD98945, 0xFFF1D6), (0xC46F32, 0xF5D8AA), (0xE69A4D, 0xFFE6BA)]
        case .golden:
            return [(0xE8B75C, 0xFFF0C8), (0xD99A3D, 0xFFE1A6), (0xF0C978, 0xFFF5D6)]
        case .borderCollie:
            return [(0x202321, 0xF4F1E8), (0x2C2C30, 0xFFFFFF), (0x1E2428, 0xE8E5D9)]
        case .native:
            return [(0x9A6A3F, 0xE5C69D), (0x6F5638, 0xD7B181), (0xB97845, 0xF1D2A6), (0x5F4B35, 0xC8A06A)]
        case .bulldog:
            return [(0xC8B8A8, 0xF5EDE5), (0x8B7355, 0xE8DDD0), (0xA0522D, 0xF0E0D0), (0xF5F5DC, 0xFFFFFF)]
        case .teddy:
            return [(0x8B4513, 0xD2B48C), (0x2F1B0E, 0xA0522D), (0xF5DEB3, 0xFFF8DC), (0xD2691E, 0xFFDEAD)]
        }
    }

    /// 7 种体色选项，用于身体各部位（身体、脑袋、耳朵、腿部、尾巴）的随机搭配
    var bodyColorPool: [UInt] {
        switch self {
        case .shiba:
            // 暖橘色系：从深橘到奶油色
            return [0xD98945, 0xC46F32, 0xE69A4D, 0xF4D29D, 0xB8602A, 0xF0C078, 0xFFE6BA]
        case .golden:
            // 金色系：从深金到浅蜜色
            return [0xE8B75C, 0xD99A3D, 0xF0C978, 0xC68B3E, 0xFFDB8F, 0xB87A30, 0xFFF0C8]
        case .borderCollie:
            // 黑白色系：从纯黑到浅灰
            return [0x202321, 0x2C2C30, 0x1E2428, 0x4A4E4D, 0x363A38, 0x5C605E, 0xE8E5D9]
        case .native:
            // 土棕色系：从深棕到浅黄棕
            return [0x9A6A3F, 0x6F5638, 0xB97845, 0x5F4B35, 0xD7B181, 0x835C36, 0xE5C69D]
        case .bulldog:
            // 柔和色系：从灰褐到奶油白
            return [0xC8B8A8, 0x8B7355, 0xA0522D, 0xF5F5DC, 0xD2C4B0, 0xE8DDD0, 0xB8A090]
        case .teddy:
            // 巧克力色系：从深巧克力到小麦色
            return [0x8B4513, 0x2F1B0E, 0xD2691E, 0xA0522D, 0xCD853F, 0x6B3410, 0xDEB887]
        }
    }

    var markingOptions: [DogMarking] {
        switch self {
        case .shiba:
            return [.none, .forehead, .tailTip, .paws]
        case .golden:
            return [.none, .ears, .paws]
        case .borderCollie:
            return [.forehead, .ears, .backPatch, .tailTip]
        case .native:
            return [.none, .forehead, .ears, .backPatch, .paws]
        case .bulldog:
            return [.none, .forehead, .ears, .paws]
        case .teddy:
            return [.none, .forehead, .ears, .tailTip, .paws]
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case fitness
    case study
    case sleep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fitness: return "健身"
        case .study: return "学习"
        case .sleep: return "作息"
        }
    }

    var templates: [GoalTemplate] {
        switch self {
        case .fitness:
            return [
                GoalTemplate(title: "运动 20 分钟", recoveryTitle: "拉伸 3 分钟"),
                GoalTemplate(title: "拉伸 10 分钟", recoveryTitle: "原地活动 2 分钟")
            ]
        case .study:
            return [
                GoalTemplate(title: "学习 30 分钟", recoveryTitle: "看 1 页"),
                GoalTemplate(title: "背单词 20 个", recoveryTitle: "背 5 个单词")
            ]
        case .sleep:
            return [
                GoalTemplate(title: "23:30 前睡觉", recoveryTitle: "睡前放下手机 5 分钟"),
                GoalTemplate(title: "睡前少刷手机", recoveryTitle: "整理明天计划")
            ]
        }
    }
}

enum ActionPlan: String, Codable, CaseIterable, Identifiable {
    case fitness
    case study
    case leisure

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fitness: return "健身"
        case .study: return "学习"
        case .leisure: return "休闲"
        }
    }

    var activeLabel: String {
        switch self {
        case .fitness: return "健身中"
        case .study: return "学习中"
        case .leisure: return "休闲中"
        }
    }

    var dogLine: String {
        switch self {
        case .fitness: return "狗狗也在动起来"
        case .study: return "狗狗也在专注"
        case .leisure: return "狗狗也在放松"
        }
    }

    var rewardGoalType: GoalType {
        switch self {
        case .fitness: return .fitness
        case .study: return .study
        case .leisure: return .sleep
        }
    }
}

enum ActionSessionPhase: String, Codable {
    case idle
    case choosingPlan
    case choosingTime
    case running
    case finished
}

struct ActionSession: Codable, Equatable {
    var phase: ActionSessionPhase
    var plan: ActionPlan?
    var durationSeconds: Int
    var remainingSeconds: Int

    static let idle = ActionSession(phase: .idle, plan: nil, durationSeconds: 0, remainingSeconds: 0)
}

enum RhythmStatus: String, Codable {
    case stable
    case missed
    case recovering
    case longBreak
    case paused
}

struct GoalTemplate: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let recoveryTitle: String
}

struct Goal: Codable, Identifiable {
    let id: UUID
    var type: GoalType
    var title: String
    var createdAt: Date
    var updatedAt: Date
}

struct CheckIn: Codable, Identifiable {
    let id: UUID
    var goalId: UUID
    var type: CheckInType
    var completedAt: Date
    var assignedDate: String
    var completedPlanTitle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case goalId
        case type
        case completedAt
        case assignedDate
        case completedPlanTitle
    }

    init(id: UUID, goalId: UUID, type: CheckInType, completedAt: Date, assignedDate: String, completedPlanTitle: String? = nil) {
        self.id = id
        self.goalId = goalId
        self.type = type
        self.completedAt = completedAt
        self.assignedDate = assignedDate
        self.completedPlanTitle = completedPlanTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        goalId = try container.decode(UUID.self, forKey: .goalId)
        type = try container.decode(CheckInType.self, forKey: .type)
        completedAt = try container.decode(Date.self, forKey: .completedAt)
        assignedDate = try container.decode(String.self, forKey: .assignedDate)
        completedPlanTitle = try container.decodeIfPresent(String.self, forKey: .completedPlanTitle)
    }
}

enum CheckInType: String, Codable {
    case main
    case recovery
}

struct DogState: Codable {
    var intimacy: Int
    var level: Int
    var mood: String
    var moodScore: Int
    var fullness: Int
    var cleanliness: Int
    var energy: Int
    var pose: String
    var inventory: [PixelRewardItem]

    enum CodingKeys: String, CodingKey {
        case intimacy
        case level
        case mood
        case moodScore
        case fullness
        case cleanliness
        case energy
        case pose
        case inventory
    }

    init(
        intimacy: Int,
        level: Int,
        mood: String,
        moodScore: Int,
        fullness: Int,
        cleanliness: Int,
        energy: Int,
        pose: String,
        inventory: [PixelRewardItem]
    ) {
        self.intimacy = intimacy
        self.level = level
        self.mood = mood
        self.moodScore = moodScore
        self.fullness = fullness
        self.cleanliness = cleanliness
        self.energy = energy
        self.pose = pose
        self.inventory = inventory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intimacy = try container.decode(Int.self, forKey: .intimacy)
        level = try container.decode(Int.self, forKey: .level)
        mood = try container.decode(String.self, forKey: .mood)
        moodScore = try container.decodeIfPresent(Int.self, forKey: .moodScore) ?? 0
        fullness = try container.decode(Int.self, forKey: .fullness)
        cleanliness = try container.decode(Int.self, forKey: .cleanliness)
        energy = try container.decode(Int.self, forKey: .energy)
        pose = try container.decode(String.self, forKey: .pose)
        inventory = try container.decodeIfPresent([PixelRewardItem].self, forKey: .inventory) ?? []
    }

    static let initial = DogState(
        intimacy: 0,
        level: 1,
        mood: "expecting",
        moodScore: 0,
        fullness: 60,
        cleanliness: 60,
        energy: 60,
        pose: "idle",
        inventory: []
    )
}

enum PixelRewardItem: String, Codable, CaseIterable, Identifiable {
    case redBall
    case blueBandana
    case tinyCrown
    case starBone
    case cozyBlanket
    case pixelTv
    case studyLamp
    case miniDumbbell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .redBall: return "红色小球"
        case .blueBandana: return "蓝色围巾"
        case .tinyCrown: return "小王冠"
        case .starBone: return "星星骨头"
        case .cozyBlanket: return "舒服小毯"
        case .pixelTv: return "像素电视"
        case .studyLamp: return "学习台灯"
        case .miniDumbbell: return "迷你哑铃"
        }
    }

    var symbolName: String {
        switch self {
        case .redBall: return "circle.fill"
        case .blueBandana: return "flag.fill"
        case .tinyCrown: return "crown.fill"
        case .starBone: return "star.fill"
        case .cozyBlanket: return "rectangle.fill"
        case .pixelTv: return "tv.fill"
        case .studyLamp: return "lamp.desk.fill"
        case .miniDumbbell: return "dumbbell.fill"
        }
    }

    var colorHex: UInt {
        switch self {
        case .redBall: return 0xC65B44
        case .blueBandana: return 0x4C7FA6
        case .tinyCrown: return 0xF2C94C
        case .starBone: return 0xF5E5BF
        case .cozyBlanket: return 0x7F93BC
        case .pixelTv: return 0x2F3A34
        case .studyLamp: return 0xE8B75C
        case .miniDumbbell: return 0x6A5D9E
        }
    }
}

struct RhythmState: Codable {
    var status: RhythmStatus
    var currentStreak: Int
    var missedDays: Int
    var lastCompletedDate: String?

    static let initial = RhythmState(status: .stable, currentStreak: 0, missedDays: 0, lastCompletedDate: nil)
}

struct FeedbackState: Codable {
    var message: String
    var gains: [StateGain]
    var leveledUp: Bool
    var rewardItem: PixelRewardItem?
    var celebrationPose: String
    var completedPlanTitle: String?

    enum CodingKeys: String, CodingKey {
        case message
        case gains
        case leveledUp
        case rewardItem
        case celebrationPose
        case completedPlanTitle
    }

    init(message: String, gains: [StateGain], leveledUp: Bool = false, rewardItem: PixelRewardItem? = nil, celebrationPose: String = "jump", completedPlanTitle: String? = nil) {
        self.message = message
        self.gains = gains
        self.leveledUp = leveledUp
        self.rewardItem = rewardItem
        self.celebrationPose = celebrationPose
        self.completedPlanTitle = completedPlanTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        gains = try container.decode([StateGain].self, forKey: .gains)
        leveledUp = try container.decodeIfPresent(Bool.self, forKey: .leveledUp) ?? false
        rewardItem = try container.decodeIfPresent(PixelRewardItem.self, forKey: .rewardItem)
        celebrationPose = try container.decodeIfPresent(String.self, forKey: .celebrationPose) ?? "jump"
        completedPlanTitle = try container.decodeIfPresent(String.self, forKey: .completedPlanTitle)
    }
}

struct StateGain: Codable, Identifiable {
    var id: String { label }
    var label: String
    var amount: Int
}

struct AppState: Codable {
    var screen: AppScreen
    var selectedDog: DogBreed
    var dogAppearance: DogAppearance?
    var goal: Goal?
    var dogState: DogState
    var rhythmState: RhythmState
    var checkIns: [CheckIn]
    var lastFeedback: FeedbackState?
    var actionSession: ActionSession
    var dogCollection: DogCollection
    var totalMainCheckIns: Int
    var availableAdoptions: Int
    var activeCompanionId: UUID?

    // 专注模式统计
    var totalFocusMinutes: Int
    var longestFocusSession: Int
    var focusSessionsCount: Int
    var focusSessions: [FocusSession]

    // 专注模式状态
    var isFocusMode: Bool
    var lastEncouragementProgress: Int
    var focusStartTime: Date?

    enum CodingKeys: String, CodingKey {
        case screen
        case selectedDog
        case dogAppearance
        case goal
        case dogState
        case rhythmState
        case checkIns
        case lastFeedback
        case actionSession
        case dogCollection
        case totalMainCheckIns
        case availableAdoptions
        case activeCompanionId
        case totalFocusMinutes
        case longestFocusSession
        case focusSessionsCount
        case focusSessions
        case isFocusMode
        case lastEncouragementProgress
        case focusStartTime
    }

    init(
        screen: AppScreen,
        selectedDog: DogBreed,
        dogAppearance: DogAppearance?,
        goal: Goal?,
        dogState: DogState,
        rhythmState: RhythmState,
        checkIns: [CheckIn],
        lastFeedback: FeedbackState?,
        actionSession: ActionSession,
        dogCollection: DogCollection = DogCollection(),
        totalMainCheckIns: Int = 0,
        availableAdoptions: Int = 0,
        activeCompanionId: UUID? = nil,
        totalFocusMinutes: Int = 0,
        longestFocusSession: Int = 0,
        focusSessionsCount: Int = 0,
        focusSessions: [FocusSession] = [],
        isFocusMode: Bool = false,
        lastEncouragementProgress: Int = 0,
        focusStartTime: Date? = nil
    ) {
        self.screen = screen
        self.selectedDog = selectedDog
        self.dogAppearance = dogAppearance
        self.goal = goal
        self.dogState = dogState
        self.rhythmState = rhythmState
        self.checkIns = checkIns
        self.lastFeedback = lastFeedback
        self.actionSession = actionSession
        self.dogCollection = dogCollection
        self.totalMainCheckIns = totalMainCheckIns
        self.availableAdoptions = availableAdoptions
        self.activeCompanionId = activeCompanionId
        self.totalFocusMinutes = totalFocusMinutes
        self.longestFocusSession = longestFocusSession
        self.focusSessionsCount = focusSessionsCount
        self.focusSessions = focusSessions
        self.isFocusMode = isFocusMode
        self.lastEncouragementProgress = lastEncouragementProgress
        self.focusStartTime = focusStartTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        screen = try container.decode(AppScreen.self, forKey: .screen)
        selectedDog = try container.decode(DogBreed.self, forKey: .selectedDog)
        dogAppearance = try container.decodeIfPresent(DogAppearance.self, forKey: .dogAppearance)
        goal = try container.decodeIfPresent(Goal.self, forKey: .goal)
        dogState = try container.decode(DogState.self, forKey: .dogState)
        rhythmState = try container.decode(RhythmState.self, forKey: .rhythmState)
        checkIns = try container.decode([CheckIn].self, forKey: .checkIns)
        lastFeedback = try container.decodeIfPresent(FeedbackState.self, forKey: .lastFeedback)
        actionSession = try container.decodeIfPresent(ActionSession.self, forKey: .actionSession) ?? .idle
        dogCollection = try container.decodeIfPresent(DogCollection.self, forKey: .dogCollection) ?? DogCollection()
        totalMainCheckIns = try container.decodeIfPresent(Int.self, forKey: .totalMainCheckIns) ?? 0
        availableAdoptions = try container.decodeIfPresent(Int.self, forKey: .availableAdoptions) ?? 0
        activeCompanionId = try container.decodeIfPresent(UUID.self, forKey: .activeCompanionId)

        // 专注模式字段（向后兼容）
        totalFocusMinutes = try container.decodeIfPresent(Int.self, forKey: .totalFocusMinutes) ?? 0
        longestFocusSession = try container.decodeIfPresent(Int.self, forKey: .longestFocusSession) ?? 0
        focusSessionsCount = try container.decodeIfPresent(Int.self, forKey: .focusSessionsCount) ?? 0
        focusSessions = try container.decodeIfPresent([FocusSession].self, forKey: .focusSessions) ?? []
        isFocusMode = try container.decodeIfPresent(Bool.self, forKey: .isFocusMode) ?? false
        lastEncouragementProgress = try container.decodeIfPresent(Int.self, forKey: .lastEncouragementProgress) ?? 0
        focusStartTime = try container.decodeIfPresent(Date.self, forKey: .focusStartTime)
    }

    static let initial = AppState(
        screen: .adopt,
        selectedDog: .native,
        dogAppearance: DogAppearance.generated(for: .native),
        goal: nil,
        dogState: .initial,
        rhythmState: .initial,
        checkIns: [],
        lastFeedback: nil,
        actionSession: .idle,
        dogCollection: DogCollection()
    )
}

// MARK: - Focus Session

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let plan: ActionPlan
    let durationSeconds: Int
    let startedAt: Date
    let completedAt: Date?
    let completed: Bool

    init(id: UUID = UUID(), plan: ActionPlan, durationSeconds: Int, startedAt: Date, completedAt: Date? = nil, completed: Bool = false) {
        self.id = id
        self.plan = plan
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.completed = completed
    }
}

struct CollectedDog: Codable, Identifiable, Equatable {
    let id: UUID
    var breed: DogBreed
    var appearance: DogAppearance
    var nickname: String
    var collectedAt: Date

    init(id: UUID = UUID(), breed: DogBreed, appearance: DogAppearance, nickname: String, collectedAt: Date = Date()) {
        self.id = id
        self.breed = breed
        self.appearance = appearance
        self.nickname = nickname
        self.collectedAt = collectedAt
    }
}

struct DogCollection: Codable {
    var dogs: [CollectedDog]

    init(dogs: [CollectedDog] = []) {
        self.dogs = dogs
    }

    var collectedBreeds: Set<DogBreed> {
        Set(dogs.map(\.breed))
    }

    func hasCollected(_ breed: DogBreed) -> Bool {
        collectedBreeds.contains(breed)
    }

    var totalCollected: Int {
        dogs.count
    }

    var totalPossible: Int {
        DogBreed.allCases.count
    }

    func dog(with id: UUID) -> CollectedDog? {
        dogs.first { $0.id == id }
    }
}
