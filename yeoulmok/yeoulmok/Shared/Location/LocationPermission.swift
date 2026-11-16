import CoreLocation

/// What the app may do with the user's location (APP-NEAR-01).
/// The location itself stays on the phone; it is never sent to the server.
nonisolated enum LocationAuthorization: Equatable {
    /// iOS has not asked yet.
    case notDetermined
    /// "앱 사용 중 허용" (or "항상").
    case allowed
    /// Denied, or restricted (e.g. parental controls). The app cannot ask again:
    /// only the Settings app can change it.
    case denied
}

/// Location permission, behind a protocol so view models can be tested without iOS.
protocol LocationPermission: AnyObject {
    var authorization: LocationAuthorization { get }
    /// Called whenever the authorization changes, also after the user changes it
    /// in the Settings app and comes back.
    var onChange: ((LocationAuthorization) -> Void)? { get set }
    /// Shows iOS's "앱 사용 중 허용" question. iOS shows it only while `.notDetermined`.
    func requestWhenInUse()
    /// The user's location, once (APP-NEAR-02). Not tracked continuously.
    /// Stays on the phone: it is only used to sort valleys by distance.
    /// Throws when iOS cannot find the location (or permission is missing).
    func currentLocation() async throws -> CLLocationCoordinate2D
}

/// `LocationPermission` backed by `CLLocationManager`.
final class SystemLocationPermission: NSObject, LocationPermission, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let requests = LocationRequests()
    /// When set, `currentLocation()` answers this instead of asking iOS (DEBUG
    /// `-mockLocation`, for UI tests and screenshots). Permission still comes from iOS.
    private let fixedLocation: CLLocationCoordinate2D?
    var onChange: ((LocationAuthorization) -> Void)?

    /// Downtown Wonju, near the mock valleys: closest is "안전 예시 계곡", then "금대리 계곡".
    static let mockLocation = CLLocationCoordinate2D(latitude: 37.3422, longitude: 127.9202)

    init(fixedLocation: CLLocationCoordinate2D? = nil) {
        self.fixedLocation = fixedLocation
        super.init()
        manager.delegate = self
    }

    var authorization: LocationAuthorization {
        Self.authorization(for: manager.authorizationStatus)
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func currentLocation() async throws -> CLLocationCoordinate2D {
        if let fixedLocation { return fixedLocation }
        // `requestLocation()` answers once (or fails after its own timeout), then stops.
        return try await requests.wait { manager.requestLocation() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        MainActor.assumeIsolated {
            requests.finish(.success(coordinate))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        MainActor.assumeIsolated {
            requests.finish(.failure(error))
        }
    }

    /// iOS calls this on the thread the manager was created on (the main thread here).
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            onChange?(Self.authorization(for: status))
        }
    }

    nonisolated static func authorization(for status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: .allowed
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }
}

/// Callers waiting for one location answer. If the screen asks again while iOS is
/// still looking (e.g. pull to refresh during the first load), both get the same
/// answer and iOS is asked only once.
final class LocationRequests {
    private var waiting: [CheckedContinuation<CLLocationCoordinate2D, any Error>] = []

    /// How many callers are waiting (for tests).
    var waitingCount: Int { waiting.count }

    /// Waits for the next `finish`. Calls `start` only when nobody was waiting yet.
    func wait(start: () -> Void) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            waiting.append(continuation)
            if waiting.count == 1 {
                start()
            }
        }
    }

    /// Gives the answer to everyone waiting. Does nothing when nobody waits.
    func finish(_ result: Result<CLLocationCoordinate2D, any Error>) {
        let done = waiting
        waiting = []
        for continuation in done {
            continuation.resume(with: result)
        }
    }
}
