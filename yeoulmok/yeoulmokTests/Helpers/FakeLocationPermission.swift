import CoreLocation
@testable import yeoulmok

/// `LocationPermission` whose answers the test chooses.
final class FakeLocationPermission: LocationPermission {
    private(set) var authorization: LocationAuthorization
    var onChange: ((LocationAuthorization) -> Void)?
    private(set) var requestCount = 0
    /// What `currentLocation()` returns next.
    var location: Result<CLLocationCoordinate2D, any Error> = .success(.init(latitude: 37, longitude: 128))
    private(set) var locationCount = 0

    init(_ authorization: LocationAuthorization) {
        self.authorization = authorization
    }

    func requestWhenInUse() {
        requestCount += 1
    }

    func answer(_ authorization: LocationAuthorization) {
        self.authorization = authorization
        onChange?(authorization)
    }

    func currentLocation() async throws -> CLLocationCoordinate2D {
        locationCount += 1
        return try location.get()
    }
}
