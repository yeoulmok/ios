import Foundation

/// One valley in a list response (`GET /valleys`, `GET /me/valleys`).
nonisolated struct ValleySummary: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let region: String
    let latitude: Double
    let longitude: Double
    let level: ValleyLevel
    /// Upstream rainfall over the last hour, in mm. `nil` means unknown (not 0).
    let rainLastHourMM: Double?
    /// Downstream water level change over the last 30 minutes, in m. `nil` means unknown.
    let waterRise30MinM: Double?
    /// When the values were observed. `nil` when there is no observation at all.
    let observedAt: Date?
    /// `true` when the observation is older than 15 minutes.
    let isStale: Bool
    let isSubscribed: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, region, level
        case latitude = "lat"
        case longitude = "lon"
        case rainLastHourMM = "rain_1h_mm"
        case waterRise30MinM = "water_rise_30m_m"
        case observedAt = "observed_at"
        case isStale = "stale"
        case isSubscribed = "subscribed"
    }
}

/// Body of `GET /valleys` and `GET /me/valleys`.
nonisolated struct ValleyListResponse: Decodable, Equatable {
    /// When the server built this response.
    let updatedAt: Date
    /// Data source text that must be shown on screen.
    let source: String
    let valleys: [ValleySummary]

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case source, valleys
    }
}
