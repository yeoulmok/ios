import Foundation
import Observation

/// State of the alert detail screen (APP-04). This issue (#10, APP-DTL-01) sets the
/// loading / error rules for the whole screen; #11–#13 only add content to `.loaded`.
@Observable
final class ValleyDetailViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame (back button) stays and a spinner is shown.
        case loading
        case loaded(ValleyDetail)
        /// Request failed and nothing was loaded before. The message is the
        /// server's `error.message` for an error code (e.g. `VALLEY_NOT_FOUND`),
        /// otherwise "연결할 수 없어요". Screen: `ErrorStateView`.
        case failed(message: String)
    }

    let valleyID: Int
    private(set) var state: State = .loading
    /// Set when the last request failed and an older detail is shown (APP-COM-07):
    /// its `updated_at`, for "○월 ○일 ○○:○○ 기준". `nil` when the detail is fresh.
    private(set) var offlineAsOf: Date?

    private let repository: any ValleyRepository
    private let cache: ValleyCache?

    init(valleyID: Int, repository: any ValleyRepository, cache: ValleyCache? = nil) {
        self.valleyID = valleyID
        self.repository = repository
        self.cache = cache
    }

    /// Loads the detail. Never goes back to `.loading`. On failure (feature spec 3-1):
    /// - a detail already shown: keep it and set `offlineAsOf`;
    /// - nothing shown, connection trouble, and a saved detail: show it, set `offlineAsOf`;
    /// - otherwise `.failed`. A server error code (e.g. `VALLEY_NOT_FOUND`) never falls
    ///   back to a saved copy: the server said this valley is gone.
    func load() async {
        do {
            let detail = try await repository.valleyDetail(id: valleyID)
            state = .loaded(detail)
            offlineAsOf = nil
            await cache?.saveDetail(detail)
        } catch {
            if case let .loaded(shown) = state {
                offlineAsOf = shown.updatedAt
                return
            }
            if !(error is APIError), let saved = await cache?.detail(id: valleyID) {
                state = .loaded(saved)
                offlineAsOf = saved.updatedAt
                return
            }
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }
}
