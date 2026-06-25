import Foundation

// MARK: - Scene System

enum SceneType: String, Codable, CaseIterable {
    case yard       // 温馨小院（幼犬）
    case park       // 阳光公园（成犬）
    case beach      // 海边沙滩（完全体）
    case forest     // 神秘森林（传奇体）

    var displayName: String {
        switch self {
        case .yard: return "温馨小院"
        case .park: return "阳光公园"
        case .beach: return "海边沙滩"
        case .forest: return "神秘森林"
        }
    }

    var icon: String {
        switch self {
        case .yard: return "house.fill"
        case .park: return "tree.fill"
        case .beach: return "beach.umbrella.fill"
        case .forest: return "leaf.fill"
        }
    }

    var requiredEvolution: DogEvolution {
        switch self {
        case .yard: return .puppy
        case .park: return .adult
        case .beach: return .complete
        case .forest: return .legendary
        }
    }

    var isUnlocked: Bool {
        // 这里会根据当前进化阶段判断是否解锁
        return true
    }

    var description: String {
        switch self {
        case .yard: return "温馨的小院子，狗狗的起点"
        case .park: return "阳光明媚的公园，更大的活动空间"
        case .beach: return "美丽的海边沙滩，听着海浪声"
        case .forest: return "神秘的森林，充满魔法气息"
        }
    }
}

// MARK: - Movement System

enum MovementPattern: String, Codable {
    case random          // 随机漫游
    case circular        // 圆形绕圈
    case linear          // 线性来回
    case zoneBased       // 在多个区域间切换
}

struct SceneMovementConfig {
    let pattern: MovementPattern
    let activityZone: CGRect  // 相对坐标（0-1），可活动区域
    let speedMultiplier: Double
    let pauseRange: ClosedRange<Double>  // 停顿时间范围（秒）
    let wanderRange: CGSize  // 漫游范围（相对于 activityZone 的百分比）

    static let `default` = SceneMovementConfig(
        pattern: .random,
        activityZone: CGRect(x: 0.2, y: 0.3, width: 0.6, height: 0.5),
        speedMultiplier: 1.0,
        pauseRange: 2.5...4.0,
        wanderRange: CGSize(width: 0.05, height: 0.04)
    )
}

extension SceneType {
    var movementConfig: SceneMovementConfig {
        switch self {
        case .yard:
            return SceneMovementConfig(
                pattern: .random,
                activityZone: CGRect(x: 0.15, y: 0.35, width: 0.7, height: 0.5),
                speedMultiplier: 1.0,
                pauseRange: 2.8...3.6,
                wanderRange: CGSize(width: 0.05, height: 0.04)
            )
        case .park:
            return SceneMovementConfig(
                pattern: .linear,
                activityZone: CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.3),
                speedMultiplier: 1.2,
                pauseRange: 2.0...3.2,
                wanderRange: CGSize(width: 0.08, height: 0.03)
            )
        case .beach:
            return SceneMovementConfig(
                pattern: .circular,
                activityZone: CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.35),
                speedMultiplier: 1.1,
                pauseRange: 2.5...3.5,
                wanderRange: CGSize(width: 0.06, height: 0.04)
            )
        case .forest:
            return SceneMovementConfig(
                pattern: .zoneBased,
                activityZone: CGRect(x: 0.1, y: 0.3, width: 0.8, height: 0.5),
                speedMultiplier: 0.9,
                pauseRange: 3.0...4.5,
                wanderRange: CGSize(width: 0.07, height: 0.05)
            )
        }
    }
}

enum TimeOfDay: String, Codable {
    case morning    // 早晨 6-10
    case daytime    // 白天 10-17
    case evening    // 黄昏 17-19
    case night      // 夜晚 19-6

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<10: return .morning
        case 10..<17: return .daytime
        case 17..<19: return .evening
        default: return .night
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "清晨"
        case .daytime: return "白天"
        case .evening: return "黄昏"
        case .night: return "夜晚"
        }
    }

    var skyColor: String {
        switch self {
        case .morning: return "#FFE5B4"
        case .daytime: return "#87CEEB"
        case .evening: return "#FF6B6B"
        case .night: return "#191970"
        }
    }

    var ambientLight: Double {
        switch self {
        case .morning: return 0.9
        case .daytime: return 1.0
        case .evening: return 0.7
        case .night: return 0.4
        }
    }
}

enum Weather: String, Codable {
    case sunny      // 晴天
    case cloudy     // 多云
    case rainy      // 雨天
    case snowy      // 雪天

    static var current: Weather {
        // 简单实现：基于日期生成，实际可以接入天气 API
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let season = Season.current

        switch season {
        case .spring:
            return dayOfYear % 5 == 0 ? .rainy : .sunny
        case .summer:
            return .sunny
        case .autumn:
            return dayOfYear % 4 == 0 ? .cloudy : .sunny
        case .winter:
            return dayOfYear % 3 == 0 ? .snowy : .cloudy
        }
    }

    var displayName: String {
        switch self {
        case .sunny: return "晴天"
        case .cloudy: return "多云"
        case .rainy: return "雨天"
        case .snowy: return "雪天"
        }
    }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        }
    }
}

enum Season: String, Codable {
    case spring     // 春
    case summer     // 夏
    case autumn     // 秋
    case winter     // 冬

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    var displayName: String {
        switch self {
        case .spring: return "春天"
        case .summer: return "夏天"
        case .autumn: return "秋天"
        case .winter: return "冬天"
        }
    }

    var leafColor: String {
        switch self {
        case .spring: return "#90EE90"
        case .summer: return "#228B22"
        case .autumn: return "#FF8C00"
        case .winter: return "#FFFFFF"
        }
    }
}

struct SceneSettings: Codable {
    var currentScene: SceneType = .yard
    var timeOfDay: TimeOfDay = .daytime
    var weather: Weather = .sunny
    var season: Season = .spring

    // 互动元素状态
    var placedItems: [PlacedItem] = []
    var discoveredEasterEggs: Set<String> = []

    static let `default` = SceneSettings()
}

struct PlacedItem: Codable, Identifiable {
    let id: UUID
    let itemType: ItemType
    let position: CGPoint

    init(id: UUID = UUID(), itemType: ItemType, position: CGPoint) {
        self.id = id
        self.itemType = itemType
        self.position = position
    }
}

enum ItemType: String, Codable, CaseIterable {
    case ball       // 玩具球
    case foodBowl   // 食盆
    case toy        // 玩具
    case cushion    // 垫子
    case flower     // 花朵

    var displayName: String {
        switch self {
        case .ball: return "玩具球"
        case .foodBowl: return "食盆"
        case .toy: return "玩具"
        case .cushion: return "垫子"
        case .flower: return "花朵"
        }
    }

    var icon: String {
        switch self {
        case .ball: return "circle.fill"
        case .foodBowl: return "bowl.fill"
        case .toy: return "star.fill"
        case .cushion: return "square.fill"
        case .flower: return "camera.macro"
        }
    }

    var color: String {
        switch self {
        case .ball: return "#FF6B6B"
        case .foodBowl: return "#FFA500"
        case .toy: return "#FFD700"
        case .cushion: return "#9370DB"
        case .flower: return "#FF69B4"
        }
    }
}

// MARK: - Dog Pose

enum DogPose: String, Codable, CaseIterable {
    // 基础姿态
    case idle, happy, focused, waiting, resting

    // 庆祝姿态
    case jump, spin, dash, heart, roll, spark

    var isCelebration: Bool {
        switch self {
        case .jump, .spin, .dash, .heart, .roll, .spark: return true
        default: return false
        }
    }

    var scaleMultiplier: CGFloat {
        switch self {
        case .happy: return 1.04
        case .focused: return 0.98
        case .resting: return 0.95
        default: return 1.0
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .focused: return 0.03
        case .resting: return 0.05
        default: return 0.0
        }
    }
}

// MARK: - Dog Evolution System

enum DogEvolution: String, Codable, CaseIterable {
    case puppy      // 幼犬 (0-9 次)
    case adult      // 成犬 (10-49 次)
    case complete   // 完全体 (50-99 次)
    case legendary  // 传奇体 (100+ 次)

    var displayName: String {
        switch self {
        case .puppy: return "幼犬"
        case .adult: return "成犬"
        case .complete: return "完全体"
        case .legendary: return "传奇体"
        }
    }

    var scale: CGFloat {
        switch self {
        case .puppy: return 0.8
        case .adult: return 1.0
        case .complete: return 1.2
        case .legendary: return 1.2
        }
    }

    var requiredCheckIns: Int {
        switch self {
        case .puppy: return 0
        case .adult: return 10
        case .complete: return 50
        case .legendary: return 100
        }
    }

    var nextStage: DogEvolution? {
        switch self {
        case .puppy: return .adult
        case .adult: return .complete
        case .complete: return .legendary
        case .legendary: return nil
        }
    }

    var nextStageRequiredCheckIns: Int? {
        nextStage?.requiredCheckIns
    }

    static func from(totalCheckIns: Int) -> DogEvolution {
        switch totalCheckIns {
        case 0..<10: return .puppy
        case 10..<50: return .adult
        case 50..<100: return .complete
        default: return .legendary
        }
    }

    func progress(toNext totalCheckIns: Int) -> Double {
        guard let next = nextStage else { return 1.0 }
        let current = requiredCheckIns
        let target = next.requiredCheckIns
        let progress = Double(totalCheckIns - current) / Double(target - current)
        return min(max(progress, 0), 1.0)
    }
}

enum DogMood: String, Codable, CaseIterable {
    case sad        // 😢 失落
    case neutral    // 😐 平淡
    case happy      // 😊 开心
    case excited    // 😄 兴奋
    case ecstatic   // 🥳 超开心

    var emoji: String {
        switch self {
        case .sad: return "😢"
        case .neutral: return "😐"
        case .happy: return "😊"
        case .excited: return "😄"
        case .ecstatic: return "🥳"
        }
    }

    var displayName: String {
        switch self {
        case .sad: return "失落"
        case .neutral: return "平淡"
        case .happy: return "开心"
        case .excited: return "兴奋"
        case .ecstatic: return "超开心"
        }
    }

    static func from(recentCheckIns: Int, streak: Int) -> DogMood {
        // 基于最近 7 天完成数和连续打卡天数计算心情
        if streak >= 7 { return .ecstatic }
        if streak >= 3 || recentCheckIns >= 5 { return .excited }
        if recentCheckIns >= 3 { return .happy }
        if recentCheckIns >= 1 { return .neutral }
        return .sad
    }

    // MARK: - 心情对移动的影响因子
    var movementModifiers: (wanderMultiplier: Double, pauseMultiplier: Double, speedMultiplier: Double, jumpProbability: Double) {
        switch self {
        case .sad:
            return (wanderMultiplier: 0.3, pauseMultiplier: 2.0, speedMultiplier: 0.5, jumpProbability: 0.0)
        case .neutral:
            return (wanderMultiplier: 0.6, pauseMultiplier: 1.5, speedMultiplier: 0.7, jumpProbability: 0.05)
        case .happy:
            return (wanderMultiplier: 1.0, pauseMultiplier: 1.0, speedMultiplier: 1.0, jumpProbability: 0.1)
        case .excited:
            return (wanderMultiplier: 1.4, pauseMultiplier: 0.7, speedMultiplier: 1.3, jumpProbability: 0.2)
        case .ecstatic:
            return (wanderMultiplier: 1.8, pauseMultiplier: 0.5, speedMultiplier: 1.5, jumpProbability: 0.35)
        }
    }

    // MARK: - 心情驱动表情

    var eyeStyle: EyeStyle {
        switch self {
        case .sad: return .droopy
        case .neutral: return .normal
        case .happy: return .squint
        case .excited: return .sparkle
        case .ecstatic: return .heart
        }
    }

    var mouthStyle: MouthStyle {
        switch self {
        case .sad: return .downturn
        case .neutral: return .straight
        case .happy: return .slightSmile
        case .excited: return .wideSmile
        case .ecstatic: return .bigSmile
        }
    }

    // MARK: - 尾巴摇摆参数
    var tailWagAngle: Double {
        switch self {
        case .sad: return 5
        case .neutral: return 10
        case .happy: return 20
        case .excited: return 22
        case .ecstatic: return 25
        }
    }

    var tailWagDuration: Double {
        switch self {
        case .sad: return 2.0
        case .neutral: return 1.2
        case .happy: return 0.5
        case .excited: return 0.4
        case .ecstatic: return 0.3
        }
    }
}

// MARK: - 表情样式

enum EyeStyle {
    case normal, droopy, squint, sparkle, heart, halfClosed, closed
}

enum MouthStyle {
    case downturn, straight, slightSmile, wideSmile, bigSmile
}

struct DogDiaryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let content: String
    let mood: DogMood
    let completions: Int
    let focusMinutes: Int
    let streakDays: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String,
        mood: DogMood,
        completions: Int,
        focusMinutes: Int,
        streakDays: Int
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.mood = mood
        self.completions = completions
        self.focusMinutes = focusMinutes
        self.streakDays = streakDays
    }
}

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
    var pose: DogPose
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
        pose: DogPose,
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
        pose = try container.decodeIfPresent(DogPose.self, forKey: .pose) ?? .idle
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
        pose: .idle,
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
    var celebrationPose: DogPose
    var completedPlanTitle: String?

    enum CodingKeys: String, CodingKey {
        case message
        case gains
        case leveledUp
        case rewardItem
        case celebrationPose
        case completedPlanTitle
    }

    init(message: String, gains: [StateGain], leveledUp: Bool = false, rewardItem: PixelRewardItem? = nil, celebrationPose: DogPose = .jump, completedPlanTitle: String? = nil) {
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
        celebrationPose = try container.decodeIfPresent(DogPose.self, forKey: .celebrationPose) ?? .jump
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
    var isResting: Bool
    var restStartTime: Date?

    // 狗狗成长进化系统
    var dogEvolution: DogEvolution
    var dogMood: DogMood
    var diaryEntries: [DogDiaryEntry]
    var lastDiaryDate: Date?

    // 场景系统
    var sceneSettings: SceneSettings

    // 每日任务建议系统
    var customTasks: [CustomTask]
    var taskHistory: [TaskHistoryEntry]
    var lastTaskRecommendationDate: Date?

    // 习惯追踪日历系统
    var achievements: [Achievement]
    var monthlyReports: [MonthlyReport]

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
        case isResting
        case restStartTime
        case dogEvolution
        case dogMood
        case diaryEntries
        case lastDiaryDate
        case sceneSettings
        case customTasks
        case taskHistory
        case lastTaskRecommendationDate
        case achievements
        case monthlyReports
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
        focusStartTime: Date? = nil,
        isResting: Bool = false,
        restStartTime: Date? = nil,
        dogEvolution: DogEvolution = .puppy,
        dogMood: DogMood = .neutral,
        diaryEntries: [DogDiaryEntry] = [],
        lastDiaryDate: Date? = nil,
        sceneSettings: SceneSettings = .default,
        customTasks: [CustomTask] = [],
        taskHistory: [TaskHistoryEntry] = [],
        lastTaskRecommendationDate: Date? = nil,
        achievements: [Achievement] = [],
        monthlyReports: [MonthlyReport] = []
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
        self.isResting = isResting
        self.restStartTime = restStartTime
        self.dogEvolution = dogEvolution
        self.dogMood = dogMood
        self.diaryEntries = diaryEntries
        self.lastDiaryDate = lastDiaryDate
        self.sceneSettings = sceneSettings
        self.customTasks = customTasks
        self.taskHistory = taskHistory
        self.lastTaskRecommendationDate = lastTaskRecommendationDate
        self.achievements = achievements
        self.monthlyReports = monthlyReports
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
        isResting = try container.decodeIfPresent(Bool.self, forKey: .isResting) ?? false
        restStartTime = try container.decodeIfPresent(Date.self, forKey: .restStartTime)

        // 狗狗成长进化系统字段（向后兼容）
        dogEvolution = try container.decodeIfPresent(DogEvolution.self, forKey: .dogEvolution) ?? .puppy
        dogMood = try container.decodeIfPresent(DogMood.self, forKey: .dogMood) ?? .neutral
        diaryEntries = try container.decodeIfPresent([DogDiaryEntry].self, forKey: .diaryEntries) ?? []
        lastDiaryDate = try container.decodeIfPresent(Date.self, forKey: .lastDiaryDate)

        // 场景系统字段（向后兼容）
        sceneSettings = try container.decodeIfPresent(SceneSettings.self, forKey: .sceneSettings) ?? .default

        // 每日任务建议系统字段（向后兼容）
        customTasks = try container.decodeIfPresent([CustomTask].self, forKey: .customTasks) ?? []
        taskHistory = try container.decodeIfPresent([TaskHistoryEntry].self, forKey: .taskHistory) ?? []
        lastTaskRecommendationDate = try container.decodeIfPresent(Date.self, forKey: .lastTaskRecommendationDate)

        // 习惯追踪日历系统字段（向后兼容）
        achievements = try container.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        monthlyReports = try container.decodeIfPresent([MonthlyReport].self, forKey: .monthlyReports) ?? []
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

// MARK: - 每日任务建议系统

/// 任务时间段
enum TaskTimeSlot: String, Codable, CaseIterable {
    case morning      // 早上 6-12
    case afternoon    // 下午 12-18
    case evening      // 晚上 18-22
    case night        // 深夜 22-6

    /// 根据当前小时判断时间段
    static var current: TaskTimeSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }

    var label: String {
        switch self {
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        case .night: return "深夜"
        }
    }

    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌆"
        case .night: return "🌙"
        }
    }
}

/// 预设任务模板
struct TaskTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let goalType: GoalType
    let estimatedMinutes: Int
    let timeSlots: [TaskTimeSlot]  // 适合的时间段
    let tags: [String]

    init(id: String = UUID().uuidString, title: String, goalType: GoalType, estimatedMinutes: Int, timeSlots: [TaskTimeSlot] = TaskTimeSlot.allCases, tags: [String] = []) {
        self.id = id
        self.title = title
        self.goalType = goalType
        self.estimatedMinutes = estimatedMinutes
        self.timeSlots = timeSlots
        self.tags = tags
    }
}

/// 用户自定义任务
struct CustomTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var goalType: GoalType
    var estimatedMinutes: Int
    var isFavorite: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, goalType: GoalType, estimatedMinutes: Int, isFavorite: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.goalType = goalType
        self.estimatedMinutes = estimatedMinutes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

/// 任务历史记录
struct TaskHistoryEntry: Codable, Identifiable {
    let id: UUID
    let title: String
    let goalType: GoalType
    let acceptedDate: Date
    var completed: Bool
    var completedDate: Date?

    init(id: UUID = UUID(), title: String, goalType: GoalType, acceptedDate: Date = Date(), completed: Bool = false, completedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.goalType = goalType
        self.acceptedDate = acceptedDate
        self.completed = completed
        self.completedDate = completedDate
    }
}

/// 预设任务库
struct PresetTaskLibrary {
    /// 健身类任务
    static let fitnessTasks: [TaskTemplate] = [
        TaskTemplate(title: "晨跑 20 分钟", goalType: .fitness, estimatedMinutes: 20, timeSlots: [.morning], tags: ["有氧", "户外"]),
        TaskTemplate(title: "俯卧撑 3 组 × 15 个", goalType: .fitness, estimatedMinutes: 10, timeSlots: [.morning, .afternoon], tags: ["力量", "上肢"]),
        TaskTemplate(title: "拉伸放松 10 分钟", goalType: .fitness, estimatedMinutes: 10, timeSlots: [.evening, .night], tags: ["柔韧", "恢复"]),
        TaskTemplate(title: "深蹲 3 组 × 12 个", goalType: .fitness, estimatedMinutes: 12, timeSlots: [.afternoon, .evening], tags: ["力量", "下肢"]),
        TaskTemplate(title: "平板支撑 3 分钟", goalType: .fitness, estimatedMinutes: 5, timeSlots: [.morning, .afternoon], tags: ["核心", "耐力"]),
        TaskTemplate(title: "散步 30 分钟", goalType: .fitness, estimatedMinutes: 30, timeSlots: [.evening], tags: ["有氧", "放松"]),
        TaskTemplate(title: "跳绳 15 分钟", goalType: .fitness, estimatedMinutes: 15, timeSlots: [.morning, .afternoon], tags: ["有氧", "协调"]),
        TaskTemplate(title: "瑜伽 20 分钟", goalType: .fitness, estimatedMinutes: 20, timeSlots: [.morning, .evening], tags: ["柔韧", "身心"]),
        TaskTemplate(title: "开合跳 5 分钟", goalType: .fitness, estimatedMinutes: 5, timeSlots: [.morning], tags: ["热身", "有氧"]),
        TaskTemplate(title: "引体向上 3 组 × 8 个", goalType: .fitness, estimatedMinutes: 10, timeSlots: [.afternoon], tags: ["力量", "上肢"]),
    ]

    /// 学习类任务
    static let studyTasks: [TaskTemplate] = [
        TaskTemplate(title: "背单词 20 个", goalType: .study, estimatedMinutes: 15, timeSlots: [.morning], tags: ["英语", "记忆"]),
        TaskTemplate(title: "阅读 30 分钟", goalType: .study, estimatedMinutes: 30, timeSlots: [.afternoon, .evening], tags: ["阅读", "积累"]),
        TaskTemplate(title: "写日记", goalType: .study, estimatedMinutes: 10, timeSlots: [.evening, .night], tags: ["写作", "反思"]),
        TaskTemplate(title: "复习笔记 20 分钟", goalType: .study, estimatedMinutes: 20, timeSlots: [.afternoon], tags: ["复习", "巩固"]),
        TaskTemplate(title: "学习新知识点", goalType: .study, estimatedMinutes: 25, timeSlots: [.morning, .afternoon], tags: ["学习", "探索"]),
        TaskTemplate(title: "做练习题 30 分钟", goalType: .study, estimatedMinutes: 30, timeSlots: [.afternoon, .evening], tags: ["练习", "应用"]),
        TaskTemplate(title: "听播客/课程 20 分钟", goalType: .study, estimatedMinutes: 20, timeSlots: [.morning, .evening], tags: ["听力", "输入"]),
        TaskTemplate(title: "整理思维导图", goalType: .study, estimatedMinutes: 15, timeSlots: [.evening], tags: ["整理", "归纳"]),
        TaskTemplate(title: "阅读专业文章", goalType: .study, estimatedMinutes: 20, timeSlots: [.morning, .afternoon], tags: ["专业", "深度"]),
        TaskTemplate(title: "写学习计划", goalType: .study, estimatedMinutes: 10, timeSlots: [.evening, .night], tags: ["规划", "目标"]),
    ]

    /// 作息类任务
    static let sleepTasks: [TaskTemplate] = [
        TaskTemplate(title: "23:00 前上床", goalType: .sleep, estimatedMinutes: 5, timeSlots: [.night], tags: ["早睡", "规律"]),
        TaskTemplate(title: "睡前放下手机 10 分钟", goalType: .sleep, estimatedMinutes: 10, timeSlots: [.night], tags: ["戒手机", "放松"]),
        TaskTemplate(title: "整理明天计划", goalType: .sleep, estimatedMinutes: 5, timeSlots: [.night], tags: ["规划", "安心"]),
        TaskTemplate(title: "冥想 10 分钟", goalType: .sleep, estimatedMinutes: 10, timeSlots: [.evening, .night], tags: ["冥想", "静心"]),
        TaskTemplate(title: "喝杯温水放松", goalType: .sleep, estimatedMinutes: 5, timeSlots: [.evening, .night], tags: ["放松", "健康"]),
        TaskTemplate(title: "睡前拉伸 5 分钟", goalType: .sleep, estimatedMinutes: 5, timeSlots: [.night], tags: ["拉伸", "放松"]),
        TaskTemplate(title: "写感恩日记", goalType: .sleep, estimatedMinutes: 5, timeSlots: [.night], tags: ["反思", "正面"]),
        TaskTemplate(title: "调暗灯光准备入睡", goalType: .sleep, estimatedMinutes: 3, timeSlots: [.night], tags: ["环境", "入睡"]),
    ]

    /// 根据目标类型获取对应任务库
    static func tasks(for goalType: GoalType) -> [TaskTemplate] {
        switch goalType {
        case .fitness: return fitnessTasks
        case .study: return studyTasks
        case .sleep: return sleepTasks
        }
    }

    /// 所有预设任务
    static var allTasks: [TaskTemplate] {
        fitnessTasks + studyTasks + sleepTasks
    }
}

// MARK: - Habit Tracking Calendar

/// 打卡类型
enum CheckInType: String, Codable {
    case mainCheckIn      // 主打卡
    case focusSession     // 专注
    case taskCompletion   // 任务完成
}

/// 打卡记录（用于日历聚合）
struct CheckInRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: CheckInType
    let goalType: GoalType?
    let duration: Int?  // 时长（分钟）

    init(id: UUID = UUID(), date: Date, type: CheckInType, goalType: GoalType? = nil, duration: Int? = nil) {
        self.id = id
        self.date = date
        self.type = type
        self.goalType = goalType
        self.duration = duration
    }
}

/// 成就类型
enum AchievementType: String, Codable, CaseIterable {
    case streak7 = "7天连续"
    case streak30 = "30天连续"
    case streak100 = "100天连续"
    case streak365 = "365天连续"
    case monthlyPerfect = "完美月份"
    case firstFocus = "首次专注"
    case focusMaster = "专注达人"
    case taskChampion = "任务冠军"

    var title: String {
        switch self {
        case .streak7: return "一周坚持"
        case .streak30: return "月度达人"
        case .streak100: return "百日挑战"
        case .streak365: return "年度传奇"
        case .monthlyPerfect: return "完美月份"
        case .firstFocus: return "初次专注"
        case .focusMaster: return "专注大师"
        case .taskChampion: return "任务王者"
        }
    }

    var description: String {
        switch self {
        case .streak7: return "连续打卡 7 天"
        case .streak30: return "连续打卡 30 天"
        case .streak100: return "连续打卡 100 天"
        case .streak365: return "连续打卡 365 天"
        case .monthlyPerfect: return "单月 100% 完成率"
        case .firstFocus: return "完成首次专注"
        case .focusMaster: return "累计专注 100 小时"
        case .taskChampion: return "完成 50 个任务"
        }
    }

    var icon: String {
        switch self {
        case .streak7: return "flame.fill"
        case .streak30: return "star.fill"
        case .streak100: return "trophy.fill"
        case .streak365: return "crown.fill"
        case .monthlyPerfect: return "checkmark.seal.fill"
        case .firstFocus: return "timer"
        case .focusMaster: return "brain.head.profile"
        case .taskChampion: return "list.bullet.clipboard.fill"
        }
    }

    var threshold: Int {
        switch self {
        case .streak7: return 7
        case .streak30: return 30
        case .streak100: return 100
        case .streak365: return 365
        case .monthlyPerfect: return 100  // 100% 完成率
        case .firstFocus: return 1
        case .focusMaster: return 6000  // 100小时 = 6000分钟
        case .taskChampion: return 50
        }
    }
}

/// 成就徽章
struct Achievement: Codable, Identifiable {
    let id: UUID
    let type: AchievementType
    let earnedDate: Date

    init(id: UUID = UUID(), type: AchievementType, earnedDate: Date = Date()) {
        self.id = id
        self.type = type
        self.earnedDate = earnedDate
    }
}

/// 月度报告
struct MonthlyReport: Codable, Identifiable {
    let id: UUID
    let month: Date
    let totalCheckIns: Int
    let completionRate: Double
    let longestStreak: Int
    let totalFocusMinutes: Int
    let topGoalType: GoalType?

    init(id: UUID = UUID(), month: Date, totalCheckIns: Int, completionRate: Double, longestStreak: Int, totalFocusMinutes: Int, topGoalType: GoalType? = nil) {
        self.id = id
        self.month = month
        self.totalCheckIns = totalCheckIns
        self.completionRate = completionRate
        self.longestStreak = longestStreak
        self.totalFocusMinutes = totalFocusMinutes
        self.topGoalType = topGoalType
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
