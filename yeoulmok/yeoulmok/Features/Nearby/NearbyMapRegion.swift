import CoreLocation
import MapKit

/// The part of the map the nearby tab shows first (APP-NEAR-03, #58): the user and
/// every valley on the list, with some room around them so no pin sits on the edge.
nonisolated enum NearbyMapRegion {
    /// Extra room around the points: 1.4 means 20% more on each side.
    static let padding = 1.4
    /// Smallest span in degrees (about 2 km), so one valley next to the user
    /// is not shown at street level.
    static let minimumSpan = 0.02

    static func fitting(user: CLLocationCoordinate2D, valleys: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let points = [user] + valleys
        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)
        let minLat = latitudes.min()!, maxLat = latitudes.max()!
        let minLon = longitudes.min()!, maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * padding, minimumSpan),
            longitudeDelta: max((maxLon - minLon) * padding, minimumSpan)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
