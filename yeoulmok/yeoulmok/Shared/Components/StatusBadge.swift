import SwiftUI

/// Capsule badge showing a valley's level (APP-COM-02). Use this everywhere
/// a level is shown, so all screens look the same.
///
///     StatusBadge(level: valley.level)                 // list rows
///     StatusBadge(level: detail.level, size: .large)   // cards, detail header
struct StatusBadge: View {
    enum Size {
        /// List rows (Figma: small badge).
        case small
        /// Cards and the detail header (Figma: large badge).
        case large
    }

    let level: ValleyLevel
    var size: Size = .small

    var body: some View {
        HStack(spacing: 4) {
            if let symbol = level.badgeSymbol {
                Image(systemName: symbol)
            }
            Text(level.title)
        }
        .font(font)
        .foregroundStyle(level.badgeForeground)
        .padding(.horizontal, size == .small ? 8 : 12)
        .padding(.vertical, size == .small ? 3 : 6)
        .background(level.badgeBackground, in: Capsule())
        // Read as one element ("상태: 판정 불가") instead of icon + text separately.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// What VoiceOver reads.
    var accessibilityText: String {
        "상태: \(level.title)"
    }

    /// Text styles (not fixed sizes), so the badge grows with the user's text size setting.
    private var font: Font {
        switch size {
        case .small: .caption.weight(.semibold)
        case .large: .subheadline.weight(.bold)
        }
    }
}

#Preview("All levels") {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            ForEach(ValleyLevel.allCases, id: \.self) { StatusBadge(level: $0) }
        }
        HStack {
            ForEach(ValleyLevel.allCases.prefix(3), id: \.self) { StatusBadge(level: $0, size: .large) }
        }
        HStack {
            ForEach(ValleyLevel.allCases.suffix(2), id: \.self) { StatusBadge(level: $0, size: .large) }
        }
    }
    .padding()
}
