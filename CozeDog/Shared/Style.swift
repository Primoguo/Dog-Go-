import SwiftUI

extension Text {
    func eyebrowStyle() -> some View {
        self
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.none)
    }
}

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

extension CGPoint {
    func applying(offset: CGSize) -> CGPoint {
        CGPoint(x: x + offset.width, y: y + offset.height)
    }
}
