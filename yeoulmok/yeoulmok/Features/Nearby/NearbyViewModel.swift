import CoreLocation
import Foundation
import Observation

/// State of the "근처" tab: location permission (APP-NEAR-01, Figma 03 · 03b) and,
/// once allowed, the closest valleys (APP-NEAR-02, Figma 03).
@Observable
final class NearbyViewModel {
    /// Location permission. Decides between the question, Figma 03b, and the list.
    enum State: Equatable {
        /// Waiting for the user to answer iOS's permission question.
        case askingPermission
        /// Location may be used: the nearby list (`list`).
        case allowed
        /// Denied or restricted: Figma 03b with "설정 열기".
        case denied
    }

    /// The nearby list, used while `state == .allowed` (feature spec 3-1).
    enum ListState: Equatable {
        /// First load (location, then `GET /valleys`). The screen frame stays.
        case loading
        /// The closest valleys, closest first.
        case loaded(valleys: [NearbyValley], source: String)
        /// The server has no valleys at all (there is no radius limit).
        case empty(source: String)
        /// Nothing to show: no location, or the request failed with nothing saved.
        case failed(message: String)
    }

    /// Temporary wording until QA (not in Figma).
    static let locationUnavailable = "현재 위치를 확인할 수 없어요"

    private(set) var state: State
    private(set) var list: ListState = .loading
    /// Set when the last request failed and older valley data is shown (APP-COM-07):
    /// that data's `updated_at`. Distances still use the current location.
    private(set) var offlineAsOf: Date?
    /// Where the distances on the list were measured from. The map shows this point
    /// as "내 위치" (#58), so the map and the distances always agree. Never sent anywhere.
    private(set) var userLocation: CLLocationCoordinate2D?

    private let permission: any LocationPermission
    private let repository: any ValleyRepository
    private let cache: ValleyCache?
    /// The valley data on screen, kept to rebuild the list for a new location.
    private var shownResponse: ValleyListResponse?

    init(permission: any LocationPermission, repository: any ValleyRepository, cache: ValleyCache? = nil) {
        self.permission = permission
        self.repository = repository
        self.cache = cache
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

    /// Pull to refresh: never a kept answer (#103), then the same as `load`.
    func refresh() async {
        await repository.invalidateCache()
        await load()
    }

    /// Finds the user, then the closest valleys. Also for pull to refresh: never goes
    /// back to `.loading`, so the current list stays while waiting.
    /// The location is only used here, on the phone; it is never sent to the server.
    func load() async {
        guard state == .allowed else { return }

        let location: CLLocationCoordinate2D
        do {
            location = try await permission.currentLocation()
        } catch {
            switch list {
            case .loading, .failed:
                list = .failed(message: Self.locationUnavailable)
            case .loaded, .empty:
                // Keep the list on screen (its distances are from the last location).
                break
            }
            return
        }

        do {
            let response = try await repository.valleys(matching: nil)
            show(response, from: location)
            offlineAsOf = nil
            await cache?.saveAllValleys(response)
        } catch {
            if let shownResponse {
                // Same rule as home (#16): keep what is shown, say how old it is.
                show(shownResponse, from: location)
                offlineAsOf = shownResponse.updatedAt
            } else if !(error is APIError), let saved = await cache?.allValleys() {
                // A server error code is an answer, not lost connection: no fallback.
                show(saved, from: location)
                offlineAsOf = saved.updatedAt
            } else {
                list = .failed(message: ErrorMessage.text(for: error))
            }
        }
    }

    private func show(_ response: ValleyListResponse, from location: CLLocationCoordinate2D) {
        shownResponse = response
        userLocation = location
        let nearby = NearbyValleys.closest(to: location, in: response.valleys)
        list = nearby.isEmpty
            ? .empty(source: response.source)
            : .loaded(valleys: nearby, source: response.source)
    }

    private static func state(for authorization: LocationAuthorization) -> State {
        switch authorization {
        case .notDetermined: .askingPermission
        case .allowed: .allowed
        case .denied: .denied
        }
    }
}
