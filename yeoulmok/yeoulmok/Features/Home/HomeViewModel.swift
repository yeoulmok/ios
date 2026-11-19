import CoreLocation
import Foundation
import Observation

/// State of the home screen (APP-HOME-01). The view only reads `state`;
/// all loading and sorting happens here, so it can be tested without UI.
@Observable
final class HomeViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame stays and a spinner is shown.
        case loading
        /// Subscribed valleys, already in home order.
        case loaded(valleys: [ValleySummary], source: String)
        /// Request succeeded but there are no subscriptions. Screen: #18.
        case empty(source: String)
        /// Request failed and nothing was loaded before. Screen: `ErrorStateView`.
        case failed(message: String)
    }

    private(set) var state: State = .loading
    /// Set when the last request failed and the screen shows older data instead
    /// (APP-COM-07): the `updated_at` of that data, for "○월 ○일 ○○:○○ 기준".
    /// `nil` when what is shown is fresh.
    private(set) var offlineAsOf: Date?
    /// The valley shown large above the list (APP-HOME-05, #59). `nil` without subscriptions.
    private(set) var featured: FeaturedValley?
    /// Its detail, for the thresholds and the summary text. `nil` until loaded or when it
    /// could not be loaded; the card then shows the values without gauges.
    private(set) var featuredDetail: ValleyDetail?

    private let repository: any ValleyRepository
    /// Where the last answer is saved, so it can be shown when the server cannot be reached.
    private let cache: ValleyCache?
    /// `updated_at` of the answer on screen.
    private var shownUpdatedAt: Date?
    /// Used only when the user already allowed it (on the nearby tab); home never asks.
    /// The location stays on the phone.
    private let location: (any LocationPermission)?

    init(repository: any ValleyRepository, cache: ValleyCache? = nil,
         location: (any LocationPermission)? = nil) {
        self.repository = repository
        self.cache = cache
        self.location = location
    }

    /// Loads subscribed valleys, also for pull to refresh (#9).
    /// Never goes back to `.loading`, so the current list stays while waiting.
    /// On failure (feature spec 3-1):
    /// - something already shown: keep it and set `offlineAsOf`;
    /// - nothing shown but a saved answer exists (e.g. after a restart): show it, set `offlineAsOf`;
    /// - nothing at all: `.failed` (common error screen).
    func load() async {
        // Found while the list loads, so the card does not change after it appears.
        async let place = currentLocationIfAllowed()
        await loadList()
        await updateFeatured(near: await place)
    }

    private func loadList() async {
        do {
            let response = try await repository.subscribedValleys()
            show(response)
            offlineAsOf = nil
            await cache?.saveSubscribedValleys(response)
        } catch {
            switch state {
            case .loaded, .empty:
                offlineAsOf = shownUpdatedAt
            case .loading, .failed:
                // A server error code is an answer, not lost connection: no fallback.
                if !(error is APIError), let saved = await cache?.subscribedValleys() {
                    show(saved)
                    offlineAsOf = saved.updatedAt
                } else {
                    state = .failed(message: ErrorMessage.text(for: error))
                }
            }
        }
    }

    private func currentLocationIfAllowed() async -> CLLocationCoordinate2D? {
        guard let location, location.authorization == .allowed else { return nil }
        return try? await location.currentLocation()
    }

    /// Picks the featured valley from the list on screen and loads its detail.
    /// A failed detail keeps the card (values without gauges), or uses a saved copy.
    private func updateFeatured(near place: CLLocationCoordinate2D?) async {
        guard case let .loaded(valleys, _) = state,
              let picked = FeaturedValley.pick(from: valleys, near: place) else {
            featured = nil
            featuredDetail = nil
            return
        }
        featured = picked
        if featuredDetail?.id != picked.valley.id {
            featuredDetail = nil
        }
        do {
            let detail = try await repository.valleyDetail(id: picked.valley.id)
            featuredDetail = detail
            await cache?.saveDetail(detail)
        } catch {
            if featuredDetail == nil {
                featuredDetail = await cache?.detail(id: picked.valley.id)
            }
        }
    }

    private func show(_ response: ValleyListResponse) {
        shownUpdatedAt = response.updatedAt
        if response.valleys.isEmpty {
            state = .empty(source: response.source)
        } else {
            state = .loaded(valleys: response.valleys.sortedForHome(), source: response.source)
        }
    }
}
