import Foundation

/// Body of `GET /valleys/{id}` (alert detail screen).
nonisolated struct ValleyDetail: Codable, Identifiable, Equatable {
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
    let observations: [ValleyObservation]
    /// What to do now, in order.
    let actions: [String]
    /// Legally required; must be shown on the detail screen.
    let disclaimer: String
    /// Data source text that must be shown on screen.
    let source: String
    /// `var` so a repository can return a copy after subscribe / unsubscribe.
    var isSubscribed: Bool
    /// `true` when the observation is older than 15 minutes.
    let isStale: Bool
    /// `true` when the level was judged from an AI estimate (no water gauge, or its
    /// data is missing). API spec v0.4; older answers and saved copies lack it: `false`.
    var isEstimated: Bool = false

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case id, name, level, summary
        case aiExplanation = "ai_explanation"
        case isAIFallback = "ai_fallback"
        case observations, actions, disclaimer, source
        case isSubscribed = "subscribed"
        case isStale = "stale"
        case isEstimated = "estimated"
    }
}

extension ValleyDetail {
    /// Written out only so `estimated` may be missing (in an extension, so the
    /// memberwise initializer stays).
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        level = try c.decode(ValleyLevel.self, forKey: .level)
        summary = try c.decode(String.self, forKey: .summary)
        aiExplanation = try c.decodeIfPresent(String.self, forKey: .aiExplanation)
        isAIFallback = try c.decode(Bool.self, forKey: .isAIFallback)
        observations = try c.decode([ValleyObservation].self, forKey: .observations)
        actions = try c.decode([String].self, forKey: .actions)
        disclaimer = try c.decode(String.self, forKey: .disclaimer)
        source = try c.decode(String.self, forKey: .source)
        isSubscribed = try c.decode(Bool.self, forKey: .isSubscribed)
        isStale = try c.decode(Bool.self, forKey: .isStale)
        isEstimated = try c.decodeIfPresent(Bool.self, forKey: .isEstimated) ?? false
    }
}

/// One evidence row on the detail screen (one station, one measurement).
nonisolated struct ValleyObservation: Codable, Equatable {
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
    /// `true` for a value estimated by AI from rainfall (`est_rise_3h`), not measured.
    /// Missing in older answers: `false`.
    var isEstimated: Bool = false

    enum CodingKeys: String, CodingKey {
        case kind = "type"
        case station
        case observedAt = "observed_at"
        case value, unit, threshold, note
        case isEstimated = "estimated"
    }
}

extension ValleyObservation {
    /// Written out only so `estimated` may be missing (see `ValleyDetail`).
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(ObservationKind.self, forKey: .kind)
        station = try c.decode(String.self, forKey: .station)
        observedAt = try c.decodeIfPresent(Date.self, forKey: .observedAt)
        value = try c.decodeIfPresent(Double.self, forKey: .value)
        unit = try c.decode(String.self, forKey: .unit)
        threshold = try c.decodeIfPresent(Double.self, forKey: .threshold)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        isEstimated = try c.decodeIfPresent(Bool.self, forKey: .isEstimated) ?? false
    }
}

/// What an observation measures. Unknown values decode as `.other`,
/// so a new kind added by the server does not break the whole detail screen.
nonisolated enum ObservationKind: String, Codable {
    /// Upstream rainfall over the last hour.
    case rainLastHour = "rain_1h"
    /// Downstream water level change over the last 30 minutes.
    case waterRise30Min = "water_rise_30m"
    /// Water level rise over the next 3 hours, estimated by AI from rainfall
    /// (API spec v0.4). Only for valleys without water level data.
    case estRise3h = "est_rise_3h"
    case other

    nonisolated init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ObservationKind(rawValue: rawValue) ?? .other
    }
}
