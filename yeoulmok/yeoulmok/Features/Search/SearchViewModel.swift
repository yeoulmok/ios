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

    private(set) var state: State = .loading

    private let repository: any ValleyRepository
    /// Counts searches, so an older answer that arrives late is thrown away.
    private var latestRequest = 0
    /// The last text passed to `search`, for "다시 시도" (#17).
    private(set) var lastQuery = ""
    /// Set when the last search failed and older results stay on screen (APP-COM-07):
    /// their `updated_at`. Search results are not saved on the device.
    private(set) var offlineAsOf: Date?
    /// `updated_at` of the results on screen.
    private var shownUpdatedAt: Date?

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

        let result: Result<ValleyListResponse, any Error>
        do {
            result = .success(try await repository.valleys(matching: trimmed.isEmpty ? nil : trimmed))
        } catch {
            result = .failure(error)
        }

        // The user searched again while this one was waiting: keep the newer result.
        guard request == latestRequest else { return }
        switch result {
        case let .success(response):
            state = response.valleys.isEmpty
                ? .empty(query: trimmed, source: response.source)
                : .loaded(valleys: response.valleys, source: response.source)
            shownUpdatedAt = response.updatedAt
            offlineAsOf = nil
        case let .failure(error):
            switch state {
            case .loaded, .empty:
                // Feature spec 3-1: keep what is shown and say how old it is.
                offlineAsOf = shownUpdatedAt
            case .loading, .failed:
                state = .failed(message: ErrorMessage.text(for: error))
            }
        }
    }

    /// "다시 시도" on the error screen (#17): the same search again.
    func retry() async {
        await search(lastQuery)
    }
}
