import SwiftUI

/// How each level looks on screen (Figma: 앱 / 공통 · 컴포넌트 › StatusBadge).
/// Kept out of the model so `ValleyLevel` does not depend on SwiftUI.
///
/// Safety rule: `.unknown` must never look like `.safe`. It differs in text,
/// color, and icon, so it is clear even without color.
extension ValleyLevel {
    /// Korean label shown in the badge.
    var title: String {
        switch self {
        case .safe: "안전"
        case .caution: "주의"
        case .danger: "위험"
        case .evacuate: "대피"
        case .unknown: "판정 불가"
        }
    }

    /// Badge fill. Values are sampled from the Figma screen (approximate).
    var badgeBackground: Color {
        switch self {
        case .safe: Color(rgb: 0x489453)
        case .caution: Color(rgb: 0xF4D159)
        case .danger: Color(rgb: 0xDD7D33)
        case .evacuate: Color(rgb: 0xB73B31)
        case .unknown: Color(rgb: 0xD6D6D6)
        }
    }

    /// Text and icon color on top of `badgeBackground`. Dark on light fills.
    var badgeForeground: Color {
        switch self {
        case .caution, .unknown: Color(rgb: 0x1C1C1E)
        case .safe, .danger, .evacuate: .white
        }
    }

    /// SF Symbol shown before the title, or `nil` for none.
    var badgeSymbol: String? {
        switch self {
        case .unknown: "questionmark.circle"
        case .safe, .caution, .danger, .evacuate: nil
        }
    }
}

private extension Color {
    /// `Color(rgb: 0x489453)`, written like a hex code from a design tool.
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
