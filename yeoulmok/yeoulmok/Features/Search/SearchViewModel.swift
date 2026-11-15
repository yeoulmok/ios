import Foundation
import Observation

/// State of the search tab (APP-SRCH-02, Figma 02 v2 · 02a). The view only reads `state`.
@Observable
final class SearchViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame stays and a spinner is shown.
        case loading
        /// Valleys in server order (no risk sorting: search rows have no badge).
        case loaded(valleys: [ValleySummary], source: String)
        /// Request succeeded but nothing matched (Figma 02a).
        /// `query` is the trimmed search text, empty when there was none.
        case empty(query: String, source: String)
        /// Request failed and nothing was loaded before. Screen: `ErrorStateView`.
        case failed(message: String)
    }

    /// Figma 02b toast, shown when subscribing or unsubscribing fails.
    static let subscriptionFailedMessage = "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."

    private(set) var state: State = .loading
    /// Valleys whose subscribe/unsubscribe request is still running.
    /// Their button is disabled, so two requests for one valley never race.
    private(set) var pendingValleyIDs: Set<Int> = []
    /// Text for the toast. The view shows it and sets it back to `nil` when it hides.
    var toastMessage: String?

    private let repository: any ValleyRepository
    /// Counts searches, so an older answer that arrives late is thrown away.
    private var latestRequest = 0
    /// The last text passed to `search`, for "다시 시도" (#17).
    private(set) var lastQuery = ""

    init(repository: any ValleyRepository) {
        self.repository = repository
    }

    /// Loads valleys matching `query` (all valleys when it is blank).
    /// Does not reset `state` to `.loading`, so the old list stays while waiting.
    func search(_ query: String = "") async {
        latestRequest += 1
        let request = latestRequest
        lastQuery = query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let newState: State
        do {
            let response = try await repository.valleys(matching: trimmed.isEmpty ? nil : trimmed)
            newState = response.valleys.isEmpty
                ? .empty(query: trimmed, source: response.source)
                : .loaded(valleys: response.valleys, source: response.source)
        } catch {
            newState = .failed(message: ErrorMessage.text(for: error))
        }

        // The user searched again while this one was waiting: keep the newer result.
        guard request == latestRequest else { return }
        state = newState
    }

    /// "다시 시도" on the error screen (#17): the same search again.
    func retry() async {
        await search(lastQuery)
    }

    /// "구독" ↔ "구독중" (APP-SRCH-03, Figma 02 · 02b).
    /// The button flips at once, then the request runs. If it fails, the button
    /// flips back and the toast appears. No confirmation before unsubscribing.
    func toggleSubscription(valleyID: Int) async {
        guard !pendingValleyIDs.contains(valleyID),
              let wasSubscribed = currentValleys.first(where: { $0.id == valleyID })?.isSubscribed
        else { return }

        setSubscribed(!wasSubscribed, valleyID: valleyID)
        pendingValleyIDs.insert(valleyID)
        defer { pendingValleyIDs.remove(valleyID) }

        do {
            if wasSubscribed {
                try await repository.unsubscribe(valleyID: valleyID)
            } else {
                try await repository.subscribe(valleyID: valleyID)
            }
        } catch {
            setSubscribed(wasSubscribed, valleyID: valleyID)
            toastMessage = Self.subscriptionFailedMessage
        }
    }

    private var currentValleys: [ValleySummary] {
        guard case let .loaded(valleys, _) = state else { return [] }
        return valleys
    }

    private func setSubscribed(_ isSubscribed: Bool, valleyID: Int) {
        guard case .loaded(var valleys, let source) = state,
              let index = valleys.firstIndex(where: { $0.id == valleyID })
        else { return }
        valleys[index].isSubscribed = isSubscribed
        state = .loaded(valleys: valleys, source: source)
    }
}
