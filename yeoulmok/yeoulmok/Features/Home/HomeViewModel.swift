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
        // The location is found while the list loads. The list and the featured card are
        // then set together, so the list never jumps down when the card appears (#59).
        async let place = currentLocationIfAllowed()
        let result: Result<ValleyListResponse, any Error>
        do {
            result = .success(try await repository.subscribedValleys())
        } catch {
            result = .failure(error)
        }
        let here = await place

        switch result {
        case let .success(response):
            show(response, near: here)
            offlineAsOf = nil
            await cache?.saveSubscribedValleys(response)
        case let .failure(error):
            switch state {
            case .loaded, .empty:
                offlineAsOf = shownUpdatedAt
            case .loading, .failed:
                // A server error code is an answer, not lost connection: no fallback.
                if !(error is APIError), let saved = await cache?.subscribedValleys() {
                    show(saved, near: here)
                    offlineAsOf = saved.updatedAt
                } else {
                    state = .failed(message: ErrorMessage.text(for: error))
                }
            }
        }
        await loadFeaturedDetail()
    }

    private func currentLocationIfAllowed() async -> CLLocationCoordinate2D? {
        guard let location, location.authorization == .allowed else { return nil }
        return try? await location.currentLocation()
    }

    /// Sets the list and the featured valley in one step (no `await` in between).
    private func show(_ response: ValleyListResponse, near place: CLLocationCoordinate2D?) {
        shownUpdatedAt = response.updatedAt
        let valleys = response.valleys.sortedForHome()
        state = valleys.isEmpty
            ? .empty(source: response.source)
            : .loaded(valleys: valleys, source: response.source)
        featured = FeaturedValley.pick(from: valleys, near: place)
        if featuredDetail?.id != featured?.valley.id {
            featuredDetail = nil
        }
    }

    /// The featured valley's detail, for its thresholds and summary. A failure keeps the
    /// card (values without gauges), or uses a saved copy.
    private func loadFeaturedDetail() async {
        guard let id = featured?.valley.id else { return }
        do {
            let detail = try await repository.valleyDetail(id: id)
            featuredDetail = detail
            await cache?.saveDetail(detail)
        } catch {
            if featuredDetail == nil {
                featuredDetail = await cache?.detail(id: id)
            }
        }
    }
}
