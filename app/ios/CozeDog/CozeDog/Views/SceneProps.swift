import SwiftUI

// MARK: - 狗窝

/// 等距狗窝：木色盒体 + 斜屋顶 + 拱形门洞
struct DogHouseView: View {
    let size: CGFloat  // 基准尺寸（约 dogSize * 1.5）

    var body: some View {
        let w = size * 1.2
        let h = size * 0.8
        let d = size * 0.3

        ZStack(alignment: .bottom) {
            // 主体（木色盒体）
            IsometricBox(
                width: w,
                height: h,
                depth: d,
                topColor: Color(hex: 0xA0782C),
                frontColor: Color(hex: 0x8B6914),
                sideColor: Color(hex: 0x6B5010)
            )

            // 屋顶（比主体宽，深色）
            let roofW = w + d + size * 0.15
            let roofH = size * 0.12
            let roofD = d + size * 0.1
            IsometricBox(
                width: roofW,
                height: roofH,
                depth: roofD,
                topColor: Color(hex: 0x6B3A1A),
                frontColor: Color(hex: 0x5C3015),
                sideColor: Color(hex: 0x4A2510)
            )
            .offset(y: -(h + d))

            // 门洞（正面深色矩形）
            PixelRect(color: Color(hex: 0x2A1A08))
                .frame(width: size * 0.35, height: size * 0.45)
                .offset(x: w * 0.25, y: -(size * 0.45))
        }
        .frame(width: w + d + size * 0.15, height: h + d + size * 0.12 + size * 0.1)
    }
}

// MARK: - 跑步机

/// 等距跑步机：扁平底座 + 跑带 + 扶手
struct TreadmillView: View {
    let size: CGFloat  // 约 dogSize * 1.3

    var body: some View {
        let w = size * 1.1
        let h = size * 0.25
        let d = size * 0.5
        let handleH = size * 0.7

        ZStack(alignment: .bottom) {
            // 底座
            IsometricBox(
                width: w,
                height: h,
                depth: d,
                topColor: Color(hex: 0x909090),
                frontColor: Color(hex: 0x707070),
                sideColor: Color(hex: 0x585858)
            )

            // 跑带（顶面深色条纹）
            PixelRect(color: Color(hex: 0x3A3A3A))
                .frame(width: w * 0.75, height: d * 0.6)
                .offset(x: w * 0.05, y: size * 0.02)

            // 左扶手
            PixelRect(color: Color(hex: 0x505050))
                .frame(width: size * 0.06, height: handleH)
                .offset(x: 0, y: -handleH)

            // 右扶手
            PixelRect(color: Color(hex: 0x505050))
                .frame(width: size * 0.06, height: handleH)
                .offset(x: w + d - size * 0.06, y: -handleH)

            // 扶手横杆
            PixelRect(color: Color(hex: 0x606060))
                .frame(width: w + d, height: size * 0.05)
                .offset(y: -(handleH - size * 0.03))

            // 控制面板（小矩形）
            PixelRect(color: Color(hex: 0x2ECC71))
                .frame(width: size * 0.2, height: size * 0.12)
                .offset(x: w * 0.3, y: -(handleH * 0.8))
        }
        .frame(width: w + d, height: h + d + handleH)
    }
}

// MARK: - 学习桌

/// 等距学习桌：桌面 + 桌腿 + 小台灯/书本
struct StudyDeskView: View {
    let size: CGFloat  // 约 dogSize * 1.2

    var body: some View {
        let tableW = size * 1.0
        let tableH = size * 0.08
        let tableD = size * 0.45
        let legH = size * 0.5
        let legW = size * 0.06

        ZStack(alignment: .bottom) {
            // 桌腿（4 根）
            // 左前腿
            PixelRect(color: Color(hex: 0x5A3518))
                .frame(width: legW, height: legH)
                .offset(x: legW, y: 0)

            // 右前腿
            PixelRect(color: Color(hex: 0x5A3518))
                .frame(width: legW, height: legH)
                .offset(x: tableW - legW * 2, y: 0)

            // 右后腿（侧面可见）
            PixelRect(color: Color(hex: 0x4A2A12))
                .frame(width: legW, height: legH)
                .offset(x: tableW + tableD - legW * 2, y: -tableD * 0.15)

            // 桌面
            IsometricBox(
                width: tableW,
                height: tableH,
                depth: tableD,
                topColor: Color(hex: 0x8B6236),
                frontColor: Color(hex: 0x6B4226),
                sideColor: Color(hex: 0x55341E)
            )
            .offset(y: -legH)

            // 小台灯（桌面右侧）
            // 灯座
            PixelRect(color: Color(hex: 0x404040))
                .frame(width: size * 0.1, height: size * 0.04)
                .offset(x: tableW * 0.65, y: -(legH + tableH + tableD + size * 0.04))

            // 灯杆
            PixelRect(color: Color(hex: 0x505050))
                .frame(width: size * 0.03, height: size * 0.18)
                .offset(x: tableW * 0.68, y: -(legH + tableH + tableD + size * 0.22))

            // 灯罩
            PixelRect(color: Color(hex: 0xF4D03F))
                .frame(width: size * 0.14, height: size * 0.06)
                .offset(x: tableW * 0.63, y: -(legH + tableH + tableD + size * 0.34))

            // 书本（桌面左侧）
            PixelRect(color: Color(hex: 0x3498DB))
                .frame(width: size * 0.18, height: size * 0.04)
                .offset(x: tableW * 0.2, y: -(legH + tableH + tableD + size * 0.02))

            PixelRect(color: Color(hex: 0xE74C3C))
                .frame(width: size * 0.15, height: size * 0.04)
                .offset(x: tableW * 0.22, y: -(legH + tableH + tableD + size * 0.06))
        }
        .frame(width: tableW + tableD, height: legH + tableH + tableD + size * 0.38)
    }
}

// MARK: - 工作台

/// 等距工作台：厚桌面 + 粗腿 + 工具装饰
struct WorkDeskView: View {
    let size: CGFloat  // 约 dogSize * 1.2

    var body: some View {
        let tableW = size * 1.0
        let tableH = size * 0.1
        let tableD = size * 0.45
        let legH = size * 0.5
        let legW = size * 0.08

        ZStack(alignment: .bottom) {
            // 桌腿（粗腿）
            PixelRect(color: Color(hex: 0x4A3020))
                .frame(width: legW, height: legH)
                .offset(x: legW * 0.5, y: 0)

            PixelRect(color: Color(hex: 0x4A3020))
                .frame(width: legW, height: legH)
                .offset(x: tableW - legW * 1.5, y: 0)

            PixelRect(color: Color(hex: 0x3A2518))
                .frame(width: legW, height: legH)
                .offset(x: tableW + tableD - legW * 1.5, y: -tableD * 0.15)

            // 桌面（深木色）
            IsometricBox(
                width: tableW,
                height: tableH,
                depth: tableD,
                topColor: Color(hex: 0x7A5A3A),
                frontColor: Color(hex: 0x5C4033),
                sideColor: Color(hex: 0x483228)
            )
            .offset(y: -legH)

            // 工具箱（桌面上左侧）
            IsometricBoxSimple(
                width: size * 0.2,
                height: size * 0.12,
                depth: size * 0.08,
                baseColor: Color(hex: 0xE74C3C)
            )
            .offset(x: tableW * 0.1, y: -(legH + tableH + tableD + size * 0.12))

            // 锤子（桌面上右侧）
            // 锤柄
            PixelRect(color: Color(hex: 0x8B6914))
                .frame(width: size * 0.03, height: size * 0.16)
                .offset(x: tableW * 0.7, y: -(legH + tableH + tableD + size * 0.08))

            // 锤头
            PixelRect(color: Color(hex: 0x808080))
                .frame(width: size * 0.1, height: size * 0.05)
                .offset(x: tableW * 0.67, y: -(legH + tableH + tableD + size * 0.2))

            // 齿轮装饰（桌面中间）
            PixelRect(color: Color(hex: 0xA0A0A0))
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: tableW * 0.45, y: -(legH + tableH + tableD + size * 0.05))
        }
        .frame(width: tableW + tableD, height: legH + tableH + tableD + size * 0.25)
    }
}

// MARK: - 沙发

/// 等距沙发：底座 + 靠背 + 扶手 + 靠垫
struct SofaView: View {
    let size: CGFloat  // 约 dogSize * 1.4

    var body: some View {
        let seatW = size * 1.2
        let seatH = size * 0.3
        let seatD = size * 0.5
        let backH = size * 0.4
        let armW = size * 0.12

        ZStack(alignment: .bottom) {
            // 沙发腿（4 个小方块）
            PixelRect(color: Color(hex: 0x4A3020))
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: size * 0.06, y: 0)

            PixelRect(color: Color(hex: 0x4A3020))
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: seatW - size * 0.06, y: 0)

            // 座垫
            IsometricBox(
                width: seatW,
                height: seatH,
                depth: seatD,
                topColor: Color(hex: 0x5B86C5),
                frontColor: Color(hex: 0x4A6FA5),
                sideColor: Color(hex: 0x3A5A8A)
            )
            .offset(y: -size * 0.06)

            // 靠背
            IsometricBox(
                width: seatW,
                height: backH,
                depth: size * 0.1,
                topColor: Color(hex: 0x5B86C5),
                frontColor: Color(hex: 0x4A6FA5),
                sideColor: Color(hex: 0x3A5A8A)
            )
            .offset(y: -(size * 0.06 + seatH + seatD + backH * 0.3))

            // 左扶手
            IsometricBoxSimple(
                width: armW,
                height: seatH + size * 0.15,
                depth: seatD,
                baseColor: Color(hex: 0x4A6FA5)
            )
            .offset(x: -armW, y: -(size * 0.06))

            // 右扶手
            IsometricBoxSimple(
                width: armW,
                height: seatH + size * 0.15,
                depth: seatD,
                baseColor: Color(hex: 0x4A6FA5)
            )
            .offset(x: seatW + seatD, y: -(size * 0.06))

            // 靠垫（2 个）
            PixelRect(color: Color(hex: 0x6B9BD2))
                .frame(width: size * 0.25, height: size * 0.2)
                .offset(x: seatW * 0.2, y: -(size * 0.06 + seatH + seatD + size * 0.1))

            PixelRect(color: Color(hex: 0x6B9BD2))
                .frame(width: size * 0.25, height: size * 0.2)
                .offset(x: seatW * 0.6, y: -(size * 0.06 + seatH + seatD + size * 0.1))
        }
        .frame(width: seatW + seatD + armW, height: size * 0.06 + seatH + seatD + backH + size * 0.15)
    }
}
