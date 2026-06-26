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

    // Text
    static let dogTextPrimary = Color(hex: 0x26382B)
    static let dogTextSecondary = Color(hex: 0x356247)
    static let dogTextTertiary = Color(hex: 0x6B715F)

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

// MARK: - CGPoint helpers

extension CGPoint {
    func applying(offset: CGSize) -> CGPoint {
        CGPoint(x: x + offset.width, y: y + offset.height)
    }
}
