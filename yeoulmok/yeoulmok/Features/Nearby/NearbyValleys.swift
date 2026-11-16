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
        valleys
            .map { valley in
                let place = CLLocationCoordinate2D(latitude: valley.latitude, longitude: valley.longitude)
                return NearbyValley(valley: valley, distanceMeters: distanceMeters(from: location, to: place))
            }
            .sorted { ($0.distanceMeters, $0.id) < ($1.distanceMeters, $1.id) }
            .prefix(limit)
            .map { $0 }
    }

    /// Mean earth radius (IUGG), in meters.
    static let earthRadiusMeters = 6_371_008.8

    /// Straight-line (great-circle) distance with the haversine formula.
    /// Not `CLLocation.distance(from:)`: in testing it gave different answers for the
    /// same two points within one run (28,040 m, then 28,052 m), so "28.0km" turned into
    /// "28.1km" on refresh. This always gives the same answer; error is under 0.5%.
    static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusMeters * asin(min(1, sqrt(h)))
    }

    /// Always km with one decimal, like Figma 03: `1.2km`, `0.4km`, `12.3km`.
    static func distanceText(meters: Double) -> String {
        String(format: "%.1fkm", meters / 1000)
    }
}
