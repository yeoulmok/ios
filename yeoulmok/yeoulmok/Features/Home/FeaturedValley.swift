import CoreLocation

/// The one valley shown large above the subscribed list on home (APP-HOME-05, #59).
nonisolated struct FeaturedValley: Equatable {
    /// Why this valley was picked, shown above its name.
    enum Reason: Equatable {
        /// A subscribed valley at 주의 or higher: the highest level wins.
        case mostUrgent
        /// No subscribed valley at 주의 or higher: the closest one.
        case closest
        /// No location: the first valley of the home list.
        case firstInList

        /// Temporary wording until QA (not in Figma).
        var title: String {
            switch self {
            case .mostUrgent: "가장 위험한 구독 계곡"
            case .closest: "가장 가까운 구독 계곡"
            case .firstInList: "구독한 계곡"
            }
        }
    }

    let valley: ValleySummary
    let reason: Reason
    /// From the user, when the location is known.
    let distanceMeters: Double?

    /// Levels that count as "주의 이상". `.unknown` is not one of them: it is not a
    /// higher risk, it is missing data (it still ranks above 안전 in rule 3).
    static let urgentLevels: Set<ValleyLevel> = [.caution, .danger, .evacuate]

    /// The rule decided on 2026-11-19 (issue #59):
    /// 1. A subscribed valley at 주의 or higher: the highest level
    ///    (same level: the closer one; no location: home list order).
    /// 2. Otherwise the closest subscribed valley.
    /// 3. Without a location, the top of the home list (`sortedForHome`:
    ///    판정 불가 sits above 안전).
    /// `nil` only when nothing is subscribed.
    static func pick(from subscribed: [ValleySummary], near location: CLLocationCoordinate2D?) -> FeaturedValley? {
        guard !subscribed.isEmpty else { return nil }

        let urgent = subscribed.filter { urgentLevels.contains($0.level) }
        if let highest = urgent.map(\.level.homeRank).min() {
            let candidates = urgent.filter { $0.level.homeRank == highest }
            let chosen = location.map { closest(in: candidates, to: $0) } ?? candidates.sortedForHome()[0]
            return make(chosen, .mostUrgent, location)
        }
        if let location {
            return make(closest(in: subscribed, to: location), .closest, location)
        }
        return make(subscribed.sortedForHome()[0], .firstInList, nil)
    }

    private static func closest(in valleys: [ValleySummary], to location: CLLocationCoordinate2D) -> ValleySummary {
        valleys.min { lhs, rhs in
            (distance(lhs, location), lhs.id) < (distance(rhs, location), rhs.id)
        }!
    }

    private static func distance(_ valley: ValleySummary, _ location: CLLocationCoordinate2D) -> Double {
        NearbyValleys.distanceMeters(
            from: location, to: CLLocationCoordinate2D(latitude: valley.latitude, longitude: valley.longitude))
    }

    private static func make(_ valley: ValleySummary, _ reason: Reason,
                             _ location: CLLocationCoordinate2D?) -> FeaturedValley {
        FeaturedValley(valley: valley, reason: reason, distanceMeters: location.map { distance(valley, $0) })
    }
}
