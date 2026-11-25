import Foundation

/// One valley in a list response (`GET /valleys`, `GET /me/valleys`).
nonisolated struct ValleySummary: Codable, Identifiable, Equatable {
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
    /// `var` so a repository can return a copy after subscribe / unsubscribe.
    var isSubscribed: Bool
    /// Short province name for the search filter, e.g. "강원", "서울" (APP-SRCH-04, #96).
    /// `nil` from a server that does not send it yet; `region` is still shown as is.
    var province: String? = nil
    /// City, county or district, e.g. "원주시", "관악구". `nil` like `province`.
    var city: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, region, level, province, city
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
nonisolated struct ValleyListResponse: Codable, Equatable {
    /// When the server built this response.
    let updatedAt: Date
    /// Data source text that must be shown on screen.
    let source: String
    let valleys: [ValleySummary]
    /// How many valleys match in all, when the list comes in pages (`limit` · `offset`,
    /// #96). `nil` from a server without pages: then `valleys` is everything.
    var total: Int? = nil

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case source, valleys, total
    }
}
