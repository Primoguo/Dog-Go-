import SwiftUI

// MARK: - 等距盒体（2.5D 像素风格）

/// 三面等距盒体：顶面 + 正面 + 侧面
struct IsometricBox: View {
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat  // 侧面深度（厚度）
    let topColor: Color
    let frontColor: Color
    let sideColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 正面（最前面的矩形）
            PixelRect(color: frontColor)
                .frame(width: width, height: height)
                .offset(x: 0, y: depth)

            // 侧面（右侧面）
            PixelRect(color: sideColor)
                .frame(width: depth, height: height)
                .offset(x: width, y: depth)

            // 顶面（顶部矩形）
            PixelRect(color: topColor)
                .frame(width: width + depth, height: depth)
                .offset(x: 0, y: 0)
        }
        .frame(
            width: width + depth,
            height: height + depth
        )
    }
}

/// 简化等距盒体：只给一个基础色，自动计算三面明暗
struct IsometricBoxSimple: View {
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat
    let baseColor: Color

    var body: some View {
        IsometricBox(
            width: width,
            height: height,
            depth: depth,
            topColor: baseColor.darker(by: -0.15),  // 顶面更亮
            frontColor: baseColor,
            sideColor: baseColor.darker(by: 0.25)    // 侧面更暗
        )
    }
}

// MARK: - 等距树干

/// 等距树干：正面 + 侧面可见
struct IsometricTrunk: View {
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 正面
            PixelRect(color: color)
                .frame(width: width, height: height)
                .offset(x: 0, y: depth)

            // 侧面
            PixelRect(color: color.darker(by: 0.3))
                .frame(width: depth, height: height)
                .offset(x: width, y: depth)
        }
        .frame(width: width + depth, height: height + depth)
    }
}

// MARK: - 等距树冠（多层矩形堆叠）

/// 等距树冠：用 2-3 层递缩矩形模拟
struct IsometricCanopy: View {
    let baseWidth: CGFloat
    let layers: Int  // 2 或 3
    let layerHeight: CGFloat
    let depth: CGFloat
    let baseColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(0..<layers, id: \.self) { i in
                let shrink = CGFloat(i) * (baseWidth * 0.2)
                let layerWidth = baseWidth - shrink
                let yOffset = -CGFloat(i) * layerHeight * 0.7
                let layerColor = baseColor.darker(by: -CGFloat(i) * 0.08)  // 越往上越亮

                IsometricBoxSimple(
                    width: layerWidth,
                    height: layerHeight,
                    depth: depth * (1.0 - CGFloat(i) * 0.2),
                    baseColor: layerColor
                )
                .offset(y: yOffset)
            }
        }
    }
}

// MARK: - Color.darker(by:) 扩展

extension Color {
    /// 调整颜色明暗。percent > 0 变暗，< 0 变亮
    func darker(by percent: CGFloat) -> Color {
        // 提取 RGBA 分量
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let factor = 1.0 - percent
        return Color(
            .sRGB,
            red: Double(max(0, min(1, r * factor))),
            green: Double(max(0, min(1, g * factor))),
            blue: Double(max(0, min(1, b * factor))),
            opacity: Double(a)
        )
        #else
        return self
        #endif
    }
}

// MARK: - 等距地面纹理线

/// 地面斜线纹理，增加等距感
struct IsometricGroundLines: View {
    let color: Color
    let spacing: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 水平等距线（模拟地面网格）
                let lineCount = Int(proxy.size.height / spacing) + 2
                ForEach(0..<lineCount, id: \.self) { i in
                    PixelRect(color: color.opacity(0.15))
                        .frame(width: proxy.size.width, height: lineWidth)
                        .position(
                            x: proxy.size.width / 2,
                            y: CGFloat(i) * spacing
                        )
                }
            }
        }
    }
}
