import CoreLocation

/// A valley on the nearby list, with its distance from the user.
nonisolated struct NearbyValley: Equatable, Identifiable {
    let valley: ValleySummary
    /// Straight-line distance from the user, in meters.
    let distanceMeters: Double

    var id: Int { valley.id }
}

/// Picks the valleys closest to the user (APP-NEAR-02). Runs on the phone only:
/// the user's location is never sent to the server (`GET /valleys` gives coordinates).
nonisolated enum NearbyValleys {
    /// Feature spec 6: no radius limit, the 5 closest valleys.
    static let limit = 5

    /// The `limit` valleys closest to `location`, closest first.
    /// Equal distances keep a stable order by id.
    static func closest(
        to location: CLLocationCoordinate2D,
        in valleys: [ValleySummary],
        limit: Int = limit
    ) -> [NearbyValley] {
        let user = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return valleys
            .map { valley in
                let place = CLLocation(latitude: valley.latitude, longitude: valley.longitude)
                return NearbyValley(valley: valley, distanceMeters: user.distance(from: place))
            }
            .sorted { ($0.distanceMeters, $0.id) < ($1.distanceMeters, $1.id) }
            .prefix(limit)
            .map { $0 }
    }

    /// Always km with one decimal, like Figma 03: `1.2km`, `0.4km`, `12.3km`.
    static func distanceText(meters: Double) -> String {
        String(format: "%.1fkm", meters / 1000)
    }
}
