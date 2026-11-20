import Foundation

/// Body of `GET /valleys/{id}/history?hours=3` (API spec v0.6, item 12): one row every
/// `stepMinutes`, oldest first, the last row is now. Drawn as the detail's "최근 3시간" card
/// (APP-DTL-09, #90). Values the server does not know are `nil`, never 0.
nonisolated struct ValleyHistory: Codable, Equatable {
    let updatedAt: Date
    let valleyID: Int
    let hours: Int
    let stepMinutes: Int
    /// `false` for a valley without a water gauge: every water value is `nil`.
    let hasWater: Bool
    let thresholds: HistoryThresholds
    let points: [HistoryPoint]
    let source: String

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case valleyID = "valley_id"
        case hours
        case stepMinutes = "step_minutes"
        case hasWater = "has_water"
        case thresholds, points, source
    }
}

/// The limits for each level, for one measurement. A level without a limit is `nil`
/// (e.g. the AI estimate only has `caution`).
nonisolated struct LevelThresholds: Codable, Equatable {
    let caution: Double?
    let danger: Double?
    let evacuate: Double?

    /// The limits that exist, lowest level first: `[(.caution, 15), (.danger, 25), …]`.
    var steps: [(level: ValleyLevel, value: Double)] {
        [(ValleyLevel.caution, caution), (.danger, danger), (.evacuate, evacuate)]
            .compactMap { level, value in value.map { (level, $0) } }
    }
}

/// `thresholds` in the history answer, per measurement. Either can be missing.
nonisolated struct HistoryThresholds: Codable, Equatable {
    let rainLastHour: LevelThresholds?
    let waterRise30Min: LevelThresholds?

    enum CodingKeys: String, CodingKey {
        case rainLastHour = "rain_1h_mm"
        case waterRise30Min = "water_rise_30m_m"
    }
}

/// One row of the history.
nonisolated struct HistoryPoint: Codable, Equatable, Identifiable {
    let at: Date
    let rainLastHourMM: Double?
    /// Height of the water at the gauge (not a change).
    let waterLevelM: Double?
    let waterRise30MinM: Double?
    /// The level judged for this row; `nil` if the server sends none.
    let level: ValleyLevel?

    var id: Date { at }

    enum CodingKeys: String, CodingKey {
        case at
        case rainLastHourMM = "rain_1h_mm"
        case waterLevelM = "water_level_m"
        case waterRise30MinM = "water_rise_30m_m"
        case level
    }
}
