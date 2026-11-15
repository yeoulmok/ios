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
}

/// `LocationPermission` backed by `CLLocationManager`.
final class SystemLocationPermission: NSObject, LocationPermission, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onChange: ((LocationAuthorization) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var authorization: LocationAuthorization {
        Self.authorization(for: manager.authorizationStatus)
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
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
