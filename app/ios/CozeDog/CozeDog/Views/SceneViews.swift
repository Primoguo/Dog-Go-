import SwiftUI

// MARK: - 场景背景（2.5D 等距视角）

struct SceneBackgroundView: View {
    let scene: SceneType
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        ZStack {
            // 天空 + 地面（等距视角能看到天空）
            skyAndGround

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

    private var skyAndGround: some View {
        GeometryReader { proxy in
            let skyHeight = proxy.size.height * 0.3
            let groundTop = skyHeight

            ZStack(alignment: .topLeading) {
                // 天空渐变
                LinearGradient(
                    colors: skyColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: skyHeight + 20) // 稍微延伸到地面以下避免缝隙

                // 地面（从 30% 高度开始）
                groundColor
                    .opacity(timeOfDay.ambientLight)
                    .frame(height: proxy.size.height - groundTop)
                    .offset(y: groundTop)
            }
            .ignoresSafeArea()
        }
    }

    private var skyColors: [Color] {
        switch timeOfDay {
        case .morning:
            return [Color(hex: 0xFFB347), Color(hex: 0x87CEEB)]
        case .afternoon:
            return [Color(hex: 0x87CEEB), Color(hex: 0xB0E0E6)]
        case .evening:
            return [Color(hex: 0xFF6B6B), Color(hex: 0xFFB347)]
        case .night:
            return [Color(hex: 0x1A1A2E), Color(hex: 0x16213E)]
        }
    }

    private var groundColor: Color {
        switch scene {
        case .yard: return Color(hex: 0x7CCD7C)
        case .park: return Color(hex: 0x6BBF6B)
        case .beach: return Color(hex: 0xF4D03F)
        case .forest: return Color(hex: 0x3D6B3D)
        }
    }
}

// MARK: - 温馨小院场景（2.5D 等距）

struct YardSceneView: View {
    @EnvironmentObject var store: AppStore
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let groundTop = h * 0.3

            ZStack {
                // 栅栏（等距：可见正面和侧面）
                ForEach(0..<12) { index in
                    let xPos = CGFloat(index) * w / 11
                    ZStack(alignment: .topLeading) {
                        // 栅栏柱正面
                        PixelRect(color: Color(hex: 0x8B4513))
                            .frame(width: 5, height: 18)
                        // 栅栏柱侧面
                        PixelRect(color: Color(hex: 0x6B3510))
                            .frame(width: 3, height: 18)
                            .offset(x: 5, y: 0)
                        // 栅栏柱顶面
                        PixelRect(color: Color(hex: 0xA0522D))
                            .frame(width: 8, height: 3)
                            .offset(x: 0, y: -3)
                    }
                    .position(x: xPos, y: groundTop + 8)
                }

                // 栅栏横杆
                PixelRect(color: Color(hex: 0xA0522D))
                    .frame(width: w * 0.9, height: 3)
                    .position(x: w * 0.5, y: groundTop + 4)

                // 小屋（等距建筑）
                YardHouseView()
                    .position(x: w * 0.18, y: groundTop + h * 0.12)

                // 树木（等距：可见树干 + 矩形树冠）
                YardTreeView(season: season)
                    .position(x: w * 0.72, y: groundTop + h * 0.08)
                YardTreeView(season: season)
                    .position(x: w * 0.85, y: groundTop + h * 0.18)

                // 狗窝（等距道具，点击休息：精力 +15 亲密度 +3）
                DogHouseView(size: min(w, h) * 0.12)
                    .position(x: w * 0.45, y: groundTop + h * 0.2)
                    .onTapGesture { store.interactSceneProp("dogHouse") }

                // 沙发（等距道具，点击放松：心情 +3 精力 +8）
                SofaView(size: min(w, h) * 0.11)
                    .position(x: w * 0.7, y: groundTop + h * 0.35)
                    .onTapGesture { store.interactSceneProp("sofa") }

                // 花朵（等距：可见花茎）
                if season != .winter {
                    ForEach(0..<5) { index in
                        PixelFlowerView(color: "#FF69B4")
                            .position(
                                x: w * (0.15 + CGFloat(index) * 0.15),
                                y: groundTop + h * (0.4 + CGFloat(index % 2) * 0.1)
                            )
                    }
                }

                // 小径（等距：有宽度的斜向路径）
                IsometricBox(
                    width: w * 0.5,
                    height: 6,
                    depth: 12,
                    topColor: Color(hex: 0xD2B48C),
                    frontColor: Color(hex: 0xC4A882),
                    sideColor: Color(hex: 0xB89B72)
                )
                .position(x: w * 0.4, y: groundTop + h * 0.42)
            }
        }
    }
}

/// 等距小屋：墙体（正面+侧面）+ 屋顶 + 门窗
struct YardHouseView: View {
    var body: some View {
        let wallW: CGFloat = 55
        let wallH: CGFloat = 40
        let wallD: CGFloat = 20

        ZStack(alignment: .bottom) {
            // 墙体正面
            PixelRect(color: Color(hex: 0xDEB887))
                .frame(width: wallW, height: wallH)
                .offset(x: 0, y: wallD)

            // 墙体侧面
            PixelRect(color: Color(hex: 0xC4A06A))
                .frame(width: wallD, height: wallH)
                .offset(x: wallW, y: wallD)

            // 门（正面）
            PixelRect(color: Color(hex: 0x8B4513))
                .frame(width: 14, height: 22)
                .offset(x: wallW * 0.15, y: wallD + wallH - 22)

            // 窗户（正面）
            PixelRect(color: Color(hex: 0x87CEEB))
                .frame(width: 12, height: 10)
                .offset(x: wallW * 0.6, y: wallD + wallH * 0.35)

            // 窗框
            PixelRect(color: Color(hex: 0x654321))
                .frame(width: 14, height: 2)
                .offset(x: wallW * 0.6, y: wallD + wallH * 0.35 - 5)
            PixelRect(color: Color(hex: 0x654321))
                .frame(width: 14, height: 2)
                .offset(x: wallW * 0.6, y: wallD + wallH * 0.35 + 5)

            // 窗户（侧面）
            PixelRect(color: Color(hex: 0x6BB8D6))
                .frame(width: 8, height: 10)
                .offset(x: wallW + wallD * 0.4, y: wallD + wallH * 0.35)

            // 屋顶（等距盒体）
            IsometricBox(
                width: wallW + 8,
                height: 8,
                depth: wallD + 8,
                topColor: Color(hex: 0x8B0000),
                frontColor: Color(hex: 0xA52A2A),
                sideColor: Color(hex: 0x6B0000)
            )
            .offset(y: -(wallH))

            // 烟囱
            IsometricBoxSimple(
                width: 8,
                height: 14,
                depth: 6,
                baseColor: Color(hex: 0x654321)
            )
            .offset(x: wallW * 0.6, y: -(wallH + 14))
        }
        .frame(width: wallW + wallD + 8, height: wallH + wallD + 30)
    }
}

/// 等距树木：可见树干 + 多层矩形树冠
struct YardTreeView: View {
    let season: Season

    var body: some View {
        let trunkW: CGFloat = 8
        let trunkH: CGFloat = 25
        let trunkD: CGFloat = 4

        ZStack(alignment: .bottom) {
            // 树干
            IsometricTrunk(
                width: trunkW,
                height: trunkH,
                depth: trunkD,
                color: Color(hex: 0x8B4513)
            )

            // 树冠（多层递缩矩形）
            IsometricCanopy(
                baseWidth: 38,
                layers: 3,
                layerHeight: 12,
                depth: 10,
                baseColor: Color(hex: season.leafColor)
            )
            .offset(y: -trunkH)
        }
        .frame(width: 48, height: trunkH + 46)
    }
}

// MARK: - 阳光公园场景（2.5D 等距）

struct ParkSceneView: View {
    @EnvironmentObject var store: AppStore
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let groundTop = h * 0.3

            ZStack {
                // 小路（等距路径）
                IsometricBox(
                    width: w * 0.8,
                    height: 8,
                    depth: 14,
                    topColor: Color(hex: 0xD2B48C),
                    frontColor: Color(hex: 0xC4A882),
                    sideColor: Color(hex: 0xB89B72)
                )
                .position(x: w * 0.5, y: groundTop + h * 0.25)

                // 树木
                ParkTreeView(season: season, size: 50)
                    .position(x: w * 0.15, y: groundTop + h * 0.08)
                ParkTreeView(season: season, size: 60)
                    .position(x: w * 0.45, y: groundTop + h * 0.05)
                ParkTreeView(season: season, size: 45)
                    .position(x: w * 0.8, y: groundTop + h * 0.12)
                ParkTreeView(season: season, size: 55)
                    .position(x: w * 0.25, y: groundTop + h * 0.38)

                // 长椅（等距）
                ParkBenchView()
                    .position(x: w * 0.6, y: groundTop + h * 0.32)

                // 花坛（等距）
                FlowerBedView()
                    .position(x: w * 0.12, y: groundTop + h * 0.35)

                // 跑步机（等距道具，点击锻炼：心情 +4 饱腹 -5）
                TreadmillView(size: min(w, h) * 0.1)
                    .position(x: w * 0.75, y: groundTop + h * 0.22)
                    .onTapGesture { store.interactSceneProp("treadmill") }
            }
        }
    }
}

/// 等距公园树木
struct ParkTreeView: View {
    let season: Season
    var size: CGFloat = 60

    var body: some View {
        let trunkW = size * 0.12
        let trunkH = size * 0.4
        let trunkD = size * 0.06

        ZStack(alignment: .bottom) {
            // 树干
            IsometricTrunk(
                width: trunkW,
                height: trunkH,
                depth: trunkD,
                color: Color(hex: 0x8B4513)
            )

            // 树冠
            IsometricCanopy(
                baseWidth: size * 0.7,
                layers: 2,
                layerHeight: size * 0.22,
                depth: size * 0.15,
                baseColor: Color(hex: season.leafColor)
            )
            .offset(y: -trunkH)
        }
        .frame(width: size * 0.85, height: trunkH + size * 0.55)
    }
}

/// 等距长椅
struct ParkBenchView: View {
    var body: some View {
        let seatW: CGFloat = 35
        let seatH: CGFloat = 5
        let seatD: CGFloat = 12
        let backH: CGFloat = 14
        let legH: CGFloat = 10

        ZStack(alignment: .bottom) {
            // 椅腿
            PixelRect(color: Color(hex: 0x654321))
                .frame(width: 3, height: legH)
                .offset(x: 2, y: 0)
            PixelRect(color: Color(hex: 0x654321))
                .frame(width: 3, height: legH)
                .offset(x: seatW - 5, y: 0)
            PixelRect(color: Color(hex: 0x553818))
                .frame(width: 3, height: legH)
                .offset(x: seatW + seatD - 5, y: -seatD * 0.2)

            // 座面
            IsometricBox(
                width: seatW,
                height: seatH,
                depth: seatD,
                topColor: Color(hex: 0xA0522D),
                frontColor: Color(hex: 0x8B4513),
                sideColor: Color(hex: 0x6B3510)
            )
            .offset(y: -legH)

            // 靠背
            IsometricBox(
                width: seatW,
                height: backH,
                depth: 3,
                topColor: Color(hex: 0xA0522D),
                frontColor: Color(hex: 0x8B4513),
                sideColor: Color(hex: 0x6B3510)
            )
            .offset(y: -(legH + seatH + seatD + backH * 0.3))
        }
        .frame(width: seatW + seatD, height: legH + seatH + seatD + backH + 5)
    }
}

/// 等距花坛
struct FlowerBedView: View {
    var body: some View {
        let bedW: CGFloat = 30
        let bedH: CGFloat = 8
        let bedD: CGFloat = 12

        ZStack(alignment: .bottom) {
            // 花坛边框（等距盒体）
            IsometricBox(
                width: bedW,
                height: bedH,
                depth: bedD,
                topColor: Color(hex: 0xA0522D),
                frontColor: Color(hex: 0x8B4513),
                sideColor: Color(hex: 0x6B3510)
            )

            // 泥土顶面
            PixelRect(color: Color(hex: 0x5C4033))
                .frame(width: bedW - 4, height: bedD - 4)
                .offset(x: 2, y: 2)

            // 花朵（等距：花茎可见）
            let flowerColors = ["#FF69B4", "#FFD700", "#FF6347", "#9370DB", "#FFA500"]
            ForEach(0..<5) { index in
                let fx = CGFloat(index % 3) * 8 + 4
                let fy = CGFloat(index / 3) * 6 - 4
                // 花茎
                PixelRect(color: Color(hex: 0x228B22))
                    .frame(width: 2, height: 8)
                    .offset(x: fx, y: -(bedH + bedD + 4))
                // 花朵
                PixelRect(color: Color(hex: flowerColors[index]))
                    .frame(width: 5, height: 5)
                    .offset(x: fx - 1.5, y: -(bedH + bedD + 12))
            }
        }
        .frame(width: bedW + bedD, height: bedH + bedD + 16)
    }
}

// MARK: - 海边沙滩场景（2.5D 等距）

struct BeachSceneView: View {
    @EnvironmentObject var store: AppStore
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let groundTop = h * 0.3

            ZStack {
                // 海浪（等距：海水在远处，可见波浪面）
                IsometricBox(
                    width: w,
                    height: 15,
                    depth: 20,
                    topColor: Color(hex: 0x4682B4).opacity(0.6),
                    frontColor: Color(hex: 0x3A6E9E).opacity(0.7),
                    sideColor: Color(hex: 0x2E5A82).opacity(0.5)
                )
                .position(x: w * 0.5, y: groundTop + 5)

                // 海浪边缘动画
                WaveShape(offset: waveOffset)
                    .fill(Color(hex: 0x87CEEB).opacity(0.5))
                    .frame(height: 12)
                    .position(x: w * 0.5, y: groundTop + 22)

                // 棕榈树（等距：弯曲树干可见）
                PalmTreeView()
                    .position(x: w * 0.18, y: groundTop + h * 0.12)
                PalmTreeView()
                    .position(x: w * 0.82, y: groundTop + h * 0.18)

                // 遮阳伞（等距：伞柄可见）
                BeachUmbrellaView()
                    .position(x: w * 0.5, y: groundTop + h * 0.3)

                // 贝壳
                ForEach(0..<4) { index in
                    PixelShellView()
                        .position(
                            x: w * (0.2 + CGFloat(index) * 0.18),
                            y: groundTop + h * (0.35 + CGFloat(index % 2) * 0.08)
                        )
                }

                // 工作台（等距道具，点击劳动：心情 +3 亲密度 +2）
                WorkDeskView(size: min(w, h) * 0.1)
                    .position(x: w * 0.3, y: groundTop + h * 0.15)
                    .onTapGesture { store.interactSceneProp("workDesk") }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    waveOffset = 15
                }
            }
        }
    }
}

/// 等距棕榈树：弯曲树干可见 + 放射叶子
struct PalmTreeView: View {
    var body: some View {
        let trunkW: CGFloat = 8
        let trunkH: CGFloat = 45
        let trunkD: CGFloat = 5

        ZStack(alignment: .bottom) {
            // 树干（等距，稍微倾斜用 offset 模拟）
            IsometricTrunk(
                width: trunkW,
                height: trunkH,
                depth: trunkD,
                color: Color(hex: 0x8B6914)
            )

            // 树干纹理（横向条纹）
            ForEach(0..<4) { i in
                PixelRect(color: Color(hex: 0x7A5A10).opacity(0.5))
                    .frame(width: trunkW, height: 2)
                    .offset(x: 0, y: -CGFloat(i) * 10 - 5)
            }

            // 棕榈叶（放射状，等距）
            ForEach(0..<6) { index in
                let angle = Double(index) * 60
                Ellipse()
                    .fill(Color(hex: 0x228B22))
                    .frame(width: 28, height: 8)
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: cos(angle * .pi / 180) * 8,
                        y: -trunkH - trunkD + sin(angle * .pi / 180) * 8 - 5
                    )
            }

            // 椰子
            PixelRect(color: Color(hex: 0x8B4513))
                .frame(width: 5, height: 5)
                .offset(x: 2, y: -trunkH - trunkD + 2)
        }
        .frame(width: trunkW + trunkD + 30, height: trunkH + trunkD + 30)
    }
}

/// 等距沙滩伞：伞柄可见 + 伞面
struct BeachUmbrellaView: View {
    var body: some View {
        let poleH: CGFloat = 40
        let poleW: CGFloat = 3
        let umbrellaR: CGFloat = 22

        ZStack(alignment: .bottom) {
            // 伞柄
            PixelRect(color: Color(hex: 0x8B4513))
                .frame(width: poleW, height: poleH)

            // 伞面（用等距盒体模拟扁平圆盘）
            IsometricBox(
                width: umbrellaR * 2,
                height: 4,
                depth: 10,
                topColor: Color(hex: 0xFF6347),
                frontColor: Color(hex: 0xE5553A),
                sideColor: Color(hex: 0xCC4830)
            )
            .offset(y: -poleH)

            // 伞面条纹
            ForEach(0..<3) { index in
                PixelRect(color: Color.white.opacity(0.3))
                    .frame(width: umbrellaR * 2 - 4, height: 2)
                    .offset(x: 2, y: -poleH + CGFloat(index) * 2 + 1)
            }

            // 伞尖
            PixelRect(color: Color(hex: 0xFFD700))
                .frame(width: 4, height: 4)
                .offset(y: -poleH - 6)
        }
        .frame(width: umbrellaR * 2 + 10, height: poleH + 12)
    }
}

// MARK: - 神秘森林场景（2.5D 等距）

struct ForestSceneView: View {
    @EnvironmentObject var store: AppStore
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
            let w = proxy.size.width
            let h = proxy.size.height
            let groundTop = h * 0.3

            ZStack {
                // 树木（等距：高大树木，可见树干）
                ForestTreeView(size: 45)
                    .position(x: w * 0.12, y: groundTop + h * 0.02)
                ForestTreeView(size: 55)
                    .position(x: w * 0.35, y: groundTop - h * 0.02)
                ForestTreeView(size: 50)
                    .position(x: w * 0.65, y: groundTop + h * 0.05)
                ForestTreeView(size: 60)
                    .position(x: w * 0.88, y: groundTop + h * 0.08)
                ForestTreeView(size: 40)
                    .position(x: w * 0.22, y: groundTop + h * 0.25)
                ForestTreeView(size: 65)
                    .position(x: w * 0.55, y: groundTop + h * 0.22)
                ForestTreeView(size: 45)
                    .position(x: w * 0.82, y: groundTop + h * 0.32)
                ForestTreeView(size: 50)
                    .position(x: w * 0.08, y: groundTop + h * 0.4)
                ForestTreeView(size: 55)
                    .position(x: w * 0.45, y: groundTop + h * 0.42)

                // 蘑菇（等距：菌柄可见）
                ForEach(0..<4) { index in
                    MushroomView()
                        .position(
                            x: w * (0.2 + CGFloat(index) * 0.2),
                            y: groundTop + h * (0.3 + CGFloat(index % 2) * 0.1)
                        )
                }

                // 学习桌（等距道具，点击学习：精力 +10 心情 +2）
                StudyDeskView(size: min(w, h) * 0.1)
                    .position(x: w * 0.72, y: groundTop + h * 0.15)
                    .onTapGesture { store.interactSceneProp("studyDesk") }

                // 魔法粒子
                if timeOfDay == .night || timeOfDay == .evening {
                    ForEach(0..<sparklePositions.count, id: \.self) { index in
                        MagicSparkleView()
                            .position(sparklePositions[index])
                            .opacity(Double.random(in: 0.3...0.8))
                    }
                }

                // 小径
                IsometricBox(
                    width: w * 0.6,
                    height: 6,
                    depth: 10,
                    topColor: Color(hex: 0x5D4E37),
                    frontColor: Color(hex: 0x4E4030),
                    sideColor: Color(hex: 0x3F3328)
                )
                .position(x: w * 0.45, y: groundTop + h * 0.2)
            }
        }
    }
}

/// 等距森林树木：高大，多层树冠
struct ForestTreeView: View {
    var size: CGFloat = 60

    var body: some View {
        let trunkW = size * 0.14
        let trunkH = size * 0.55
        let trunkD = size * 0.08

        ZStack(alignment: .bottom) {
            // 树干（更长）
            IsometricTrunk(
                width: trunkW,
                height: trunkH,
                depth: trunkD,
                color: Color(hex: 0x654321)
            )

            // 树冠（3 层，更大）
            IsometricCanopy(
                baseWidth: size * 0.75,
                layers: 3,
                layerHeight: size * 0.2,
                depth: size * 0.18,
                baseColor: Color(hex: 0x006400)
            )
            .offset(y: -trunkH)
        }
        .frame(width: size * 0.93, height: trunkH + size * 0.7)
    }
}

// MARK: - 场景缩略图（Dog Home 用）

/// 迷你等距场景缩略图，约 80x56
struct SceneThumbnailView: View {
    let scene: SceneType
    let isSelected: Bool
    let isLocked: Bool

    var body: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(baseColor)
                .frame(width: 80, height: 56)

            // 场景内容
            thumbnailContent
                .frame(width: 80, height: 56)
                .clipped()

            // 锁定遮罩
            if isLocked {
                Rectangle()
                    .fill(Color.dogScrim.opacity(0.45))
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // 选中边框
            Rectangle()
                .strokeBorder(isSelected ? Color(hex: 0x356247) : Color.clear, lineWidth: 2)
        }
        .frame(width: 80, height: 56)
    }

    private var baseColor: Color {
        switch scene {
        case .yard: return Color(hex: 0x7EC850)
        case .park: return Color(hex: 0xA8D86E)
        case .beach: return Color(hex: 0xF0D878)
        case .forest: return Color(hex: 0x3A7D44)
        }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        switch scene {
        case .yard:
            yardThumbnail
        case .park:
            parkThumbnail
        case .beach:
            beachThumbnail
        case .forest:
            forestThumbnail
        }
    }

    // MARK: 温馨小院缩略图
    private var yardThumbnail: some View {
        ZStack {
            // 地面纹理线
            PixelRect(color: Color(hex: 0x6AB840))
                .frame(width: 80, height: 1)
                .offset(y: 12)
            PixelRect(color: Color(hex: 0x6AB840))
                .frame(width: 80, height: 1)
                .offset(y: 24)

            // 小狗窝（等距盒体）
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0xA0782C))
                    .frame(width: 18, height: 12)
                    .offset(x: 0, y: 6)
                PixelRect(color: Color(hex: 0x8B6914))
                    .frame(width: 4, height: 12)
                    .offset(x: 18, y: 6)
                PixelRect(color: Color(hex: 0xC49A3C))
                    .frame(width: 22, height: 4)
                    .offset(x: 0, y: 2)
                // 门洞
                PixelRect(color: Color(hex: 0x4A3000))
                    .frame(width: 6, height: 7)
                    .offset(x: 6, y: 11)
            }
            .offset(x: -22, y: -2)

            // 小树（等距）
            ZStack(alignment: .bottom) {
                PixelRect(color: Color(hex: 0x6B4226))
                    .frame(width: 3, height: 10)
                IsometricBoxSimple(
                    width: 14, height: 8, depth: 3,
                    baseColor: Color(hex: 0x2D8B2D)
                )
                .offset(y: -10)
                IsometricBoxSimple(
                    width: 10, height: 6, depth: 2,
                    baseColor: Color(hex: 0x3AA63A)
                )
                .offset(y: -18)
            }
            .offset(x: 18, y: -4)

            // 小沙发
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0x4A6FA5))
                    .frame(width: 14, height: 6)
                    .offset(x: 0, y: 3)
                PixelRect(color: Color(hex: 0x3A5F95))
                    .frame(width: 3, height: 6)
                    .offset(x: 14, y: 3)
                PixelRect(color: Color(hex: 0x5A7FB5))
                    .frame(width: 17, height: 3)
                    .offset(x: 0, y: 0)
                // 靠背
                PixelRect(color: Color(hex: 0x3A5F95))
                    .frame(width: 14, height: 3)
                    .offset(x: 0, y: -3)
            }
            .offset(x: -8, y: 12)
        }
    }

    // MARK: 阳光公园缩略图
    private var parkThumbnail: some View {
        ZStack {
            // 地面纹理
            PixelRect(color: Color(hex: 0x98C85E))
                .frame(width: 80, height: 1)
                .offset(y: 14)
            PixelRect(color: Color(hex: 0x98C85E))
                .frame(width: 80, height: 1)
                .offset(y: 28)

            // 小路
            PixelRect(color: Color(hex: 0xD4C49A))
                .frame(width: 12, height: 56)
                .offset(x: 0)

            // 跑步机（等距盒体）
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0x808080))
                    .frame(width: 16, height: 8)
                    .offset(x: 0, y: 4)
                PixelRect(color: Color(hex: 0x606060))
                    .frame(width: 3, height: 8)
                    .offset(x: 16, y: 4)
                PixelRect(color: Color(hex: 0xA0A0A0))
                    .frame(width: 19, height: 4)
                    .offset(x: 0, y: 0)
                // 扶手
                PixelRect(color: Color(hex: 0x505050))
                    .frame(width: 2, height: 8)
                    .offset(x: 16, y: -4)
                // 跑带纹理
                PixelRect(color: Color(hex: 0x404040))
                    .frame(width: 12, height: 1)
                    .offset(x: 2, y: 7)
            }
            .offset(x: -28, y: -4)

            // 等距长椅
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0x8B6914))
                    .frame(width: 14, height: 5)
                    .offset(x: 0, y: 3)
                PixelRect(color: Color(hex: 0x6B4226))
                    .frame(width: 3, height: 5)
                    .offset(x: 14, y: 3)
                PixelRect(color: Color(hex: 0xA0782C))
                    .frame(width: 17, height: 3)
                    .offset(x: 0, y: 0)
                // 靠背
                PixelRect(color: Color(hex: 0x6B4226))
                    .frame(width: 14, height: 4)
                    .offset(x: 0, y: -4)
            }
            .offset(x: 14, y: 6)

            // 小花
            PixelRect(color: Color(hex: 0xFF6B8A))
                .frame(width: 4, height: 4)
                .offset(x: -10, y: 16)
            PixelRect(color: Color(hex: 0xFFD700))
                .frame(width: 3, height: 3)
                .offset(x: 26, y: 18)
        }
    }

    // MARK: 海边沙滩缩略图
    private var beachThumbnail: some View {
        ZStack {
            // 海水条
            PixelRect(color: Color(hex: 0x4AAFE0))
                .frame(width: 80, height: 10)
                .offset(y: -23)
            // 海浪边
            PixelRect(color: Color(hex: 0x6BC5F0))
                .frame(width: 80, height: 3)
                .offset(y: -16)

            // 沙滩纹理
            PixelRect(color: Color(hex: 0xE0C868))
                .frame(width: 80, height: 1)
                .offset(y: 4)
            PixelRect(color: Color(hex: 0xE0C868))
                .frame(width: 80, height: 1)
                .offset(y: 16)

            // 棕榈树
            ZStack(alignment: .bottom) {
                // 弯曲树干
                PixelRect(color: Color(hex: 0x8B6914))
                    .frame(width: 3, height: 18)
                    .offset(x: 1, y: 0)
                PixelRect(color: Color(hex: 0x8B6914))
                    .frame(width: 3, height: 6)
                    .offset(x: -1, y: -16)
                // 棕榈叶
                PixelRect(color: Color(hex: 0x2D8B2D))
                    .frame(width: 16, height: 4)
                    .offset(x: -4, y: -22)
                PixelRect(color: Color(hex: 0x3AA63A))
                    .frame(width: 12, height: 3)
                    .offset(x: 2, y: -20)
                PixelRect(color: Color(hex: 0x228B22))
                    .frame(width: 10, height: 3)
                    .offset(x: -6, y: -19)
            }
            .offset(x: -20, y: 2)

            // 工作台（小等距盒体）
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0x5C4033))
                    .frame(width: 14, height: 7)
                    .offset(x: 0, y: 3)
                PixelRect(color: Color(hex: 0x4A3020))
                    .frame(width: 3, height: 7)
                    .offset(x: 14, y: 3)
                PixelRect(color: Color(hex: 0x7A5A43))
                    .frame(width: 17, height: 3)
                    .offset(x: 0, y: 0)
            }
            .offset(x: 12, y: 2)

            // 沙滩伞
            ZStack {
                PixelRect(color: Color(hex: 0x8B6914))
                    .frame(width: 2, height: 12)
                PixelRect(color: Color(hex: 0xFF4444))
                    .frame(width: 12, height: 3)
                    .offset(y: -6)
                PixelRect(color: Color(hex: 0xFFFFFF))
                    .frame(width: 4, height: 3)
                    .offset(x: -2, y: -6)
                PixelRect(color: Color(hex: 0xFFFFFF))
                    .frame(width: 4, height: 3)
                    .offset(x: 4, y: -6)
            }
            .offset(x: 24, y: -4)

            // 贝壳
            PixelRect(color: Color(hex: 0xFFB6C1))
                .frame(width: 3, height: 2)
                .offset(x: -6, y: 18)
        }
    }

    // MARK: 神秘森林缩略图
    private var forestThumbnail: some View {
        ZStack {
            // 地面纹理
            PixelRect(color: Color(hex: 0x2D6B34))
                .frame(width: 80, height: 1)
                .offset(y: 10)
            PixelRect(color: Color(hex: 0x2D6B34))
                .frame(width: 80, height: 1)
                .offset(y: 22)

            // 大树（等距，多层树冠）
            ZStack(alignment: .bottom) {
                PixelRect(color: Color(hex: 0x4A3020))
                    .frame(width: 5, height: 16)
                IsometricBoxSimple(
                    width: 22, height: 10, depth: 5,
                    baseColor: Color(hex: 0x006400)
                )
                .offset(y: -14)
                IsometricBoxSimple(
                    width: 16, height: 8, depth: 4,
                    baseColor: Color(hex: 0x228B22)
                )
                .offset(y: -24)
                IsometricBoxSimple(
                    width: 10, height: 6, depth: 3,
                    baseColor: Color(hex: 0x006400)
                )
                .offset(y: -32)
            }
            .offset(x: -16, y: 4)

            // 小树
            ZStack(alignment: .bottom) {
                PixelRect(color: Color(hex: 0x4A3020))
                    .frame(width: 3, height: 8)
                IsometricBoxSimple(
                    width: 10, height: 6, depth: 3,
                    baseColor: Color(hex: 0x2D8B2D)
                )
                .offset(y: -8)
            }
            .offset(x: 22, y: 8)

            // 学习桌
            ZStack(alignment: .topLeading) {
                PixelRect(color: Color(hex: 0x6B4226))
                    .frame(width: 12, height: 6)
                    .offset(x: 0, y: 3)
                PixelRect(color: Color(hex: 0x5A3216))
                    .frame(width: 3, height: 6)
                    .offset(x: 12, y: 3)
                PixelRect(color: Color(hex: 0x8B5A3C))
                    .frame(width: 15, height: 3)
                    .offset(x: 0, y: 0)
                // 小书架
                PixelRect(color: Color(hex: 0x4A3020))
                    .frame(width: 5, height: 5)
                    .offset(x: 2, y: -5)
                PixelRect(color: Color(hex: 0xFF6B6B))
                    .frame(width: 3, height: 3)
                    .offset(x: 3, y: -4)
            }
            .offset(x: 6, y: 6)

            // 蘑菇
            ZStack {
                PixelRect(color: Color(hex: 0xD4A574))
                    .frame(width: 2, height: 4)
                PixelRect(color: Color(hex: 0xFF4444))
                    .frame(width: 6, height: 3)
                    .offset(y: -3)
                PixelRect(color: Color(hex: 0xFFFFFF))
                    .frame(width: 2, height: 1)
                    .offset(x: -1, y: -3)
            }
            .offset(x: 28, y: 16)
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
                            y: CGFloat.random(in: 30...100)
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
                    PixelRect(color: Color(hex: 0x4682B4)).frame(width: 2, height: 15)
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

/// 等距花朵：可见花茎
struct PixelFlowerView: View {
    let color: String

    var body: some View {
        ZStack(alignment: .bottom) {
            // 花茎
            PixelRect(color: Color(hex: 0x228B22))
                .frame(width: 2, height: 10)

            // 花瓣
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 5, height: 5)
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 5) * 4,
                        y: sin(Double(index) * .pi * 2 / 5) * 4 - 12
                    )
            }

            // 花心
            Circle()
                .fill(Color.yellow)
                .frame(width: 3, height: 3)
                .offset(y: -12)
        }
        .frame(width: 14, height: 22)
    }
}

struct PixelShellView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFFC0CB))
                .frame(width: 10, height: 10)
            Circle()
                .fill(Color(hex: 0xFFB6C1))
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

/// 等距蘑菇：菌柄可见
struct MushroomView: View {
    var body: some View {
        let capW: CGFloat = 16
        let capH: CGFloat = 6
        let capD: CGFloat = 6
        let stemH: CGFloat = 10
        let stemW: CGFloat = 5

        ZStack(alignment: .bottom) {
            // 菌柄
            IsometricTrunk(
                width: stemW,
                height: stemH,
                depth: 3,
                color: Color(hex: 0xF5F5DC)
            )

            // 菌盖
            IsometricBox(
                width: capW,
                height: capH,
                depth: capD,
                topColor: Color(hex: 0xFF0000),
                frontColor: Color(hex: 0xCC0000),
                sideColor: Color(hex: 0x990000)
            )
            .offset(y: -stemH)

            // 白点
            PixelRect(color: Color.white)
                .frame(width: 3, height: 3)
                .offset(x: 3, y: -(stemH + capH + capD - 2))
            PixelRect(color: Color.white)
                .frame(width: 3, height: 3)
                .offset(x: 9, y: -(stemH + capH + capD - 4))
        }
        .frame(width: capW + capD, height: stemH + capH + capD + 3)
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

