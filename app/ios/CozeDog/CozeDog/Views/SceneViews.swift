import SwiftUI

// MARK: - 场景背景（鸟瞰视角）

struct SceneBackgroundView: View {
    let scene: SceneType
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        ZStack {
            // 地面填充整个画面（鸟瞰无天空）
            groundBackground

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

    private var groundBackground: some View {
        // 鸟瞰视角：地面颜色根据时间和场景微调
        let baseColor: Color
        switch scene {
        case .yard: baseColor = Color(hex: "#7CCD7C")
        case .park: baseColor = Color(hex: "#6BBF6B")
        case .beach: baseColor = Color(hex: "#F4D03F")
        case .forest: baseColor = Color(hex: "#3D6B3D")
        }

        // 昼夜亮度调整
        let brightness = timeOfDay.ambientLight
        return baseColor
            .opacity(brightness)
            .ignoresSafeArea()
    }
}

// MARK: - 温馨小院场景（鸟瞰）

struct YardSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 草地纹理（鸟瞰：整个画面都是草地）
                Rectangle()
                    .fill(Color(hex: "#7CCD7C"))
                    .ignoresSafeArea()

                // 栅栏（鸟瞰：小矩形排列）
                ForEach(0..<10) { index in
                    PixelRect(color: Color(hex: "#8B4513"))
                        .frame(width: 6, height: 3)
                    .position(
                        x: CGFloat(index) * proxy.size.width / 9 + 15,
                        y: 20
                    )
                }

                // 小屋（鸟瞰：矩形屋顶）
                YardHouseView()
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.3)

                // 树木（鸟瞰：圆形树冠，无树干）
                YardTreeView(season: season)
                    .position(x: proxy.size.width * 0.75, y: proxy.size.height * 0.25)
                YardTreeView(season: season)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.4)

                // 花朵（鸟瞰：小圆点）
                if season != .winter {
                    ForEach(0..<6) { index in
                        PixelFlowerView(color: "#FF69B4")
                            .position(
                                x: CGFloat.random(in: 30...proxy.size.width - 30),
                                y: CGFloat.random(in: proxy.size.height * 0.5...proxy.size.height - 30)
                            )
                    }
                }

                // 小径
                Rectangle()
                    .fill(Color(hex: "#D2B48C"))
                    .frame(width: proxy.size.width * 0.6, height: 8)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.7)
            }
        }
    }
}

struct YardHouseView: View {
    var body: some View {
        ZStack {
            // 屋顶（鸟瞰：矩形）
            PixelRect(color: Color(hex: "#8B0000"))
                .frame(width: 50, height: 40)

            // 屋顶纹理
            PixelRect(color: Color(hex: "#A52A2A"))
                .frame(width: 40, height: 4)
                .offset(y: -10)
            PixelRect(color: Color(hex: "#A52A2A"))
                .frame(width: 40, height: 4)
                .offset(y: 0)
            PixelRect(color: Color(hex: "#A52A2A"))
                .frame(width: 40, height: 4)
                .offset(y: 10)

            // 烟囱
            PixelRect(color: Color(hex: "#654321"))
                .frame(width: 8, height: 8)
                .offset(x: 15, y: -12)
        }
    }
}

struct YardTreeView: View {
    let season: Season

    var body: some View {
        ZStack {
            // 树冠（鸟瞰：圆形，无树干）
            Circle()
                .fill(Color(hex: season.leafColor))
                .frame(width: 45, height: 45)

            // 树冠中心深色
            Circle()
                .fill(Color(hex: season.leafColor).opacity(0.7))
                .frame(width: 20, height: 20)

            // 树干顶部（鸟瞰：小圆点）
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - 阳光公园场景（鸟瞰）

struct ParkSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 草地（鸟瞰：整个画面）
                Rectangle()
                    .fill(Color(hex: "#6BBF6B"))
                    .ignoresSafeArea()

                // 小路（鸟瞰：弯曲条带）
                ScenePathStrip(color: "#D2B48C", width: proxy.size.width * 0.9)
                    .frame(height: 12)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)

                // 树木（鸟瞰：不同大小的圆形）
                ParkTreeView(season: season, size: 55)
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.25)
                ParkTreeView(season: season, size: 65)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.2)
                ParkTreeView(season: season, size: 50)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.3)
                ParkTreeView(season: season, size: 60)
                    .position(x: proxy.size.width * 0.3, y: proxy.size.height * 0.7)

                // 长椅（鸟瞰：小矩形）
                ParkBenchView()
                    .position(x: proxy.size.width * 0.7, y: proxy.size.height * 0.6)

                // 花坛
                FlowerBedView()
                    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.65)
            }
        }
    }
}

struct ParkTreeView: View {
    let season: Season
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // 树冠（鸟瞰：圆形）
            Circle()
                .fill(Color(hex: season.leafColor))
                .frame(width: size, height: size)

            // 树冠纹理
            Circle()
                .fill(Color(hex: season.leafColor).opacity(0.6))
                .frame(width: size * 0.5, height: size * 0.5)

            // 树干顶部
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 10, height: 10)
        }
    }
}

struct ParkBenchView: View {
    var body: some View {
        ZStack {
            // 座位（鸟瞰：矩形）
            PixelRect(color: Color(hex: "#8B4513"))
                .frame(width: 30, height: 12)

            // 靠背（鸟瞰：细条）
            PixelRect(color: Color(hex: "#654321"))
                .frame(width: 30, height: 3)
                .offset(y: -5)

            // 腿（鸟瞰：小点）
            Circle()
                .fill(Color(hex: "#654321"))
                .frame(width: 4, height: 4)
                .offset(x: -12, y: 4)
            Circle()
                .fill(Color(hex: "#654321"))
                .frame(width: 4, height: 4)
                .offset(x: 12, y: 4)
        }
    }
}

struct FlowerBedView: View {
    var body: some View {
        ZStack {
            // 花坛边缘
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 35, height: 35)

            // 花朵
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color(hex: ["#FF69B4", "#FFD700", "#FF6347", "#9370DB", "#FFA500"][index]))
                    .frame(width: 6, height: 6)
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 5) * 10,
                        y: sin(Double(index) * .pi * 2 / 5) * 10
                    )
            }

            // 中心
            Circle()
                .fill(Color(hex: "#FFD700"))
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - 海边沙滩场景（鸟瞰）

struct BeachSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 沙滩（鸟瞰：整个画面）
                Rectangle()
                    .fill(Color(hex: "#F4D03F"))
                    .ignoresSafeArea()

                // 海浪（鸟瞰：顶部蓝色条带）
                Rectangle()
                    .fill(Color(hex: "#4682B4").opacity(0.7))
                    .frame(height: proxy.size.height * 0.25)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.12)

                // 海浪边缘
                WaveShape(offset: waveOffset)
                    .fill(Color(hex: "#87CEEB").opacity(0.5))
                    .frame(height: 20)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.25)

                // 贝壳（鸟瞰：小形状）
                ForEach(0..<5) { index in
                    PixelShellView()
                        .position(
                            x: CGFloat.random(in: 30...proxy.size.width - 30),
                            y: CGFloat.random(in: proxy.size.height * 0.4...proxy.size.height - 30)
                        )
                }

                // 棕榈树（鸟瞰：圆形 + 放射叶子）
                PalmTreeView()
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.5)
                PalmTreeView()
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.6)

                // 遮阳伞（鸟瞰：圆形）
                BeachUmbrellaView()
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.7)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    waveOffset = 15
                }
            }
        }
    }
}

struct PalmTreeView: View {
    var body: some View {
        ZStack {
            // 树冠（鸟瞰：圆形）
            Circle()
                .fill(Color(hex: "#228B22"))
                .frame(width: 40, height: 40)

            // 叶子（鸟瞰：放射状）
            ForEach(0..<6) { index in
                Ellipse()
                    .fill(Color(hex: "#2E8B2E"))
                    .frame(width: 25, height: 8)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .offset(y: -15)
            }

            // 树干顶部
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 10, height: 10)
        }
    }
}

struct BeachUmbrellaView: View {
    var body: some View {
        ZStack {
            // 伞面（鸟瞰：圆形）
            Circle()
                .fill(Color(hex: "#FF6347"))
                .frame(width: 35, height: 35)

            // 伞面条纹
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 35, height: 4)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            // 伞柄顶部
            Circle()
                .fill(Color(hex: "#8B4513"))
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - 神秘森林场景（鸟瞰）

struct ForestSceneView: View {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    @State private var sparklePositions: [CGPoint] = (0..<15).map { _ in
        CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 森林地面（鸟瞰：深绿色）
                Rectangle()
                    .fill(Color(hex: "#3D6B3D"))
                    .ignoresSafeArea()

                // 树木（鸟瞰：不同大小的圆形，密集）
                ForestTreeView(size: 50)
                    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.2)
                ForestTreeView(size: 60)
                    .position(x: proxy.size.width * 0.4, y: proxy.size.height * 0.15)
                ForestTreeView(size: 55)
                    .position(x: proxy.size.width * 0.7, y: proxy.size.height * 0.25)
                ForestTreeView(size: 65)
                    .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.35)
                ForestTreeView(size: 45)
                    .position(x: proxy.size.width * 0.25, y: proxy.size.height * 0.5)
                ForestTreeView(size: 70)
                    .position(x: proxy.size.width * 0.6, y: proxy.size.height * 0.55)
                ForestTreeView(size: 50)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.65)
                ForestTreeView(size: 55)
                    .position(x: proxy.size.width * 0.1, y: proxy.size.height * 0.75)
                ForestTreeView(size: 60)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.8)

                // 蘑菇（鸟瞰：小圆形）
                ForEach(0..<4) { index in
                    MushroomView()
                        .position(
                            x: CGFloat.random(in: 40...proxy.size.width - 40),
                            y: CGFloat.random(in: proxy.size.height * 0.4...proxy.size.height - 40)
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

                // 小径
                ScenePathStrip(color: "#5D4E37", width: proxy.size.width * 0.7)
                    .frame(height: 10)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.45)
            }
        }
    }
}

struct ForestTreeView: View {
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // 树冠（鸟瞰：圆形，多层）
            Circle()
                .fill(Color(hex: "#006400"))
                .frame(width: size, height: size)

            Circle()
                .fill(Color(hex: "#228B22"))
                .frame(width: size * 0.7, height: size * 0.7)

            Circle()
                .fill(Color(hex: "#2E8B2E"))
                .frame(width: size * 0.4, height: size * 0.4)

            // 树干顶部
            Circle()
                .fill(Color(hex: "#654321"))
                .frame(width: 12, height: 12)
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
                        .opacity(0.5)
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
                .fill(Color.white.opacity(0.6))
                .frame(width: 40, height: 40)
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 50, height: 50)
                .offset(x: 20, y: -5)
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 35, height: 35)
                .offset(x: 40, y: 5)
        }
    }
}

struct RainView: View {
    @State private var rainDrops: [RainDrop] = (0..<50).map { _ in RainDrop() }
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(rainDrops) { drop in
                    PixelRect(color: Color(hex: "#4682B4")).frame(width: 2, height: 15)
                        .position(
                            x: drop.position.x,
                            y: isAnimating ? proxy.size.height + 20 : drop.position.y
                        )
                        .opacity(0.6)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
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
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(snowFlakes) { flake in
                    Circle()
                        .fill(Color.white)
                        .frame(width: flake.size, height: flake.size)
                        .position(
                            x: flake.position.x + (isAnimating ? flake.driftX : 0),
                            y: isAnimating ? proxy.size.height + 20 : flake.position.y
                        )
                        .opacity(0.8)
                }
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
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
    var driftX: CGFloat

    init() {
        self.position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: -100...0)
        )
        self.size = CGFloat.random(in: 3...8)
        self.duration = Double.random(in: 3...6)
        self.driftX = CGFloat.random(in: -30...30)
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

struct ScenePathStrip: View {
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
            // 花瓣（鸟瞰：圆形排列）
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 6, height: 6)
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 5) * 5,
                        y: sin(Double(index) * .pi * 2 / 5) * 5
                    )
            }

            // 花心
            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
        }
    }
}

struct PixelShellView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#FFC0CB"))
                .frame(width: 10, height: 10)
            Circle()
                .fill(Color(hex: "#FFB6C1"))
                .frame(width: 6, height: 6)
                .offset(x: -2, y: -2)
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
            // 菌盖（鸟瞰：圆形）
            Circle()
                .fill(Color(hex: "#FF0000"))
                .frame(width: 16, height: 16)

            // 白点
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .offset(x: -4, y: -4)
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .offset(x: 4, y: 2)

            // 菌柄（鸟瞰：小圆点）
            Circle()
                .fill(Color(hex: "#F5F5DC"))
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - WaveShape（海浪边缘）

struct WaveShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = 4
        let frequency: CGFloat = 0.02

        path.move(to: CGPoint(x: 0, y: rect.midY))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = rect.midY + sin(x * frequency + offset) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
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
