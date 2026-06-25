import SwiftUI

// MARK: - 进化特效视图

struct EvolutionEffectsView: View {
    let evolution: DogEvolution
    let mood: DogMood

    var body: some View {
        ZStack {
            // 根据进化阶段显示不同特效
            switch evolution {
            case .puppy:
                EmptyView()
            case .adult:
                EmptyView()
            case .complete:
                GlowEffect()
            case .legendary:
                GlowEffect()
                HaloEffect()
                ParticleEffect()
            }
        }
    }
}

// MARK: - 发光特效

struct GlowEffect: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(0.3),
                        Color.orange.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 80
                )
            )
            .frame(width: 160, height: 160)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .opacity(isAnimating ? 0.6 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - 光环特效

struct HaloEffect: View {
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                Circle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .offset(y: -70)
                    .rotationEffect(.degrees(rotation + Double(index) * 45))
            }
        }
        .frame(width: 160, height: 160)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - 粒子特效

struct ParticleEffect: View {
    @State private var particles: [Particle] = (0..<12).map { _ in Particle() }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: particle.duration)
                            .repeatForever(autoreverses: false)
                        ) {
                            particle.animate()
                        }
                    }
            }
        }
        .frame(width: 160, height: 160)
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var duration: Double

    init() {
        let angle = Double.random(in: 0..<360)
        let radius = Double.random(in: 40..<70)
        self.position = CGPoint(
            x: 80 + CGFloat(cos(angle * .pi / 180) * radius),
            y: 80 + CGFloat(sin(angle * .pi / 180) * radius)
        )
        self.size = CGFloat.random(in: 3...6)
        self.color = [Color.yellow, Color.orange, Color.pink].randomElement()!
        self.opacity = Double.random(in: 0.3...0.7)
        self.duration = Double.random(in: 2...4)
    }

    mutating func animate() {
        let angle = Double.random(in: 0..<360)
        let radius = Double.random(in: 50..<80)
        position = CGPoint(
            x: 80 + CGFloat(cos(angle * .pi / 180) * radius),
            y: 80 + CGFloat(sin(angle * .pi / 180) * radius)
        )
        opacity = Double.random(in: 0.2...0.8)
    }
}

// MARK: - 进化进度条

struct EvolutionProgressBar: View {
    let currentEvolution: DogEvolution
    let totalCheckIns: Int

    var body: some View {
        VStack(spacing: 8) {
            // 当前阶段
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.orange)
                Text(currentEvolution.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let nextStage = currentEvolution.nextStage {
                    Text("→ \(nextStage.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 12)

            // 进度文字
            HStack {
                Text("已完成 \(totalCheckIns) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let nextRequired = currentEvolution.nextStageRequiredCheckIns {
                    let remaining = max(0, nextRequired - totalCheckIns)
                    Text("还需 \(remaining) 次")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("已达最高阶段！")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }

    private var progress: CGFloat {
        currentEvolution.progress(toNext: totalCheckIns)
    }
}

// MARK: - 心情显示

struct MoodDisplayView: View {
    let mood: DogMood

    var body: some View {
        HStack(spacing: 8) {
            Text(mood.emoji)
                .font(.title2)
            Text(mood.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(moodBackgroundColor)
        )
    }

    private var moodBackgroundColor: Color {
        switch mood {
        case .sad:
            return Color.blue.opacity(0.2)
        case .neutral:
            return Color.gray.opacity(0.2)
        case .happy:
            return Color.green.opacity(0.2)
        case .excited:
            return Color.orange.opacity(0.2)
        case .ecstatic:
            return Color.pink.opacity(0.2)
        }
    }
}

// MARK: - 日记查看器

struct DiaryViewerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if store.state.diaryEntries.isEmpty {
                        emptyDiaryView
                    } else {
                        ForEach(store.getRecentDiaryEntries(limit: 30)) { entry in
                            DiaryEntryCard(entry: entry)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("狗狗日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyDiaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("还没有日记")
                .font(.headline)
                .foregroundColor(.primary)
            Text("完成计划后，狗狗会自动写日记哦")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct DiaryEntryCard: View {
    let entry: DogDiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 日期和心情
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                MoodDisplayView(mood: entry.mood)
            }

            // 日记内容
            Text(entry.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // 统计数据
            HStack(spacing: 16) {
                if entry.completions > 0 {
                    Label("\(entry.completions) 次完成", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if entry.focusMinutes > 0 {
                    Label("\(entry.focusMinutes) 分钟专注", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                if entry.streakDays > 0 {
                    Label("连续 \(entry.streakDays) 天", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}

// MARK: - 进化动画弹窗

struct EvolutionPopupView: View {
    let oldEvolution: DogEvolution
    let newEvolution: DogEvolution
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 标题
                Text("🎉 进化成功！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // 进化前后对比
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text(oldEvolution.displayName)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "pawprint")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    VStack(spacing: 8) {
                        Text(newEvolution.displayName)
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                            .scaleEffect(showContent ? 1.2 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                    }
                }

                // 描述
                Text(evolutionDescription)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 关闭按钮
                Button(action: onDismiss) {
                    Text("太棒了！")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .padding(.top, 16)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 20)
            )
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }

    private var evolutionDescription: String {
        switch newEvolution {
        case .puppy:
            return "你的狗狗还是个小宝宝"
        case .adult:
            return "狗狗长大了，更加活泼了！"
        case .complete:
            return "完全体！狗狗散发出耀眼的光芒！"
        case .legendary:
            return "传奇诞生！你的狗狗已经成为传说！"
        }
    }
}
