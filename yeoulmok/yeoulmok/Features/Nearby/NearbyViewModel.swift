import Foundation
import Observation

/// State of the "근처" tab (APP-NEAR-01, Figma 03 · 03b). The list itself is #15.
@Observable
final class NearbyViewModel {
    enum State: Equatable {
        /// Waiting for the user to answer iOS's permission question.
        case askingPermission
        /// Location may be used: the nearby list (#15).
        case allowed
        /// Denied or restricted: Figma 03b with "설정 열기".
        case denied
    }

    private(set) var state: State

    private let permission: any LocationPermission

    init(permission: any LocationPermission) {
        self.permission = permission
        state = Self.state(for: permission.authorization)
        // Also fires after the user changes it in Settings and returns to the app.
        permission.onChange = { [weak self] authorization in
            self?.state = Self.state(for: authorization)
        }
    }

    /// The tab appeared. The first time, this shows iOS's question (APP-NEAR-01).
    func onAppear() {
        if permission.authorization == .notDetermined {
            permission.requestWhenInUse()
        }
    }

    private static func state(for authorization: LocationAuthorization) -> State {
        switch authorization {
        case .notDetermined: .askingPermission
        case .allowed: .allowed
        case .denied: .denied
        }
    }
}
