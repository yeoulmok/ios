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

    /// Toast text when subscribing or unsubscribing fails (Figma 02b, same as #7).
    static let subscriptionFailedMessage = "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."

    let valleyID: Int
    private(set) var state: State = .loading
    /// The subscribe/unsubscribe request is still running. The button is disabled,
    /// so two requests never race.
    private(set) var isSubscriptionPending = false
    /// Text for the toast. The view shows it and sets it back to `nil` when it hides.
    var toastMessage: String?
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

    /// "구독" ↔ "구독중" (APP-DTL-06, #57). Same rules as the search list had (#7):
    /// the button flips at once, then the request runs. If it fails, the button flips
    /// back and the toast appears. No confirmation before unsubscribing.
    func toggleSubscription() async {
        guard !isSubscriptionPending, case let .loaded(detail) = state else { return }
        let wasSubscribed = detail.isSubscribed

        setSubscribed(!wasSubscribed)
        isSubscriptionPending = true
        defer { isSubscriptionPending = false }

        do {
            if wasSubscribed {
                try await repository.unsubscribe(valleyID: valleyID)
            } else {
                try await repository.subscribe(valleyID: valleyID)
            }
            // The saved copy (shown when offline) should not show the old state.
            if case let .loaded(updated) = state {
                await cache?.saveDetail(updated)
            }
        } catch {
            setSubscribed(wasSubscribed)
            toastMessage = Self.subscriptionFailedMessage
        }
    }

    private func setSubscribed(_ isSubscribed: Bool) {
        guard case var .loaded(detail) = state else { return }
        detail.isSubscribed = isSubscribed
        state = .loaded(detail)
    }
}
