import SwiftUI

// MARK: - 场景视图

struct SceneBackgroundView: View {
    let scene: SceneType
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        ZStack {
            // 天空背景
            skyBackground

            // 场景特定元素
            switch scene {
            case .yard:
                YardSceneView(timeOfDay: timeOfDay, weather: weather, season: season)
            case .park:
                ParkSceneView(timeOfDay: timeOfDay, weather: weather, season: season)
            case .beach:
                BeachSceneView(timeOfDay: timeOfDay, weather: weather, season: season)
            case .forest:
                ForestSceneView(timeOfDay: timeOfDay, weather: weather, season: season)
            }

            // 天气效果
            WeatherEffectsView(weather: weather)
        }
    }

    private var skyBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: timeOfDay.skyColor),
                Color(hex: timeOfDay.skyColor).opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(timeOfDay.ambientLight)
    }
}

// MARK: - 温馨小院场景

struct YardSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 草地
                Rectangle()
                    .fill(Color(hex: "#7CCD7C"))
                    .frame(height: proxy.size.height * 0.6)
                    .offset(y: proxy.size.height * 0.4)

                // 栅栏
                ForEach(0..<8) { index in
                    PixelRect(
                        color: "#8B4513",
                        width: 4,
                        height: 40
                    )
                    .position(
                        x: CGFloat(index) * proxy.size.width / 7 + 20,
                        y: proxy.size.height * 0.45
                    )
                }

                // 小屋
                YardHouseView()
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.5)

                // 树木
                YardTreeView(season: season)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.45)

                // 花朵
                if season != .winter {
                    ForEach(0..<5) { index in
                        PixelFlowerView(color: "#FF69B4")
                            .position(
                                x: CGFloat.random(in: 50...proxy.size.width - 50),
                                y: proxy.size.height * CGFloat.random(in: 0.6...0.8)
                            )
                    }
                }
            }
        }
    }
}

struct YardHouseView: View {
    var body: some View {
        ZStack {
            // 屋顶
            PixelTriangle(color: "#8B0000", size: 60)
                .offset(y: -30)

            // 房体
            PixelRect(color: "#DEB887", width: 50, height: 40)
                .offset(y: 10)

            // 门
            PixelRect(color: "#8B4513", width: 12, height: 20)
                .offset(y: 20)

            // 窗户
            PixelRect(color: "#87CEEB", width: 10, height: 10)
                .offset(x: -15, y: 5)
            PixelRect(color: "#87CEEB", width: 10, height: 10)
                .offset(x: 15, y: 5)
        }
    }
}

struct YardTreeView: View {
    let season: Season

    var body: some View {
        ZStack {
            // 树干
            PixelRect(color: "#8B4513", width: 12, height: 40)
                .offset(y: 20)

            // 树叶
            Circle()
                .fill(Color(hex: season.leafColor))
                .frame(width: 50, height: 50)
                .offset(y: -10)
        }
    }
}

// MARK: - 阳光公园场景

struct ParkSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 草地
                Rectangle()
                    .fill(Color(hex: "#7CCD7C"))
                    .frame(height: proxy.size.height * 0.7)
                    .offset(y: proxy.size.height * 0.3)

                // 小路
                PixelPath(color: "#D2B48C", width: proxy.size.width * 0.8)
                    .offset(y: proxy.size.height * 0.6)

                // 树木
                ForEach(0..<3) { index in
                    ParkTreeView(season: season)
                        .position(
                            x: proxy.size.width * CGFloat(index + 1) / 4,
                            y: proxy.size.height * 0.4
                        )
                }

                // 长椅
                ParkBenchView()
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.65)

                // 太阳/月亮
                CelestialBodyView(timeOfDay: timeOfDay)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.15)
            }
        }
    }
}

struct ParkTreeView: View {
    let season: Season

    var body: some View {
        ZStack {
            // 树干
            PixelRect(color: "#8B4513", width: 16, height: 50)
                .offset(y: 25)

            // 树冠
            Circle()
                .fill(Color(hex: season.leafColor))
                .frame(width: 70, height: 70)
                .offset(y: -15)
        }
    }
}

struct ParkBenchView: View {
    var body: some View {
        ZStack {
            // 座位
            PixelRect(color: "#8B4513", width: 60, height: 8)
                .offset(y: -5)

            // 靠背
            PixelRect(color: "#8B4513", width: 60, height: 20)
                .offset(y: -15)

            // 腿
            PixelRect(color: "#654321", width: 6, height: 15)
                .offset(x: -25, y: 5)
            PixelRect(color: "#654321", width: 6, height: 15)
                .offset(x: 25, y: 5)
        }
    }
}

struct CelestialBodyView: View {
    let timeOfDay: TimeOfDay

    var body: some View {
        Group {
            if timeOfDay == .night {
                // 月亮
                Circle()
                    .fill(Color(hex: "#F4F4F4"))
                    .frame(width: 40, height: 40)
                    .shadow(color: .white.opacity(0.5), radius: 10)
            } else {
                // 太阳
                Circle()
                    .fill(Color(hex: "#FFD700"))
                    .frame(width: 50, height: 50)
                    .shadow(color: .yellow.opacity(0.6), radius: 15)
            }
        }
    }
}

// MARK: - 海边沙滩场景

struct BeachSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 沙滩
                Rectangle()
                    .fill(Color(hex: "#F4A460"))
                    .frame(height: proxy.size.height * 0.5)
                    .offset(y: proxy.size.height * 0.5)

                // 海浪
                WaveView(offset: waveOffset)
                    .fill(Color(hex: "#4682B4").opacity(0.6))
                    .frame(height: proxy.size.height * 0.3)
                    .offset(y: proxy.size.height * 0.45)

                // 贝壳
                ForEach(0..<4) { index in
                    PixelShellView()
                        .position(
                            x: CGFloat.random(in: 30...proxy.size.width - 30),
                            y: proxy.size.height * CGFloat.random(in: 0.6...0.8)
                        )
                }

                // 棕榈树
                PalmTreeView()
                    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.45)
                PalmTreeView()
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.45)

                // 太阳/月亮
                CelestialBodyView(timeOfDay: timeOfDay)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.15)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    waveOffset = 20
                }
            }
        }
    }
}

struct WaveView: View {
    let offset: CGFloat

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 50))
            for x in stride(from: 0, through: UIScreen.main.bounds.width, by: 10) {
                let y = 50 + sin((x + offset) / 30) * 10
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 200))
            path.addLine(to: CGPoint(x: 0, y: 200))
            path.closeSubpath()
        }
    }
}

struct PalmTreeView: View {
    var body: some View {
        ZStack {
            // 树干
            PixelRect(color: "#8B4513", width: 12, height: 60)
                .offset(y: 30)

            // 叶子
            ForEach(0..<5) { index in
                Ellipse()
                    .fill(Color(hex: "#228B22"))
                    .frame(width: 40, height: 15)
                    .rotationEffect(.degrees(Double(index) * 72 - 90))
                    .offset(y: -10)
            }
        }
    }
}

struct PixelShellView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#FFC0CB"))
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color(hex: "#FFB6C1"))
                .frame(width: 8, height: 8)
                .offset(x: -2, y: -2)
        }
    }
}

// MARK: - 神秘森林场景

struct ForestSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    @State private var sparklePositions: [CGPoint] = (0..<15).map { _ in
        CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.7)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 深绿色背景
                Rectangle()
                    .fill(Color(hex: "#2F4F2F"))
                    .frame(height: proxy.size.height * 0.7)
                    .offset(y: proxy.size.height * 0.3)

                // 树木
                ForEach(0..<5) { index in
                    ForestTreeView()
                        .position(
                            x: proxy.size.width * CGFloat(index + 1) / 6,
                            y: proxy.size.height * 0.4
                        )
                }

                // 魔法粒子
                if timeOfDay == .night || timeOfDay == .evening {
                    ForEach(0..<sparklePositions.count, id: \.self) { index in
                        MagicSparkleView()
                            .position(sparklePositions[index])
                            .opacity(Double.random(in: 0.3...0.8))
                    }
                }

                // 蘑菇
                ForEach(0..<3) { index in
                    MushroomView()
                        .position(
                            x: CGFloat.random(in: 50...proxy.size.width - 50),
                            y: proxy.size.height * CGFloat.random(in: 0.6...0.75)
                        )
                }
            }
        }
    }
}

struct ForestTreeView: View {
    var body: some View {
        ZStack {
            // 树干
            PixelRect(color: "#654321", width: 20, height: 70)
                .offset(y: 35)

            // 树冠（三角形）
            PixelTriangle(color: "#006400", size: 80)
                .offset(y: -20)
            PixelTriangle(color: "#228B22", size: 60)
                .offset(y: -40)
        }
    }
}

struct MagicSparkleView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.yellow, Color.purple.opacity(0.5), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 8
                )
            )
            .frame(width: 12, height: 12)
            .scaleEffect(isAnimating ? 1.5 : 0.8)
            .opacity(isAnimating ? 0.8 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

struct MushroomView: View {
    var body: some View {
        ZStack {
            // 菌盖
            Circle()
                .fill(Color(hex: "#FF0000"))
                .frame(width: 20, height: 15)
                .offset(y: -5)

            // 白点
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .offset(x: -5, y: -7)
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .offset(x: 5, y: -3)

            // 菌柄
            PixelRect(color: "#F5F5DC", width: 8, height: 12)
                .offset(y: 5)
        }
    }
}

// MARK: - 天气效果

struct WeatherEffectsView: View {
    let weather: Weather

    var body: some View {
        switch weather {
        case .sunny:
            EmptyView()
        case .cloudy:
            CloudsView()
        case .rainy:
            RainView()
        case .snowy:
            SnowView()
        }
    }
}

struct CloudsView: View {
    @State private var cloudOffset: CGFloat = -100

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<4) { index in
                    CloudView()
                        .position(
                            x: cloudOffset + CGFloat(index) * 150,
                            y: CGFloat.random(in: 50...150)
                        )
                        .opacity(0.7)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                    cloudOffset = proxy.size.width + 100
                }
            }
        }
    }
}

struct CloudView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 50, height: 50)
                .offset(x: 20, y: -5)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 35, height: 35)
                .offset(x: 40, y: 5)
        }
    }
}

struct RainView: View {
    @State private var rainDrops: [RainDrop] = (0..<50).map { _ in RainDrop() }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(rainDrops) { drop in
                    PixelRect(color: "#4682B4", width: 2, height: 15)
                        .position(drop.position)
                        .opacity(0.6)
                        .onAppear {
                            withAnimation(
                                .linear(duration: drop.duration)
                                .repeatForever(autoreverses: false)
                            ) {
                                drop.position.y = proxy.size.height + 20
                            }
                        }
                }
            }
        }
    }
}

struct RainDrop: Identifiable {
    let id = UUID()
    var position: CGPoint
    var duration: Double

    init() {
        self.position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: -100...0)
        )
        self.duration = Double.random(in: 1...2)
    }
}

struct SnowView: View {
    @State private var snowFlakes: [SnowFlake] = (0..<40).map { _ in SnowFlake() }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(snowFlakes) { flake in
                    Circle()
                        .fill(Color.white)
                        .frame(width: flake.size, height: flake.size)
                        .position(flake.position)
                        .opacity(0.8)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: flake.duration)
                                .repeatForever(autoreverses: false)
                            ) {
                                flake.position.y = proxy.size.height + 20
                                flake.position.x += CGFloat.random(in: -30...30)
                            }
                        }
                }
            }
        }
    }
}

struct SnowFlake: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var duration: Double

    init() {
        self.position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: -100...0)
        )
        self.size = CGFloat.random(in: 3...8)
        self.duration = Double.random(in: 3...6)
    }
}

// MARK: - 辅助视图

struct PixelTriangle: View {
    let color: String
    let size: CGFloat

    var body: some View {
        Triangle()
            .fill(Color(hex: color))
            .frame(width: size, height: size)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PixelPath: View {
    let color: String
    let width: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color(hex: color))
            .frame(width: width, height: 20)
    }
}

struct PixelFlowerView: View {
    let color: String

    var body: some View {
        ZStack {
            // 花瓣
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 8, height: 8)
                    .offset(y: -6)
                    .rotationEffect(.degrees(Double(index) * 72))
            }

            // 花心
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Color 扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
