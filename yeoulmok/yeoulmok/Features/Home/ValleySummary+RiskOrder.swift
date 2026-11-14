import Foundation

/// Home list order (Figma 01 v2 API memo): 대피 › 위험 › 주의 › 판정 불가 › 안전,
/// then by name. The most urgent valley comes first, and "unknown" sits above
/// "safe" so it is not lost among safe valleys.
extension ValleyLevel {
    /// Lower comes first in the home list.
    nonisolated var homeRank: Int {
        switch self {
        case .evacuate: 0
        case .danger: 1
        case .caution: 2
        case .unknown: 3
        case .safe: 4
        }
    }
}

extension Array where Element == ValleySummary {
    /// Sorted for the home list: by `homeRank`, then by Korean name, then by id
    /// (so the order never changes between refreshes when names are equal).
    nonisolated func sortedForHome() -> [ValleySummary] {
        sorted { lhs, rhs in
            if lhs.level.homeRank != rhs.level.homeRank {
                return lhs.level.homeRank < rhs.level.homeRank
            }
            let byName = lhs.name.compare(rhs.name, locale: Locale(identifier: "ko_KR"))
            if byName != .orderedSame {
                return byName == .orderedAscending
            }
            return lhs.id < rhs.id
        }
    }
}
