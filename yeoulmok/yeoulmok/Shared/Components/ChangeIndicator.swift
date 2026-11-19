import SwiftUI

/// ↑ / ↓ / → next to a 30-minute water level change (APP-HOME-05 #59, reused in #63).
/// Rising water is drawn in the warning color. Nothing is shown when the value is missing.
struct ChangeIndicator: View {
    let change: Double?

    var body: some View {
        if let direction = ChangeDirection(change) {
            Image(systemName: direction.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(direction == .rising ? ValleyLevel.danger.badgeBackground : Color.secondary)
                .accessibilityLabel(direction.title)
        }
    }
}

nonisolated enum ChangeDirection: Equatable {
    case rising, falling, steady

    /// Changes smaller than half a centimeter count as steady.
    static let steadyBand = 0.005

    init?(_ change: Double?) {
        guard let change else { return nil }
        if change > Self.steadyBand { self = .rising }
        else if change < -Self.steadyBand { self = .falling }
        else { self = .steady }
    }

    var symbol: String {
        switch self {
        case .rising: "arrow.up"
        case .falling: "arrow.down"
        case .steady: "arrow.right"
        }
    }

    var title: String {
        switch self {
        case .rising: "오르는 중"
        case .falling: "내리는 중"
        case .steady: "변화 없음"
        }
    }
}
