import SwiftUI

struct DogWorldScene: View {
    @EnvironmentObject private var store: AppStore
    @State private var showsDogStatus = false
    @State private var activityIndex = 0
    @State private var wanderOffset = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let dogSize = min(width * 0.11, height * 0.15)
            let dogPosition = dogMapPosition(width: width, height: height)
                .applying(offset: wanderOffset)

            ZStack {
                PixelYardMap(goalType: activeGoalType, isRecovery: isRecovery, isDone: isIdleCompleted)

                PixelMapLabel(text: propLabel)
                    .position(propLabelPosition(width: width, height: height))

                Button {
                    showsDogStatus = true
                    store.speechMode = "tap"
                } label: {
                    ZStack {
                        if showsDogStatus {
                            PixelRect(color: Color(hex: 0xFFF1B8, alpha: 0.75))
                                .frame(width: dogSize * 1.28, height: dogSize * 0.52)
                                .offset(y: dogSize * 0.35)
                        }

                        PixelDogSprite(
                            breed: store.state.selectedDog,
                            appearance: store.currentDogAppearance(),
                            size: dogSize,
                            pose: store.state.dogState.pose
                        )

                        // Companion dog
                        if let companionId = store.state.activeCompanionId,
                           let companion = store.state.dogCollection.dog(with: companionId) {
                            PixelDogSprite(
                                breed: companion.breed,
                                appearance: companion.appearance,
                                size: dogSize * 0.85,
                                pose: store.state.dogState.pose
                            )
                            .offset(x: dogSize * 0.9, y: dogSize * 0.1)
                        }

                        PixelDogActivityCue(
                            goalType: activeGoalType,
                            isRecovery: isRecovery,
                            isDone: isIdleCompleted,
                            isRunning: store.state.actionSession.phase == .running,
                            activityIndex: activityIndex
                        )
                        .frame(width: max(20, dogSize * 0.56), height: max(20, dogSize * 0.56))
                        .offset(x: dogSize * 0.48, y: dogSize * -0.38)
                    }
                    .frame(width: dogSize * 1.5, height: dogSize * 1.5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(dogPosition)

                if showsDogStatus {
                    DogStatusTray(
                        breed: store.state.selectedDog,
                        appearance: store.currentDogAppearance(),
                        dogState: store.state.dogState,
                        speech: store.speechText(),
                        nextLevelNeed: store.nextLevelNeed(),
                        onClose: { showsDogStatus = false }
                    )
                    .padding(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .position(x: width / 2, y: height - min(36, height * 0.11))
                }

                if store.state.actionSession.phase == .running {
                    PixelDogCountdownBadge(
                        plan: store.state.actionSession.plan,
                        remainingSeconds: store.state.actionSession.remainingSeconds
                    )
                    .position(x: width * 0.73, y: height * 0.15)
                }
            }
            .background(Color(hex: 0xDCEBCB))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: 0x7C9B64), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
            .onTapGesture {
                showsDogStatus = false
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showsDogStatus)
            .animation(.easeInOut(duration: 1.2), value: wanderOffset)
            .animation(.easeInOut(duration: 0.35), value: activityIndex)
            .task(id: dogWorldTaskID) {
                await runDogWorldLoop(width: width, height: height)
            }
        }
        .aspectRatio(0.83, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var isRecovery: Bool {
        store.state.rhythmState.status == .missed || store.state.rhythmState.status == .longBreak
    }

    private var isIdleCompleted: Bool {
        store.state.actionSession.phase == .idle && store.hasMainCheckInToday()
    }

    private var activeGoalType: GoalType? {
        store.state.actionSession.plan?.rewardGoalType ?? store.state.goal?.type
    }

    private var dogWorldTaskID: String {
        "\(activeGoalType?.rawValue ?? "none")-\(store.state.actionSession.phase.rawValue)"
    }

    private func dogMapPosition(width: CGFloat, height: CGFloat) -> CGPoint {
        if isRecovery { return CGPoint(x: width * 0.30, y: height * 0.25) }
        if isIdleCompleted { return CGPoint(x: width * 0.78, y: height * 0.28) }

        switch activeGoalType {
        case .fitness:
            return CGPoint(x: width * 0.28, y: height * 0.68)
        case .study:
            return CGPoint(x: width * 0.66, y: height * 0.40)
        case .sleep:
            return CGPoint(x: width * 0.68, y: height * 0.70)
        case .none:
            return CGPoint(x: width * 0.50, y: height * 0.48)
        }
    }

    @MainActor
    private func runDogWorldLoop(width: CGFloat, height: CGFloat) async {
        while !Task.isCancelled {
            let maxX = width * 0.05
            let maxY = height * 0.04
            activityIndex = Int.random(in: 0...2)

            if isRecovery || isIdleCompleted {
                wanderOffset = CGSize(width: CGFloat.random(in: -maxX * 0.3...maxX * 0.3), height: CGFloat.random(in: -maxY * 0.3...maxY * 0.3))
            } else {
                wanderOffset = CGSize(width: CGFloat.random(in: -maxX...maxX), height: CGFloat.random(in: -maxY...maxY))
            }

            try? await Task.sleep(nanoseconds: 3_200_000_000)
        }
    }

    private var propLabel: String {
        if store.state.rhythmState.status == .missed || store.state.rhythmState.status == .longBreak { return "恢复小路" }
        switch activeGoalType {
        case .fitness: return "运动区"
        case .study: return "学习角"
        case .sleep: return "休闲窝"
        case .none: return "狗狗小院"
        }
    }

    private func propLabelPosition(width: CGFloat, height: CGFloat) -> CGPoint {
        if isRecovery { return CGPoint(x: width * 0.28, y: height * 0.20) }

        switch activeGoalType {
        case .fitness:
            return CGPoint(x: width * 0.22, y: height * 0.57)
        case .study:
            return CGPoint(x: width * 0.66, y: height * 0.28)
        case .sleep:
            return CGPoint(x: width * 0.78, y: height * 0.34)
        case .none:
            return CGPoint(x: width * 0.20, y: height * 0.14)
        }
    }
}

struct PixelYardMap: View {
    let goalType: GoalType?
    let isRecovery: Bool
    let isDone: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                PixelGridBackground()

                PixelRect(color: Color(hex: 0x7FB46C))
                    .frame(width: width * 0.88, height: height * 0.74)
                    .position(x: width * 0.52, y: height * 0.50)

                PixelRect(color: Color(hex: 0xA9C98A))
                    .frame(width: width * 0.78, height: height * 0.62)
                    .position(x: width * 0.52, y: height * 0.50)

                PixelRect(color: Color(hex: 0x95BE77, alpha: 0.75))
                    .frame(width: width * 0.28, height: height * 0.22)
                    .position(x: width * 0.70, y: height * 0.60)

                PixelPath()
                    .stroke(Color(hex: 0xD8C7A4), style: StrokeStyle(lineWidth: max(10, width * 0.028), lineCap: .square, lineJoin: .miter))
                    .frame(width: width, height: height)

                PixelDetailDots()
                    .frame(width: width, height: height)

                PixelFence()
                    .stroke(Color(hex: 0x8D6D46), style: StrokeStyle(lineWidth: 4, lineCap: .square, lineJoin: .miter))
                    .padding(8)

                PixelDogHouse()
                    .frame(width: width * 0.11, height: height * 0.13)
                    .position(x: width * 0.83, y: height * 0.22)

                PixelGate()
                    .frame(width: width * 0.11, height: height * 0.07)
                    .position(x: width * 0.20, y: height * 0.14)

                PixelProps(goalType: goalType, isRecovery: isRecovery, isDone: isDone)
                    .frame(width: width * 0.13, height: height * 0.13)
                    .position(propPosition(width: width, height: height))

                if isRecovery {
                    PixelFootprints()
                        .frame(width: width * 0.13, height: height * 0.16)
                        .position(x: width * 0.35, y: height * 0.32)
                }
            }
            .overlay {
                if isRecovery {
                    Color(hex: 0x6F7D78, alpha: 0.12)
                } else if isDone {
                    Color(hex: 0xF7C95C, alpha: 0.10)
                }
            }
        }
    }

    private func propPosition(width: CGFloat, height: CGFloat) -> CGPoint {
        if isRecovery { return CGPoint(x: width * 0.28, y: height * 0.28) }

        switch goalType {
        case .fitness:
            return CGPoint(x: width * 0.23, y: height * 0.67)
        case .study:
            return CGPoint(x: width * 0.69, y: height * 0.39)
        case .sleep:
            return CGPoint(x: width * 0.69, y: height * 0.69)
        case .none:
            return CGPoint(x: width * 0.50, y: height * 0.52)
        }
    }
}

struct PixelGridBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let tile = max(18, proxy.size.width / 15)
            let columns = Int(ceil(proxy.size.width / tile))
            let rows = Int(ceil(proxy.size.height / tile))

            ZStack(alignment: .topLeading) {
                Color(hex: 0xCFE4B5)
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        Rectangle()
                            .fill((row + column).isMultiple(of: 2) ? Color(hex: 0xD8EBC1) : Color(hex: 0xC6DBA9))
                            .frame(width: tile, height: tile)
                            .position(x: CGFloat(column) * tile + tile / 2, y: CGFloat(row) * tile + tile / 2)
                    }
                }
            }
        }
    }
}

struct PixelPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.width * 0.52, y: rect.height * 0.50))
        path.addLine(to: CGPoint(x: rect.width * 0.76, y: rect.height * 0.74))
        return path
    }
}

struct PixelDetailDots: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    PixelRect(color: detailColor(index))
                        .frame(width: detailSize(index), height: detailSize(index))
                        .position(x: width * x(index), y: height * y(index))
                }
            }
            .opacity(0.72)
        }
    }

    private func detailColor(_ index: Int) -> Color {
        [Color(hex: 0xF2D06B), Color(hex: 0x7BAF67), Color(hex: 0xB6D38A), Color(hex: 0xDFA06D)][index % 4]
    }

    private func detailSize(_ index: Int) -> CGFloat {
        [4, 5, 6, 4, 7][index % 5]
    }

    private func x(_ index: Int) -> CGFloat {
        [0.14, 0.31, 0.46, 0.68, 0.84, 0.22, 0.57, 0.73, 0.38][index % 9]
    }

    private func y(_ index: Int) -> CGFloat {
        [0.28, 0.22, 0.34, 0.20, 0.46, 0.76, 0.73, 0.62, 0.66][index % 9]
    }
}

struct PixelFence: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}

struct PixelDogHouse: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                PixelRect(color: Color(hex: 0xB77B49))
                    .frame(width: width * 0.78, height: height * 0.58)
                    .position(x: width * 0.50, y: height * 0.62)

                PixelRect(color: Color(hex: 0x7E4E31))
                    .frame(width: width * 0.92, height: height * 0.22)
                    .position(x: width * 0.50, y: height * 0.32)

                PixelRect(color: Color(hex: 0x4B3327))
                    .frame(width: width * 0.26, height: height * 0.32)
                    .position(x: width * 0.50, y: height * 0.70)
            }
        }
    }
}

struct PixelGate: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                PixelRect(color: Color(hex: 0x8D6D46))
                    .frame(width: 8)
            }
        }
        .background(PixelRect(color: Color(hex: 0xB88B55)).frame(height: 10))
    }
}

struct PixelProps: View {
    let goalType: GoalType?
    let isRecovery: Bool
    let isDone: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                if isRecovery {
                    PixelRect(color: Color(hex: 0xE8D9BC))
                        .frame(width: width * 0.52, height: height * 0.30)
                        .position(x: width * 0.50, y: height * 0.62)
                    PixelFootprints()
                        .frame(width: width * 0.58, height: height * 0.50)
                        .position(x: width * 0.58, y: height * 0.35)
                } else {
                    switch goalType {
                    case .fitness:
                        PixelRect(color: Color(hex: 0x6C91C2))
                            .frame(width: width * 0.76, height: height * 0.34)
                            .position(x: width * 0.50, y: height * 0.62)
                        Circle()
                            .fill(isDone ? Color(hex: 0xF7C95C) : Color(hex: 0xC65B44))
                            .frame(width: width * 0.26, height: width * 0.26)
                            .position(x: width * 0.24, y: height * 0.30)
                    case .study:
                        PixelRect(color: Color(hex: 0xB77B49))
                            .frame(width: width * 0.66, height: height * 0.18)
                            .position(x: width * 0.54, y: height * 0.52)
                        PixelRect(color: Color(hex: 0xF4E8C7))
                            .frame(width: width * 0.42, height: height * 0.22)
                            .position(x: width * 0.44, y: height * 0.36)
                    case .sleep:
                        PixelRect(color: Color(hex: 0x7F93BC))
                            .frame(width: width * 0.66, height: height * 0.38)
                            .position(x: width * 0.52, y: height * 0.56)
                        PixelRect(color: Color(hex: 0xF2DFA8))
                            .frame(width: width * 0.30, height: height * 0.18)
                            .position(x: width * 0.34, y: height * 0.40)
                    case .none:
                        PixelRect(color: Color(hex: 0xD6B47E))
                            .frame(width: width * 0.38, height: height * 0.32)
                            .position(x: width * 0.48, y: height * 0.54)
                    }
                }
            }
        }
    }
}

struct PixelDogActivityCue: View {
    let goalType: GoalType?
    let isRecovery: Bool
    let isDone: Bool
    let isRunning: Bool
    let activityIndex: Int

    var body: some View {
        ZStack {
            PixelRect(color: background)
            Image(systemName: symbolName)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(foreground)

            if showsMotionMark {
                PixelRect(color: foreground.opacity(0.45))
                    .frame(width: 4, height: 2)
                    .offset(x: -9, y: -6)
                PixelRect(color: foreground.opacity(0.35))
                    .frame(width: 6, height: 2)
                    .offset(x: -8, y: 7)
            }
        }
        .overlay {
            Rectangle()
                .stroke(border, lineWidth: 1)
        }
    }

    private var symbolName: String {
        let idx = activityIndex % 3
        if isRecovery { return ["leaf.fill", "shoeprints.fill", "sunrise.fill"][idx] }
        if isDone { return ["heart.fill", "zzz", "star.fill"][idx] }

        switch goalType {
        case .fitness: return ["figure.run", "dumbbell.fill", "flame.fill"][idx]
        case .study: return ["book.fill", "pencil", "lightbulb.fill"][idx]
        case .sleep: return ["moon.fill", "play.rectangle.fill", "cloud.fill"][idx]
        case .none: return ["pawprint.fill", "music.note", "leaf.fill"][idx]
        }
    }

    private var showsMotionMark: Bool {
        isRunning && !isDone && !isRecovery && goalType == .fitness && activityIndex % 3 == 0
    }

    private var background: Color {
        if isDone { return Color(hex: 0xF7D66F) }
        if isRecovery { return Color(hex: 0xE8D9BC) }
        return Color(hex: 0xFFF8E8)
    }

    private var foreground: Color {
        if isDone { return Color(hex: 0x6E4F15) }
        if isRecovery { return Color(hex: 0x6D6557) }
        return Color(hex: 0x356247)
    }

    private var border: Color {
        if isDone { return Color(hex: 0xC69A3E) }
        if isRecovery { return Color(hex: 0xB8A98F) }
        return Color(hex: 0x7C9B64)
    }
}

struct PixelDogCountdownBadge: View {
    let plan: ActionPlan?
    let remainingSeconds: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(plan?.activeLabel ?? "行动中")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
            Text(formattedTime)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
        }
        .foregroundStyle(Color(hex: 0x26382B))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            ZStack {
                PixelRect(color: Color(hex: 0xFFF1B8, alpha: 0.96))
                PixelTinyGrid(colorA: Color(hex: 0xFFE7A5, alpha: 0.42), colorB: Color.clear, tile: 7)
            }
        }
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0xC69A3E), lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x4B3327, alpha: 0.14), radius: 0, x: 3, y: 3)
    }

    private var formattedTime: String {
        let minutes = max(0, remainingSeconds) / 60
        let seconds = max(0, remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PixelFootprints: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    PixelRect(color: Color(hex: 0x8B7D68, alpha: 0.45))
                        .frame(width: width * 0.16, height: height * 0.10)
                        .position(
                            x: width * (0.22 + Double(index) * 0.18),
                            y: height * (0.24 + Double(index % 2) * 0.22)
                        )
                }
            }
        }
    }
}

struct DogStatusTray: View {
    let breed: DogBreed
    let appearance: DogAppearance
    let dogState: DogState
    let speech: String
    let nextLevelNeed: Int
    var onClose: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                PixelDogSprite(breed: breed, appearance: appearance, size: 44, pose: dogState.pose)
                    .frame(width: 50, height: 46)
                    .background(Color(hex: 0xEAF1DA))
                    .overlay {
                        Rectangle()
                            .stroke(Color(hex: 0x7C9B64), lineWidth: 2)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("\(breed.name)")
                            .font(.caption.weight(.heavy))
                            .lineLimit(1)
                        Text(moodLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: 0x356247))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0xDDEBCB))
                        Text("Lv.\(dogState.level)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x5D6B55))
                    }

                    Text(speech)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x7C9B64))
                            .frame(width: 22, height: 22)
                            .background(Color(hex: 0xEAF1DA))
                            .overlay {
                                Rectangle().stroke(Color(hex: 0x7C9B64), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 6) {
                PixelStatBar(icon: "fork.knife", label: "饱", value: dogState.fullness, max: 100, color: Color(hex: 0xC65B44))
                PixelStatBar(icon: "drop.fill", label: "洁", value: dogState.cleanliness, max: 100, color: Color(hex: 0x4C7FA6))
                PixelStatBar(icon: "bolt.fill", label: "力", value: dogState.energy, max: 100, color: Color(hex: 0xC69A3E))
            }

            HStack(spacing: 4) {
                Text("亲密度")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: 0x5D6B55))
                PixelProgressBar(value: dogState.intimacy, max: nextLevelNeed, height: 6, fillColor: Color(hex: 0x5D8B6A))
                Text("\(dogState.intimacy)/\(nextLevelNeed)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: 0x5D6B55))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xFFF8E8, alpha: 0.96))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x7C9B64), lineWidth: 2)
        }
    }

    private var moodLabel: String {
        switch dogState.mood {
        case "happy": return "开心"
        case "focused": return "专注"
        case "waiting": return "等待"
        case "recovering": return "恢复"
        default: return "期待"
        }
    }
}

struct PixelStatBar: View {
    let icon: String
    let label: String
    let value: Int
    let max: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(color)
            PixelProgressBar(value: value, max: max, height: 5, fillColor: color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PixelProgressBar: View {
    let value: Int
    let max: Int
    let height: CGFloat
    let fillColor: Color

    var body: some View {
        let ratio = max > 0 ? min(CGFloat(value) / CGFloat(max), 1.0) : 0

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                PixelRect(color: Color(hex: 0xE8E0D0))
                PixelRect(color: fillColor)
                    .frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: height)
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x7C9B64), lineWidth: 1)
        }
    }
}

struct PixelCelebrationPanel: View {
    let breed: DogBreed
    let appearance: DogAppearance
    let feedback: FeedbackState?
    let dogLevel: Int
    let intimacy: Int
    let moodScore: Int
    let isAnimating: Bool

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text("Dog done!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x26382B))
                Text(feedback?.message ?? "今天的节奏接住了。")
                    .font(.headline.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: 0x356247))
            }

            ZStack {
                PixelGridBackground()
                    .opacity(0.72)

                PixelCelebrationBurst()

                PixelDogSprite(breed: breed, appearance: appearance, size: 128, pose: "happy")
                    .scaleEffect(isAnimating ? celebrationScale : 1)
                    .rotationEffect(.degrees(isAnimating ? celebrationRotation : -celebrationRotation))
                    .offset(x: isAnimating ? celebrationX : -celebrationX, y: isAnimating ? celebrationY : 0)
            }
            .frame(height: 178)
            .background(Color(hex: 0xEAF1DA))
            .overlay {
                Rectangle()
                    .stroke(Color(hex: 0x7C9B64), lineWidth: 3)
            }

            VStack(spacing: 8) {
                ForEach(feedback?.gains ?? []) { gain in
                    PixelGainRow(gain: gain)
                }
            }

            HStack(spacing: 10) {
                PixelMeter(label: "亲密度", value: intimacy, maxValue: 10)
                PixelMeter(label: "心情", value: moodScore, maxValue: 10)
            }

            if feedback?.leveledUp == true {
                PixelLevelUpReward(level: dogLevel, item: feedback?.rewardItem)
            }
        }
        .padding(14)
        .background(Color(hex: 0xFFF8E8))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x7C9B64), lineWidth: 3)
        }
        .shadow(color: .black.opacity(0.10), radius: 16, y: 10)
    }

    private var celebrationScale: CGFloat {
        switch feedback?.celebrationPose {
        case "roll": return 1.06
        case "heart": return 1.08
        default: return 1.12
        }
    }

    private var celebrationRotation: Double {
        switch feedback?.celebrationPose {
        case "spin": return 6
        case "roll": return 10
        case "dash": return -4
        default: return 3
        }
    }

    private var celebrationX: CGFloat {
        feedback?.celebrationPose == "dash" ? 16 : 0
    }

    private var celebrationY: CGFloat {
        switch feedback?.celebrationPose {
        case "jump": return -12
        case "spark": return -8
        default: return -6
        }
    }
}

struct PixelCelebrationBurst: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    PixelRect(color: burstColor(index))
                        .frame(width: burstSize(index), height: burstSize(index))
                        .position(x: width * burstX(index), y: height * burstY(index))
                }
            }
        }
    }

    private func burstColor(_ index: Int) -> Color {
        [Color(hex: 0xF2C94C), Color(hex: 0xC65B44), Color(hex: 0x4C7FA6), Color(hex: 0x7C9B64)][index % 4]
    }

    private func burstSize(_ index: Int) -> CGFloat {
        [6, 4, 8, 5][index % 4]
    }

    private func burstX(_ index: Int) -> CGFloat {
        [0.16, 0.25, 0.38, 0.56, 0.72, 0.84, 0.18, 0.32, 0.66, 0.78, 0.46, 0.58][index]
    }

    private func burstY(_ index: Int) -> CGFloat {
        [0.28, 0.66, 0.22, 0.18, 0.30, 0.62, 0.46, 0.80, 0.76, 0.44, 0.68, 0.52][index]
    }
}

struct PixelGainRow: View {
    let gain: StateGain

    var body: some View {
        HStack {
            Text(gain.label)
                .font(.subheadline.weight(.heavy))
            Spacer()
            Text("+\(gain.amount)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color(hex: 0x356247))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: 0xF6E9C8))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0xC7A76D), lineWidth: 2)
        }
    }
}

struct PixelMeter: View {
    let label: String
    let value: Int
    let maxValue: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color(hex: 0x356247))
                Spacer()
                Text("\(value)/\(maxValue)")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 3) {
                ForEach(0..<maxValue, id: \.self) { index in
                    PixelRect(color: index < value ? Color(hex: 0x5D8B6A) : Color(hex: 0xD9CFB9))
                        .frame(height: 10)
                        .overlay {
                            Rectangle()
                                .stroke(index < value ? Color(hex: 0x356247) : Color(hex: 0xBCA98B), lineWidth: 1)
                        }
                }
            }
        }
        .padding(8)
        .background(Color(hex: 0xEAF1DA))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x9BB985), lineWidth: 1)
        }
    }
}

struct PixelLevelUpReward: View {
    let level: Int
    let item: PixelRewardItem?

    var body: some View {
        HStack(spacing: 10) {
            PixelRewardItemIcon(item: item ?? .redBall)

            VStack(alignment: .leading, spacing: 3) {
                Text("Lv.\(level) 升级奖励")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color(hex: 0x6A4B14))
                Text(item?.label ?? "神秘像素道具")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(hex: 0x26382B))
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: 0xFFF1B8))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0xC69A3E), lineWidth: 2)
        }
    }
}

struct PixelRewardItemIcon: View {
    let item: PixelRewardItem

    var body: some View {
        ZStack {
            PixelRect(color: Color(hex: item.colorHex))
            Image(systemName: item.symbolName)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color(hex: 0xFFF8E8))
        }
        .frame(width: 42, height: 42)
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x6A4B14), lineWidth: 2)
        }
    }
}

struct PixelDogSprite: View {
    let breed: DogBreed
    let appearance: DogAppearance
    let size: CGFloat
    let pose: String

    var body: some View {
        ZStack {
            PixelRect(color: Color(hex: shadowColor, alpha: 0.26))
                .frame(width: size * 0.78, height: size * 0.16)
                .offset(y: size * 0.33)

            PixelRect(color: Color(hex: appearance.bodyColorHex))
                .frame(width: size * bodyWidth, height: size * bodyHeight)
                .offset(y: size * 0.12)

            PixelRect(color: Color(hex: appearance.secondaryFurHex))
                .frame(width: size * bellyWidth, height: size * 0.18)
                .offset(x: size * bellyX, y: size * 0.17)

            PixelRect(color: Color(hex: appearance.headColorHex))
                .frame(width: size * headWidth, height: size * headHeight)
                .offset(y: size * -0.16)

            PixelRect(color: Color(hex: appearance.earColorHex))
                .frame(width: size * earWidth, height: size * earHeight)
                .offset(x: size * -0.20, y: size * earY)

            PixelRect(color: Color(hex: appearance.earColorHex))
                .frame(width: size * earWidth, height: size * earHeight)
                .offset(x: size * 0.20, y: size * earY)

            if appearance.marking == .forehead || breed == .borderCollie {
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * markingWidth, height: size * 0.13)
                    .offset(y: size * -0.23)
            }

            if breed == .borderCollie {
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.22, height: size * 0.30)
                    .offset(x: size * -0.18, y: size * 0.05)
            }

            if breed == .golden {
                PixelRect(color: Color(hex: appearance.secondaryFurHex, alpha: 0.85))
                    .frame(width: size * 0.12, height: size * 0.18)
                    .offset(x: size * -0.25, y: size * -0.11)
                PixelRect(color: Color(hex: appearance.secondaryFurHex, alpha: 0.85))
                    .frame(width: size * 0.12, height: size * 0.18)
                    .offset(x: size * 0.25, y: size * -0.11)
            }

            if breed == .native {
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.12, height: size * 0.10)
                    .offset(x: size * -0.05, y: size * -0.26)
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.16, height: size * 0.12)
                    .offset(x: size * 0.14, y: size * 0.04)
            }

            if breed == .bulldog {
                // Wider chest for bulldog
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.35, height: size * 0.15)
                    .offset(y: size * 0.18)
            }

            if breed == .teddy {
                // Curly fur texture for teddy
                PixelRect(color: Color(hex: appearance.headColorHex, alpha: 0.7))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: size * -0.15, y: size * -0.20)
                PixelRect(color: Color(hex: appearance.headColorHex, alpha: 0.7))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: size * 0.15, y: size * -0.20)
                PixelRect(color: Color(hex: appearance.headColorHex, alpha: 0.7))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: size * 0.0, y: size * -0.28)
            }

            if appearance.marking == .backPatch {
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: size * 0.16, y: size * 0.08)
            }

            // Eyes - different based on pose
            if pose == "focused" {
                // Focused pose: half-closed eyes (horizontal lines)
                PixelRect(color: Color(hex: 0x2A241F))
                    .frame(width: size * eyeSize * 1.2, height: size * eyeSize * 0.3)
                    .offset(x: size * -0.10, y: size * -0.14)
                PixelRect(color: Color(hex: 0x2A241F))
                    .frame(width: size * eyeSize * 1.2, height: size * eyeSize * 0.3)
                    .offset(x: size * 0.10, y: size * -0.14)
            } else {
                // Normal eyes
                PixelRect(color: Color(hex: 0x2A241F))
                    .frame(width: size * eyeSize, height: size * eyeSize)
                    .offset(x: size * -0.10, y: size * -0.14)
                PixelRect(color: Color(hex: 0x2A241F))
                    .frame(width: size * eyeSize, height: size * eyeSize)
                    .offset(x: size * 0.10, y: size * -0.14)
            }

            PixelRect(color: Color(hex: 0x2A241F))
                .frame(width: size * 0.07, height: size * 0.04)
                .offset(y: size * -0.05)

            PixelRect(color: Color(hex: appearance.secondaryFurHex))
                .frame(width: size * 0.18, height: size * 0.10)
                .offset(y: size * -0.01)

            PixelRect(color: Color(hex: 0x2A241F))
                .frame(width: size * 0.07, height: size * 0.04)
                .offset(y: size * -0.03)

            PixelRect(color: Color(hex: 0x2A241F))
                .frame(width: size * 0.08, height: size * 0.025)
                .offset(y: size * 0.01)

            PixelRect(color: Color(hex: appearance.collarHex))
                .frame(width: size * 0.46, height: size * 0.07)
                .offset(y: size * 0.03)

            PixelRect(color: Color(hex: appearance.legColorHex))
                .frame(width: size * legWidth, height: size * legHeight)
                .offset(x: size * -0.18, y: size * legY)
            PixelRect(color: Color(hex: appearance.legColorHex))
                .frame(width: size * legWidth, height: size * legHeight)
                .offset(x: size * 0.18, y: size * legY)

            if appearance.marking == .paws {
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.11, height: size * 0.05)
                    .offset(x: size * -0.18, y: size * 0.39)
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.11, height: size * 0.05)
                    .offset(x: size * 0.18, y: size * 0.39)
            }

            if breed == .shiba {
                PixelRect(color: Color(hex: appearance.tailColorHex))
                    .frame(width: size * 0.20, height: size * 0.20)
                    .offset(x: size * tailX, y: size * -0.02)
                PixelRect(color: Color(hex: appearance.secondaryFurHex))
                    .frame(width: size * 0.10, height: size * 0.10)
                    .offset(x: size * tailX, y: size * -0.02)
            } else {
                PixelRect(color: Color(hex: appearance.tailColorHex))
                    .frame(width: size * tailWidth, height: size * tailHeight)
                    .offset(x: size * tailX, y: size * tailY)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pose == "happy" ? 1.04 : (pose == "focused" ? 0.98 : 1))
        .offset(y: pose == "focused" ? size * 0.03 : 0)

    private var bodyWidth: CGFloat {
        switch breed {
        case .golden: return 0.68
        case .bulldog: return 0.65
        case .borderCollie: return 0.62
        case .native: return 0.58
        case .shiba: return 0.52
        case .teddy: return 0.48
        }
    }

    private var bodyHeight: CGFloat {
        switch breed {
        case .golden: return 0.44
        case .native: return 0.44
        case .borderCollie: return 0.42
        case .shiba: return 0.40
        case .bulldog: return 0.38
        case .teddy: return 0.36
        }
    }

    private var headWidth: CGFloat {
        switch breed {
        case .bulldog: return 0.44
        case .golden: return 0.44
        default: return 0.40
        }
    }

    private var headHeight: CGFloat {
        switch breed {
        case .bulldog: return 0.38
        case .golden: return 0.32
        case .teddy: return 0.34
        default: return 0.36
        }
    }

    private var bellyWidth: CGFloat {
        breed == .borderCollie ? 0.22 : 0.30
    }

    private var bellyX: CGFloat {
        breed == .borderCollie ? 0.10 : 0.03
    }

    private var markingWidth: CGFloat {
        breed == .borderCollie ? 0.24 : 0.16
    }

    private var eyeSize: CGFloat {
        size < 30 ? 0.075 : 0.060
    }

    private var earWidth: CGFloat {
        switch breed {
        case .golden: return 0.16
        case .bulldog: return 0.15
        case .teddy: return 0.11
        default: return 0.13
        }
    }

    private var earHeight: CGFloat {
        switch breed {
        case .golden: return 0.22
        case .bulldog: return 0.14
        case .teddy: return 0.15
        default: return 0.19
        }
    }

    private var earY: CGFloat {
        switch breed {
        case .golden: return -0.28
        case .bulldog: return -0.30
        case .teddy: return -0.32
        default: return -0.35
        }
    }

    private var tailX: CGFloat {
        switch breed {
        case .shiba: return pose == "waiting" ? -0.34 : 0.34
        case .golden: return pose == "waiting" ? -0.43 : 0.43
        case .borderCollie: return pose == "waiting" ? -0.40 : 0.40
        case .native: return pose == "waiting" ? -0.38 : 0.38
        case .bulldog: return pose == "waiting" ? -0.36 : 0.36
        case .teddy: return pose == "waiting" ? -0.30 : 0.30
        }
    }

    private var tailY: CGFloat {
        breed == .golden ? 0.16 : 0.08
    }

    private var tailWidth: CGFloat {
        breed == .golden ? 0.13 : 0.15
    }

    private var tailHeight: CGFloat {
        breed == .golden ? 0.36 : 0.30
    }

    private var legWidth: CGFloat {
        switch breed {
        case .bulldog: return 0.12
        case .teddy: return 0.09
        default: return 0.10
        }
    }

    private var legHeight: CGFloat {
        switch breed {
        case .bulldog: return 0.12
        case .teddy: return 0.13
        default: return 0.15
        }
    }

    private var legY: CGFloat {
        switch breed {
        case .bulldog: return 0.30
        case .teddy: return 0.31
        default: return 0.32
        }
    }

    private var shadowColor: UInt {
        pose == "waiting" ? 0x50675A : 0x315039
    }
}

struct PixelMapLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(Color(hex: 0x3E4F38))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color(hex: 0xFFF8E8, alpha: 0.88))
            .overlay {
                Rectangle()
                    .stroke(Color(hex: 0x7C9B64), lineWidth: 1)
            }
    }
}

struct PixelRect: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
    }
}

struct PixelTinyGrid: View {
    let colorA: Color
    let colorB: Color
    var tile: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let columns = Int(ceil(proxy.size.width / tile))
            let rows = Int(ceil(proxy.size.height / tile))

            ZStack(alignment: .topLeading) {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        Rectangle()
                            .fill((row + column).isMultiple(of: 2) ? colorA : colorB)
                            .frame(width: tile, height: tile)
                            .position(x: CGFloat(column) * tile + tile / 2, y: CGFloat(row) * tile + tile / 2)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct WeekRhythmView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(store.weekCompletion().enumerated()), id: \.offset) { _, done in
                PixelRhythmCell(done: done)
            }
        }
    }
}

struct TodayActionPanel: View {
    let eyebrow: String
    let headline: String
    let title: String
    let status: String
    let completedPlans: [String]
    let actionSession: ActionSession
    let isRecovery: Bool
    let isDone: Bool
    let isLongBreak: Bool
    let dogLevel: Int
    let intimacy: Int
    let nextLevelNeed: Int
    let openDogGoAction: () -> Void
    let selectPlanAction: (ActionPlan) -> Void
    let startTimerAction: (Int) -> Void
    let tickTimerAction: () -> Void
    let cancelSessionAction: () -> Void
    let completeAction: () -> Void
    let smallGoalAction: () -> Void
    let debugMissAction: () -> Void
    let debugResetAction: () -> Void

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .eyebrowStyle()
                Text(headline)
                    .font((isDone && actionSession.phase == .idle ? Font.caption : Font.headline).weight(.heavy))
                    .foregroundStyle(Color(hex: 0x26382B))
            }

            if isDone && !completedPlans.isEmpty && actionSession.phase == .idle {
                CompletedPlanBadges(plans: completedPlans)
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isRecovery ? "恢复任务" : "今日目标")
                        .eyebrowStyle()
                    Text(displayTitle)
                        .font(.title3.weight(.heavy))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                PixelStatusBadge(text: status, tone: statusTone)
            }

            if isLongBreak {
                Text("目标可能有点重，今天先做更小的一步。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x6A5B46))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0xF5E5BF))
                    .overlay {
                        Rectangle()
                            .stroke(Color(hex: 0xC7A76D), lineWidth: 1)
                    }
            }

            actionContent

            if isLongBreak {
                PixelSecondaryButton(title: "使用小目标") {
                    smallGoalAction()
                }
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("本周节奏")
                        .eyebrowStyle()
                    WeekRhythmView()
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color(hex: 0xC69A3E))
                        Text("Lv.\(dogLevel)")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color(hex: 0x356247))
                    }
                    PixelProgressBar(value: intimacy, max: nextLevelNeed, height: 5, fillColor: Color(hex: 0x5D8B6A))
                        .frame(width: 60)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(hex: 0xEAF1DA))
                .overlay {
                    Rectangle()
                        .stroke(Color(hex: 0x9BB985), lineWidth: 1)
                }
            }

            #if DEBUG
            HStack(spacing: 8) {
                PixelDebugButton(title: "漏一天", action: debugMissAction)
                PixelDebugButton(title: "重置", action: debugResetAction)
            }
            #endif
        }
        .padding(12)
        .background {
            ZStack {
                Color(hex: 0xFFF8E8)
                PixelTinyGrid(colorA: Color(hex: 0xF4E6C6, alpha: 0.34), colorB: Color.clear, tile: 14)
                    .opacity(0.78)
            }
        }
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x7C9B64), lineWidth: 3)
        }
        .shadow(color: Color(hex: 0x3E4F38, alpha: 0.16), radius: 0, x: 4, y: 4)
        .onReceive(timer) { _ in
            if actionSession.phase == .running {
                tickTimerAction()
            }
        }
    }

    @ViewBuilder
    private var actionContent: some View {
        switch actionSession.phase {
        case .idle:
            PixelPrimaryButton(title: isRecovery ? "做个小恢复" : "Dog Go!") {
                isRecovery ? completeAction() : openDogGoAction()
            }
        case .choosingPlan:
            VStack(alignment: .leading, spacing: 8) {
                Text("选择今天的计划")
                    .eyebrowStyle()
                HStack(spacing: 8) {
                    planChoiceButton(plan: .fitness, icon: "figure.run")
                    planChoiceButton(plan: .study, icon: "book.fill")
                    planChoiceButton(plan: .leisure, icon: "cup.and.saucer.fill")
                }
                PixelSecondaryButton(title: "取消") {
                    cancelSessionAction()
                }
            }
        case .choosingTime:
            VStack(alignment: .leading, spacing: 8) {
                Text("\(actionSession.plan?.label ?? "计划")多久？")
                    .eyebrowStyle()
                HStack(spacing: 6) {
                    ForEach([5, 10, 20, 30], id: \.self) { minutes in
                        timeChoiceButton(minutes: minutes)
                    }
                }
                PixelSecondaryButton(title: "重选计划") {
                    cancelSessionAction()
                    openDogGoAction()
                }
            }
        case .running:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(actionSession.plan?.activeLabel ?? "行动中")
                            .eyebrowStyle()
                        Text(formattedTime(actionSession.remainingSeconds))
                            .font(.system(size: 36, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x26382B))
                    }
                    Spacer()
                    runningDogCompanion
                }
                runningProgressBar
                PixelSecondaryButton(title: "取消本次") {
                    cancelSessionAction()
                }
            }
        case .finished:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color(hex: 0x5D8B6A))
                    Text("时间到了！")
                        .eyebrowStyle()
                }
                PixelPrimaryButton(title: "Dog done!") {
                    completeAction()
                }
            }
        }
    }

    private func planChoiceButton(plan: ActionPlan, icon: String) -> some View {
        Button {
            selectPlanAction(plan)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(actionSession.plan == plan ? Color(hex: 0x356247) : Color(hex: 0x7C9B64))
                Text(plan.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(actionSession.plan == plan ? Color(hex: 0x356247) : Color(hex: 0x5D6B55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(actionSession.plan == plan ? Color(hex: 0xDDEBCB) : Color(hex: 0xF4E6C6, alpha: 0.5))
            .overlay {
                Rectangle()
                    .stroke(actionSession.plan == plan ? Color(hex: 0x356247) : Color(hex: 0x9BB985), lineWidth: actionSession.plan == plan ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func timeChoiceButton(minutes: Int) -> some View {
        Button {
            startTimerAction(minutes)
        } label: {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(size: minutes >= 20 ? 18 : 15, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(hex: 0x356247))
                Text("min")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFFF8E8))
            .overlay {
                Rectangle()
                    .stroke(Color(hex: 0x7C9B64), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var runningDogCompanion: some View {
        HStack(spacing: 4) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(Color(hex: 0x5D8B6A))
            Text(actionSession.plan?.dogLine ?? "狗狗也在行动")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(Color(hex: 0x356247))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(hex: 0xEAF1DA))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x9BB985), lineWidth: 1)
        }
    }

    private var runningProgressBar: some View {
        GeometryReader { geo in
            let progress = actionSession.durationSeconds > 0
                ? CGFloat(actionSession.durationSeconds - actionSession.remainingSeconds) / CGFloat(actionSession.durationSeconds)
                : 0
            ZStack(alignment: .leading) {
                PixelRect(color: Color(hex: 0xE8E0D0))
                PixelRect(color: Color(hex: 0x5D8B6A))
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 8)
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0x7C9B64), lineWidth: 1)
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var displayTitle: String {
        switch actionSession.phase {
        case .idle:
            return "Dog Go! 一下"
        case .choosingPlan:
            return "选择今天的计划"
        case .choosingTime:
            return "\(actionSession.plan?.label ?? "计划")行动"
        case .running, .finished:
            if let plan = actionSession.plan {
                return "\(plan.label) \(max(1, actionSession.durationSeconds / 60)) 分钟"
            }
            return title
        }
    }

    private var statusTone: PixelStatusBadge.Tone {
        if isDone && actionSession.phase == .idle { return .done }
        if isRecovery { return .recovery }
        return .pending
    }
}

struct CompletedPlanBadges: View {
    let plans: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 74), spacing: 6, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(Array(plans.enumerated()), id: \.offset) { index, plan in
                HStack(spacing: 4) {
                    PixelRect(color: badgeDotColor(index))
                        .frame(width: 6, height: 6)
                    Text(plan)
                        .font(.caption2.weight(.heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundStyle(Color(hex: 0x2F593D))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xEAF1DA))
                .overlay {
                    Rectangle()
                        .stroke(Color(hex: 0x9BB985), lineWidth: 1)
                }
            }
        }
    }

    private func badgeDotColor(_ index: Int) -> Color {
        [Color(hex: 0x5D8B6A), Color(hex: 0xC69A3E), Color(hex: 0x4C7FA6), Color(hex: 0xC65B44)][index % 4]
    }
}

struct AppBottomBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 8) {
            BottomBarItem(title: "Dog Go", systemImage: "pawprint.fill", isSelected: store.state.screen == .home) {
                store.go(.home)
            }

            BottomBarItem(title: "Dog Done", systemImage: "checkmark.seal.fill", isSelected: store.state.screen == .progress) {
                store.go(.progress)
            }

            BottomBarItem(title: "Dog Dog", systemImage: "pawprint.circle.fill", isSelected: store.state.screen == .dogDog) {
                store.go(.dogDog)
            }

            BottomBarItem(title: "Dog Home", systemImage: "house.lodge.fill", isSelected: store.state.screen == .dogHome) {
                store.go(.dogHome)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background {
            ZStack {
                Color(hex: 0xFFF8E8).opacity(0.97)
                PixelTinyGrid(colorA: Color(hex: 0xEAF1DA, alpha: 0.4), colorB: Color.clear, tile: 10)
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: 0x7C9B64))
                .frame(height: 2)
        }
    }
}

struct BottomBarItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .heavy))
                Text(title)
                    .font(.caption2.weight(.heavy))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(foreground)
            .background {
                ZStack {
                    background
                    PixelTinyGrid(colorA: Color(hex: 0xFFF8E8, alpha: isSelected ? 0.06 : 0.18), colorB: Color.clear, tile: 8)
                }
            }
            .overlay {
                Rectangle()
                    .stroke(border, lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: isSelected ? Color(hex: 0x1E3D2C, alpha: 0.22) : Color.clear, radius: 0, x: 2, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        if isSelected { return Color(hex: 0xFFF8E8) }
        return Color(hex: 0x41573E)
    }

    private var background: Color {
        if isSelected { return Color(hex: 0x356247) }
        return Color(hex: 0xEAF1DA)
    }

    private var border: Color {
        if isSelected { return Color(hex: 0x1E3D2C) }
        return Color(hex: 0x9BB985)
    }
}

struct PixelRhythmCell: View {
    let done: Bool

    var body: some View {
        Rectangle()
            .fill(done ? Color(hex: 0x5D8B6A) : Color(hex: 0xD9CFB9))
            .frame(width: 22, height: 12)
            .overlay {
                Rectangle()
                    .stroke(done ? Color(hex: 0x356247) : Color(hex: 0xBCA98B), lineWidth: 1)
            }
    }
}

struct PixelStatusBadge: View {
    enum Tone {
        case pending
        case recovery
        case done
    }

    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(background)
            .overlay {
                Rectangle()
                    .stroke(border, lineWidth: 1)
            }
    }

    private var foreground: Color {
        switch tone {
        case .pending: return Color(hex: 0x3E4F38)
        case .recovery: return Color(hex: 0x514830)
        case .done: return Color(hex: 0x2F593D)
        }
    }

    private var background: Color {
        switch tone {
        case .pending: return Color(hex: 0xE8F0D9)
        case .recovery: return Color(hex: 0xF2DFA8)
        case .done: return Color(hex: 0xDDEBCB)
        }
    }

    private var border: Color {
        switch tone {
        case .pending: return Color(hex: 0x9BB985)
        case .recovery: return Color(hex: 0xC7A76D)
        case .done: return Color(hex: 0x5D8B6A)
        }
    }
}

struct PixelPrimaryButton: View {
    let title: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.plain)
        .background {
            ZStack {
                disabled ? Color(hex: 0xD5D8C7) : Color(hex: 0x356247)
                PixelTinyGrid(colorA: Color(hex: 0xFFF8E8, alpha: disabled ? 0.08 : 0.10), colorB: Color.clear, tile: 9)
            }
        }
        .foregroundStyle(disabled ? Color(hex: 0x6B715F) : .white)
        .overlay {
            Rectangle()
                .stroke(disabled ? Color(hex: 0xA4AA96) : Color(hex: 0x1E3D2C), lineWidth: 3)
        }
        .shadow(color: disabled ? Color.clear : Color(hex: 0x1E3D2C, alpha: 0.25), radius: 0, x: 3, y: 3)
        .disabled(disabled)
    }
}

struct PixelSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .background {
            ZStack {
                Color(hex: 0xF6E9C8)
                PixelTinyGrid(colorA: Color(hex: 0xFFF8E8, alpha: 0.34), colorB: Color.clear, tile: 8)
            }
        }
        .foregroundStyle(Color(hex: 0x3E3323))
        .overlay {
            Rectangle()
                .stroke(Color(hex: 0xC7A76D), lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x8D6D46, alpha: 0.18), radius: 0, x: 2, y: 2)
    }
}

struct PixelChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .background {
            ZStack {
                isSelected ? Color(hex: 0x356247) : Color(hex: 0xEAF1DA)
                PixelTinyGrid(colorA: Color(hex: 0xFFF8E8, alpha: isSelected ? 0.08 : 0.22), colorB: Color.clear, tile: 7)
            }
        }
        .foregroundStyle(isSelected ? Color(hex: 0xFFF8E8) : Color(hex: 0x356247))
        .overlay {
            Rectangle()
                .stroke(isSelected ? Color(hex: 0x1E3D2C) : Color(hex: 0x9BB985), lineWidth: isSelected ? 2 : 1)
        }
        .shadow(color: isSelected ? Color(hex: 0x1E3D2C, alpha: 0.20) : Color.clear, radius: 0, x: 2, y: 2)
    }
}

struct PixelDebugButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.caption2.weight(.bold))
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(hex: 0xECE7DA))
            .foregroundStyle(.secondary)
            .overlay {
                Rectangle()
                    .stroke(Color(hex: 0xC8BDA8), lineWidth: 1)
            }
    }
}

struct ScreenScaffold<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .padding(18)
                .frame(maxWidth: 430)
                .frame(maxWidth: .infinity)
        }
    }
}

struct Header: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .eyebrowStyle()
            Text(title)
                .font(.largeTitle.weight(.heavy))
                .lineSpacing(2)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: 0xECE0D0), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 22, y: 12)
    }
}

struct DogChoiceCard: View {
    let dog: DogBreed
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dog.initial)
                .font(.title.weight(.heavy))
                .foregroundStyle(faceForeground)
                .frame(width: 54, height: 54)
                .background(faceBackground)
                .clipShape(Circle())

            Text(dog.breedName)
                .font(.headline)

            FlowTags(tags: dog.tags)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(12)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color(hex: 0x356247) : Color(hex: 0xECE0D0), lineWidth: isSelected ? 2 : 1)
        }
    }

    private var faceBackground: LinearGradient {
        switch dog {
        case .shiba:
            return LinearGradient(colors: [Color(hex: 0xF4D29D), Color(hex: 0xD98945)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .golden:
            return LinearGradient(colors: [Color(hex: 0xFFE0A4), Color(hex: 0xF1B84E)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .borderCollie:
            return LinearGradient(colors: [Color.white, Color(hex: 0x202321)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .native:
            return LinearGradient(colors: [Color(hex: 0xD7B181), Color(hex: 0x835C36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .bulldog:
            return LinearGradient(colors: [Color(hex: 0xF5EDE5), Color(hex: 0xC8B8A8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .teddy:
            return LinearGradient(colors: [Color(hex: 0xD2B48C), Color(hex: 0x8B4513)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var faceForeground: Color {
        switch dog {
        case .borderCollie, .native, .teddy:
            return .white
        case .shiba, .golden, .bulldog:
            return Color(hex: 0x3C2715)
        }
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: 0x356247))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xE6F0E9))
                    .clipShape(Capsule())
            }
        }
    }
}

struct TemplateRow: View {
    let template: GoalTemplate
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(template.title)
                .font(.headline)
            Text("恢复任务：\(template.recoveryTitle)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(selected ? Color(hex: 0xE6F0E9) : Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(selected ? Color(hex: 0x356247) : Color(hex: 0xECE0D0), lineWidth: 1)
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.heavy))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PrimaryButton: View {
    let title: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.plain)
        .background(disabled ? Color(hex: 0xD7DED4) : Color(hex: 0x356247))
        .foregroundStyle(disabled ? Color(hex: 0x657161) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .disabled(disabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.68))
        .foregroundStyle(Color(hex: 0x24211D))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: 0xECE0D0), lineWidth: 1)
        }
    }
}
