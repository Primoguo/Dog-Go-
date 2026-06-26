import SwiftUI

// MARK: - Color(hex: UInt) — the single color initializer

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Semantic color constants

extension Color {
    // Brand
    static let dogBrand = Color(hex: 0x356247)
    static let dogBrandDark = Color(hex: 0x1E3D2C)

    // Functional
    static let dogSuccess = Color(hex: 0x5D8B6A)
    static let dogBorder = Color(hex: 0x7C9B64)
    static let dogBorderLight = Color(hex: 0x9BB985)

    // Backgrounds
    static let dogBgPage = Color(hex: 0xF2F7EE)
    static let dogBgWarm = Color(hex: 0xFFF7EC)
    static let dogBgCool = Color(hex: 0xEDF5FB)
    static let dogBgPanel = Color(hex: 0xFFF8E8)
    static let dogBgTexture = Color(hex: 0xEAF1DA)
    static let dogBgCard = Color(hex: 0xF6E9C8)
    static let dogBgScene = Color(hex: 0xDCEBCB)

    // Text
    static let dogTextPrimary = Color(hex: 0x26382B)
    static let dogTextSecondary = Color(hex: 0x356247)
    static let dogTextTertiary = Color(hex: 0x6B715F)
    static let dogTextPlaceholder = Color(hex: 0x8B8B8B)
    static let dogSecondaryButtonText = Color(hex: 0x3E3323)
    static let dogTextOnDark = Color(hex: 0xFFF8E8) // 深色背景上的浅色文本

    // Danger (放弃/危险操作)
    static let dogDanger = Color(hex: 0x8B6A5D) // 放弃按钮文本/边框、未完成指示
    static let dogDangerBg = Color(hex: 0xF5E5E0) // 放弃按钮背景

    // Status (状态色 — §2.6)
    static let dogError = Color(hex: 0xC65B44) // 错误/健康红
    static let dogInfo = Color(hex: 0x4C7FA6) // 信息/精力蓝

    // Disabled (禁用态 — §5.2)
    static let dogDisabledBg = Color(hex: 0xD5D8C7) // 禁用按钮背景
    static let dogDisabledBorder = Color(hex: 0xA4AA96) // 禁用按钮边框

    // Progress & Meter (进度条/计量条 — §5.4/§5.5/§5.8)
    static let dogProgressBarTrack = Color(hex: 0xE8E0D0) // 进度条轨道
    static let dogRhythmEmpty = Color(hex: 0xD9CFB9) // 节奏/计量空白块填充
    static let dogRhythmEmptyBorder = Color(hex: 0xBCA98B) // 节奏/计量空白块边框

    // Overlay
    static let dogScrim = Color(hex: 0x26382B) // 遮罩/半透明覆盖层

    // Accent
    static let dogAccent = Color(hex: 0xC69A3E)
    static let dogAccentBright = Color(hex: 0xFFF1B8)
    static let dogAccentLight = Color(hex: 0xC7A76D)

    // Pixel shadow
    static let dogPixelShadow = Color(hex: 0x3E4F38)
}

// MARK: - Text helpers

extension Text {
    func eyebrowStyle() -> some View {
        self
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.dogTextTertiary)
            .textCase(.none)
    }
}

// MARK: - View text helpers

extension View {
    func secondaryText() -> some View { foregroundStyle(Color.dogTextSecondary) }
    func tertiaryText() -> some View { foregroundStyle(Color.dogTextTertiary) }
}

// MARK: - Pixel card style ViewModifier

struct PixelCardStyle: ViewModifier {
    var bg: Color = .dogBgPanel
    var borderColor: Color = .dogBorder
    var borderWidth: CGFloat = 2
    var padding: CGFloat = 12
    var shadowOffset: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    bg
                    PixelTinyGrid(colorA: Color(hex: 0xF4E6C6, alpha: 0.34), colorB: .clear, tile: 14)
                }
            }
            .overlay { Rectangle().stroke(borderColor, lineWidth: borderWidth) }
            .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: shadowOffset, y: shadowOffset)
    }
}

extension View {
    func pixelCardStyle(
        bg: Color = .dogBgPanel,
        borderColor: Color = .dogBorder,
        borderWidth: CGFloat = 2,
        padding: CGFloat = 12,
        shadowOffset: CGFloat = 4
    ) -> some View {
        modifier(PixelCardStyle(bg: bg, borderColor: borderColor, borderWidth: borderWidth, padding: padding, shadowOffset: shadowOffset))
    }
}

// MARK: - 时间格式化工具

/// 将秒数格式化为 MM:SS 格式
func formattedTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let secs = seconds % 60
    return String(format: "%02d:%02d", minutes, secs)
}

/// 将分钟数格式化为中文时长（如 "30分钟"、"1小时20分钟"）
func formatMinutes(_ minutes: Int) -> String {
    if minutes < 60 {
        return "\(minutes)分钟"
    } else {
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)小时"
        } else {
            return "\(hours)小时\(mins)分钟"
        }
    }
}

/// 将秒数格式化为中文时长
func formatDuration(_ seconds: Int) -> String {
    formatMinutes(seconds / 60)
}

// MARK: - CGPoint helpers

extension CGPoint {
    func applying(offset: CGSize) -> CGPoint {
        CGPoint(x: x + offset.width, y: y + offset.height)
    }
}
