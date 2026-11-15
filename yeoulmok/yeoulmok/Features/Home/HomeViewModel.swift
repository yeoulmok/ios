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
        /// Request failed and nothing was loaded before. Screen: #17.
        case failed(message: String)
    }

    private(set) var state: State = .loading

    private let repository: any ValleyRepository

    init(repository: any ValleyRepository) {
        self.repository = repository
    }

    /// Loads subscribed valleys, also for pull to refresh (#9).
    /// Never goes back to `.loading`, so the current list stays while waiting.
    /// A failure after a successful load keeps what is shown (feature spec 3-1:
    /// keep the screen; the "○시 ○분 기준" banner is #16).
    func load() async {
        do {
            let response = try await repository.subscribedValleys()
            if response.valleys.isEmpty {
                state = .empty(source: response.source)
            } else {
                state = .loaded(valleys: response.valleys.sortedForHome(), source: response.source)
            }
        } catch {
            switch state {
            case .loaded, .empty:
                return
            case .loading, .failed:
                state = .failed(message: ErrorMessage.text(for: error))
            }
        }
    }
}
