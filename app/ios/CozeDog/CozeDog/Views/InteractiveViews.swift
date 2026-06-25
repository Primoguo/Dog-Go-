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
            PixelRect(color: "#228B22", width: 3, height: 20)
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
