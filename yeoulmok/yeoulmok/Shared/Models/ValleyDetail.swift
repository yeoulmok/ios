import Foundation

/// Body of `GET /valleys/{id}` (alert detail screen).
nonisolated struct ValleyDetail: Decodable, Identifiable, Equatable {
    /// When the server built this response. Shown in the "기준 시각" banner.
    let updatedAt: Date
    let id: Int
    let name: String
    let level: ValleyLevel
    /// One-line summary for the current level, e.g. "상류에 비가 많이 오고 있어요".
    let summary: String
    /// AI-written reason for the level. `nil` means there is none: hide the box.
    let aiExplanation: String?
    /// `true` when fixed text was used instead of AI text.
    let isAIFallback: Bool
    /// Evidence rows. Can be empty when no station is linked.
    let observations: [Observation]
    /// What to do now, in order.
    let actions: [String]
    /// Legally required; must be shown on the detail screen.
    let disclaimer: String
    /// Data source text that must be shown on screen.
    let source: String
    let isSubscribed: Bool
    /// `true` when the observation is older than 15 minutes.
    let isStale: Bool

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case id, name, level, summary
        case aiExplanation = "ai_explanation"
        case isAIFallback = "ai_fallback"
        case observations, actions, disclaimer, source
        case isSubscribed = "subscribed"
        case isStale = "stale"
    }
}

/// One evidence row on the detail screen (one station, one measurement).
nonisolated struct Observation: Decodable, Equatable {
    let kind: ObservationKind
    /// Station name, e.g. "원주 신림(AWS)".
    let station: String
    /// `nil` when the station has no recent data.
    let observedAt: Date?
    /// `nil` means unknown (not 0). See `note` for the reason.
    let value: Double?
    /// "mm" or "m".
    let unit: String
    /// The limit this value is compared against. `nil` when the server has none set.
    let threshold: Double?
    /// Why `value` is missing, e.g. "수위 결측". `nil` when there is a value.
    let note: String?

    enum CodingKeys: String, CodingKey {
        case kind = "type"
        case station
        case observedAt = "observed_at"
        case value, unit, threshold, note
    }
}

/// What an observation measures. Unknown values decode as `.other`,
/// so a new kind added by the server does not break the whole detail screen.
nonisolated enum ObservationKind: String, Decodable {
    /// Upstream rainfall over the last hour.
    case rainLastHour = "rain_1h"
    /// Downstream water level change over the last 30 minutes.
    case waterRise30Min = "water_rise_30m"
    case other

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ObservationKind(rawValue: rawValue) ?? .other
    }
}
